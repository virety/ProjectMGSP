from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.authtoken.models import Token
from rest_framework import viewsets, generics, permissions, status
from .models import User, Transaction, Card, Deposit, Loan, Mortgage, Application
from .serializers import (
    UserRegistrationSerializer, 
    UserSerializer, 
    TransactionSerializer, 
    AuthTokenSerializer,
    CardSerializer,
    DepositSerializer,
    LoanSerializer,
    MortgageSerializer,
    UserProfileSerializer,
    TransferSerializer,
    ApplicationSerializer,
)
from rest_framework.renderers import JSONRenderer, TemplateHTMLRenderer, BrowsableAPIRenderer
from rest_framework.parsers import JSONParser, FormParser, MultiPartParser
from datetime import date, timedelta
from rest_framework import status
from .credit_logic import CreditLogicManager
from decimal import Decimal, Inexact
from django.db import transaction
from rest_framework.views import APIView
import re
from django.db.models import Q

# Create your views here.

class CustomAuthToken(ObtainAuthToken):
    serializer_class = AuthTokenSerializer
    renderer_classes = [JSONRenderer, BrowsableAPIRenderer]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data,
                                           context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'email': user.email
        })

class UserRegistrationView(generics.CreateAPIView):
    """
    API view for user registration.
    """
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny] # Anyone can register

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows users to be viewed.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]

class UserLoginView(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data,
                                           context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'email': user.email
        })

class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    API endpoint for viewing and editing the authenticated user's profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        """
        This view should return an object instance for the currently authenticated user.
        """
        return self.request.user

class TransferView(APIView):
    """
    API endpoint for handling money transfers between users.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = TransferSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        sender_user = request.user
        amount = data['amount']
        recipient_identifier = data['recipient_identifier']

        try:
            with transaction.atomic():
                # Get the sender's card
                sender_card = get_object_or_404(Card, user=sender_user, card_number=data['sender_card_number'])

                # Check for sufficient funds
                if sender_card.balance < amount:
                    return Response({"detail": "Insufficient funds."}, status=status.HTTP_400_BAD_REQUEST)

                # Determine recipient
                recipient_user = None
                recipient_card = None

                # Check if identifier is a card number
                if re.match(r'^\d{16}$', recipient_identifier):
                    try:
                        recipient_card = Card.objects.get(card_number=recipient_identifier)
                        recipient_user = recipient_card.user
                    except Card.DoesNotExist:
                        pass # It's not a card number, will check if it's a phone number
                
                # If not a card, check if it's a phone number
                if recipient_card is None:
                    try:
                        recipient_user = User.objects.get(phone_number=recipient_identifier)
                        recipient_card = recipient_user.get_default_card()
                        if not recipient_card:
                             return Response({"detail": "Recipient does not have a default card to receive funds."}, status=status.HTTP_400_BAD_REQUEST)
                    except User.DoesNotExist:
                        return Response({"detail": "Recipient not found."}, status=status.HTTP_404_NOT_FOUND)
                
                # Check for transfer to self
                if sender_card == recipient_card:
                    return Response({"detail": "Cannot transfer to the same card."}, status=status.HTTP_400_BAD_REQUEST)
                
                # Perform the transfer
                sender_card.balance -= amount
                recipient_card.balance += amount
                sender_card.save()
                recipient_card.save()

                # Create transaction records
                Transaction.objects.create(
                    sender_card=sender_card, 
                    recipient_card=recipient_card, 
                    amount=amount,
                    description=f"Transfer to {recipient_user.get_full_name()}"
                )
                
                return Response({
                    "detail": "Transfer successful.",
                    "sender_balance": sender_card.balance
                }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"detail": "Произошла внутренняя ошибка при выполнении перевода."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AdminCreditScoreCheck(APIView):
    permission_classes = [permissions.IsAdminUser]
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.credit_logic_manager = CreditLogicManager()

    def get(self, request, user_id):
        if not user_id:
            return Response(
                {"detail": "Please provide a 'user_id' query parameter."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        score_details = self.credit_logic_manager.get_detailed_credit_score(user)
        return Response(score_details)

class ApplicationUpdateView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        try:
            application = Application.objects.get(pk=pk)
        except Application.DoesNotExist:
            return Response({'error': 'Application not found'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        if new_status not in ['APPROVED', 'REJECTED']:
            return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

        if application.status != 'PENDING':
            return Response({'error': f'Application is already {application.status}'}, status=status.HTTP_400_BAD_REQUEST)

        if new_status == 'APPROVED':
            # Create the corresponding product
            user = application.user
            details = application.details
            app_type = application.application_type

            if app_type == 'LOAN':
                Loan.objects.create(user=user, amount=details['amount'], term=details['term'], interest_rate=Decimal('5.0')) # Example interest rate
            elif app_type == 'MORTGAGE':
                Mortgage.objects.create(user=user, property_cost=details['property_cost'], initial_payment=details['initial_payment'], term_years=details['term_years'])
            elif app_type == 'DEPOSIT':
                Deposit.objects.create(user=user, amount=details['amount'], term_months=details['term_months'])
            elif app_type == 'CARD':
                Card.objects.create(user=user, card_number=Card.generate_card_number(), cvv=Card.generate_cvv(), expiration_date=Card.generate_expiration_date())

            application.status = 'APPROVED'
            application.rejection_reason = None
        else: # REJECTED
            rejection_reason = request.data.get('rejection_reason')
            if not rejection_reason:
                return Response({'error': 'Rejection reason is required'}, status=status.HTTP_400_BAD_REQUEST)
            application.status = 'REJECTED'
            application.rejection_reason = rejection_reason

        application.save()
        serializer = ApplicationSerializer(application)
        return Response(serializer.data)

class LoanCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.credit_logic_manager = CreditLogicManager()

    def post(self, request):
        user = request.user
        data = request.data
        
        # Check credit score
        credit_score = self.credit_logic_manager.get_credit_score(user)
        if credit_score < 650:
             return Response({'error': f'Loan application denied. Your credit score is {credit_score}, which is below the minimum of 650.'}, status=status.HTTP_400_BAD_REQUEST)

        application_data = {
            'user': user.id,
            'application_type': 'LOAN',
            'status': 'PENDING',
            'details': {
                'amount': data.get('amount'),
                'term': data.get('term'),
                'interest_rate': 0.0 # Will be set upon approval
            }
        }
        
        serializer = ApplicationSerializer(data=application_data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MortgageCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.credit_logic_manager = CreditLogicManager()

    def post(self, request):
        user = request.user
        data = request.data
        
        # Check credit score
        credit_score = self.credit_logic_manager.get_credit_score(user)
        if credit_score < 700: # Higher requirement for mortgages
             return Response({'error': f'Mortgage application denied. Your credit score is {credit_score}, which is below the minimum of 700.'}, status=status.HTTP_400_BAD_REQUEST)

        application_data = {
            'user': user.id,
            'application_type': 'MORTGAGE',
            'status': 'PENDING',
            'details': {
                'property_cost': data.get('property_cost'),
                'initial_payment': data.get('initial_payment'),
                'term_years': data.get('term_years'),
            }
        }
        
        serializer = ApplicationSerializer(data=application_data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DepositCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        data = request.data
        application_data = {
            'user': request.user.id,
            'application_type': 'DEPOSIT',
            'status': 'PENDING',
            'details': {
                'amount': data.get('amount'),
                'term_months': data.get('term_months'),
            }
        }
        
        serializer = ApplicationSerializer(data=application_data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CardListView(generics.ListAPIView):
    """
    An endpoint for the user to view a list of their own cards.
    """
    serializer_class = CardSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Card.objects.filter(owner=self.request.user)

class SetDefaultCardView(APIView):
    """
    An endpoint for the user to set one of their cards as the default.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        try:
            card_to_set_default = Card.objects.get(pk=pk, owner=user)
        except Card.DoesNotExist:
            return Response({'error': 'Card not found or you do not own this card.'}, status=status.HTTP_404_NOT_FOUND)

        # Set all other cards for this user to is_default=False
        user.cards.exclude(pk=pk).update(is_default=False)
        
        # Set the selected card to is_default=True
        card_to_set_default.is_default = True
        card_to_set_default.save()

        return Response({'status': f'Card {card_to_set_default.card_number} is now the default.'}, status=status.HTTP_200_OK)

class TransactionListView(generics.ListAPIView):
    """
    An endpoint for the user to view their transaction history.
    """
    serializer_class = TransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Based on the current Transaction model, it's only linked to one user.
        # This will show all transactions associated with the logged-in user.
        return Transaction.objects.filter(user=self.request.user).order_by('-timestamp')

class CardCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        data = request.data
        application_data = {
            'user': request.user.id,
            'application_type': 'CARD',
            'status': 'PENDING',
            'details': {
                'card_number': data.get('card_number'),
                'cvv': data.get('cvv'),
                'expiration_date': data.get('expiration_date'),
            }
        }
        
        serializer = ApplicationSerializer(data=application_data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
