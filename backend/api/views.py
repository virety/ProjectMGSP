from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.authtoken.models import Token
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework import viewsets, generics, permissions, status
from .models import User, Transaction, Card, Deposit, Loan, Mortgage, Application, Currency, CurrencyHistory, ForumPost, ForumComment, ForumLike, Terminal, AIChat, AIChatMessage, PredictionPost, PredictionComment, PredictionLike, CryptoCurrency, CryptoWallet, CryptoTransaction, CryptoPriceHistory
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
    AdminApplicationSerializer,
    CurrencySerializer,
    ForumPostSerializer,
    ForumCommentSerializer,
    TerminalSerializer,
    AIChatSerializer,
    AIChatListSerializer,
    AIChatMessageSerializer,
    ChatMessageCreateSerializer,
    PredictionPostSerializer,
    PredictionPostCreateSerializer,
    PredictionCommentSerializer,
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
from django.shortcuts import get_object_or_404
from rest_framework.decorators import action
from django.utils import timezone
from django.db.models import Sum, Avg
from rest_framework.parsers import MultiPartParser, FormParser
from PIL import Image
import os

# Create your views here.

class ObtainAuthTokenView(ObtainAuthToken):
    """
    Custom view to obtain auth token, using phone_number.
    """
    serializer_class = AuthTokenSerializer

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

class TransferView(generics.CreateAPIView):
    serializer_class = TransferSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        source_card_id = serializer.validated_data['source_card_id']
        
        try:
            source_card = Card.objects.select_for_update().get(id=source_card_id, owner=request.user)
        except Card.DoesNotExist:
            return Response({"error": "Source card not found or you are not the owner."}, status=status.HTTP_404_NOT_FOUND)

        if not source_card.is_active:
            return Response({"error": "Source card is blocked."}, status=status.HTTP_403_FORBIDDEN)

        target_card_number = serializer.validated_data['target_card_number']
        amount = serializer.validated_data['amount']

        try:
            with transaction.atomic():
                # Get the sender's card
                sender_card = source_card

                # Check for sufficient funds
                if sender_card.balance < amount:
                    return Response({"detail": "Insufficient funds."}, status=status.HTTP_400_BAD_REQUEST)

                # Determine recipient
                recipient_user = None
                recipient_card = None
                is_phone_transfer = False

                # Check if identifier is a card number
                if re.match(r'^\d{16}$', target_card_number):
                    try:
                        recipient_card = Card.objects.get(card_number=target_card_number)
                        recipient_user = recipient_card.owner
                    except Card.DoesNotExist:
                        pass # It's not a card number, will check if it's a phone number
                
                # If not a card, check if it's a phone number
                if recipient_card is None:
                    is_phone_transfer = True
                    try:
                        recipient_user = User.objects.get(phone_number=target_card_number)
                        # Find the recipient's default card, or just any card if no default is set
                        recipient_card = Card.objects.filter(owner=recipient_user).first() 
                        if not recipient_card:
                                return Response({"detail": "Recipient does not have a card to receive funds."}, status=status.HTTP_400_BAD_REQUEST)
                    except User.DoesNotExist:
                        return Response({"detail": "Recipient not found."}, status=status.HTTP_404_NOT_FOUND)
                
                # Check for transfer to self
                if sender_card == recipient_card:
                    return Response({"detail": "Cannot transfer to the same card."}, status=status.HTTP_400_BAD_REQUEST)
                
                # Check for transfer to self by phone number only
                if is_phone_transfer and request.user == recipient_user:
                    return Response({"detail": "Cannot transfer to yourself."}, status=status.HTTP_400_BAD_REQUEST)
                
                # Perform the transfer
                sender_card.balance -= amount
                recipient_card.balance += amount
                sender_card.save()
                recipient_card.save()

                # Create transaction records
                Transaction.objects.create(
                    user=request.user,
                    title=f"Transfer to {recipient_user.get_full_name()}",
                    amount=-amount,
                    transaction_type=0 # Expense
                )
                Transaction.objects.create(
                    user=recipient_user,
                    title=f"Transfer from {request.user.get_full_name()}",
                    amount=amount,
                    transaction_type=1 # Income
                )
                
                return Response({
                    "detail": "Transfer successful.",
                    "sender_balance": sender_card.balance
                }, status=status.HTTP_200_OK)

        except Exception as e:
            # Log the exception e for debugging
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
                Loan.objects.create(
                    user=user, 
                    total_amount=details['amount'], 
                    remaining_debt=details['amount'],
                    term_months=details['term'], 
                    interest_rate=Decimal('5.0'),
                    monthly_payment=Decimal(str(details['amount'])) / details['term'],
                    next_payment_date=date.today() + timedelta(days=30)
                )
            elif app_type == 'MORTGAGE':
                total_amount = details['property_cost'] - details['initial_payment']
                monthly_payment = total_amount / (details['term_years'] * 12)
                Mortgage.objects.create(
                    user=user, 
                    property_cost=details['property_cost'], 
                    initial_payment=details['initial_payment'], 
                    total_amount=total_amount,
                    term_years=details['term_years'],
                    interest_rate=Decimal('7.0'),
                    monthly_payment=monthly_payment
                )
            elif app_type == 'DEPOSIT':
                Deposit.objects.create(
                    user=user, 
                    amount=details['amount'], 
                    term_months=details['term_months'],
                    interest_rate=Decimal('6.5')
                )
            elif app_type == 'CARD':
                Card.objects.create(
                    user=user, 
                    card_name="Nyota Card",
                    card_number=Card.generate_card_number(), 
                    cvv=Card.generate_cvv(), 
                    card_expiry_date=Card.generate_expiration_date(),
                    gradient_start_hex="#4158D0",
                    gradient_end_hex="#C850C0"
                )

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

class AdminApplicationListView(generics.ListAPIView):
    """
    API endpoint для получения всех заявок на рассмотрении (только для админов)
    """
    serializer_class = AdminApplicationSerializer
    permission_classes = [permissions.IsAdminUser]
    
    def get_queryset(self):
        # Возвращаем только заявки со статусом PENDING
        return Application.objects.filter(status='PENDING').select_related('user').order_by('-created_at')

class CreateAdminUserView(APIView):
    """
    ВРЕМЕННЫЙ endpoint для создания админа - удалить после использования!
    """
    permission_classes = [permissions.AllowAny]  # Открытый доступ ВРЕМЕННО
    
    def post(self, request):
        # Защита - только если админа еще нет
        if User.objects.filter(is_superuser=True).exists():
            return Response({'error': 'Admin already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Создаем суперпользователя
        admin_user = User.objects.create_superuser(
            phone_number='+79999999999',
            password='admin123456',
            first_name='Admin',
            last_name='Nyota',
            email='admin@nyota.com'
        )
        
        return Response({
            'message': 'Admin user created successfully',
            'phone': '+79999999999',
            'password': 'admin123456',
            'user_id': admin_user.id
        }, status=status.HTTP_201_CREATED)

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

class CurrencyViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows currencies to be viewed.
    Provides a list of all available currencies and allows retrieving
    a specific currency with its historical data.
    """
    queryset = Currency.objects.all().prefetch_related('history')
    serializer_class = CurrencySerializer
    permission_classes = [permissions.AllowAny] # Data is public

class ForumPostViewSet(viewsets.ModelViewSet):
    """
    API endpoint for forum posts.
    - List all posts with search and filtering
    - Create a new post
    - Retrieve, update, or delete a specific post
    - Like/unlike posts
    """
    queryset = ForumPost.objects.all()
    serializer_class = ForumPostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = ForumPost.objects.all()
        
        # Search functionality
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(content__icontains=search)
            )
        
        # Filter by author
        author_id = self.request.query_params.get('author', None)
        if author_id:
            queryset = queryset.filter(author_id=author_id)
            
        # Show only pinned posts
        pinned_only = self.request.query_params.get('pinned', None)
        if pinned_only == 'true':
            queryset = queryset.filter(is_pinned=True)
            
        return queryset

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'], url_path='like')
    def like(self, request, pk=None):
        """Like or unlike a forum post"""
        post = self.get_object()
        
        if post.is_locked:
            return Response(
                {'error': 'Этот пост заблокирован для взаимодействия'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        like, created = ForumLike.objects.get_or_create(
            user=request.user,
            post=post
        )
        
        if not created:
            # Unlike - remove the like
            like.delete()
            return Response({
                'liked': False,
                'likes_count': post.likes_count
            })
        else:
            # Like created
            return Response({
                'liked': True,
                'likes_count': post.likes_count
            })

    @action(detail=True, methods=['get'], url_path='comments')
    def comments(self, request, pk=None):
        """Get comments for a specific post"""
        post = self.get_object()
        comments = post.comments.all()
        serializer = ForumCommentSerializer(comments, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='comments')
    def add_comment(self, request, pk=None):
        """Add a comment to a specific post"""
        post = self.get_object()
        
        if post.is_locked:
            return Response(
                {'error': 'Этот пост заблокирован для комментариев'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = ForumCommentSerializer(
            data=request.data, 
            context={'request': request, 'post': post}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ForumCommentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for comments on a forum post.
    """
    queryset = ForumComment.objects.all()
    serializer_class = ForumCommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        # Filter comments by the post_pk from the URL
        return self.queryset.filter(post_id=self.kwargs.get('post_pk'))

    def get_serializer_context(self):
        context = super().get_serializer_context()
        # Pass the post object to the serializer
        context['post'] = ForumPost.objects.get(pk=self.kwargs.get('post_pk'))
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        post = ForumPost.objects.get(pk=self.kwargs.get('post_pk'))
        comment = serializer.save(author=self.request.user, post=post)
        comment.post = post
        comment.save()
        serializer = self.get_serializer(comment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class TerminalViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows terminals to be viewed.
    Provides a list of all active terminals.
    """
    queryset = Terminal.objects.filter(is_active=True)
    serializer_class = TerminalSerializer
    permission_classes = [permissions.AllowAny] # Allow any user, including unauthenticated

class CardViewSet(viewsets.ModelViewSet):
    serializer_class = CardSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all the cards
        for the currently authenticated user.
        """
        return self.request.user.cards.all()

    @action(detail=True, methods=['post'], url_path='block')
    def block(self, request, pk=None):
        """
        Block a card. Sets is_active to False.
        """
        card = self.get_object()
        card.is_active = False
        card.save()
        return Response({'status': 'card blocked'}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'], url_path='unblock')
    def unblock(self, request, pk=None):
        """
        Unblock a card. Sets is_active to True.
        """
        card = self.get_object()
        card.is_active = True
        card.save()
        return Response({'status': 'card unblocked'}, status=status.HTTP_200_OK)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class CreateCardApplicationView(generics.CreateAPIView):
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


# AI Chat Views
from .services import AIChatService

class AIChatViewSet(viewsets.ModelViewSet):
    """
    API endpoint for AI chat sessions.
    - List user's chats
    - Create new chat
    - Retrieve specific chat with messages
    - Delete chat
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.request.user.ai_chats.filter(is_active=True).order_by('-updated_at')

    def get_serializer_class(self):
        if self.action == 'list':
            return AIChatListSerializer
        return AIChatSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def destroy(self, request, *args, **kwargs):
        """Soft delete chat"""
        chat = self.get_object()
        chat.is_active = False
        chat.save()
        return Response({'status': 'chat deleted'}, status=status.HTTP_204_NO_CONTENT)


class AIChatMessageView(APIView):
    """
    API endpoint for sending messages to AI chat.
    POST: Send a message and get AI response
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChatMessageCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        message = serializer.validated_data['message']
        chat_id = serializer.validated_data.get('chat_id')

        try:
            # Initialize chat service
            chat_service = AIChatService()
            
            # Get or create chat
            chat = chat_service.get_or_create_chat(request.user, chat_id)
            
            # Process message synchronously
            assistant_message = chat_service.process_user_message(chat, message)

            # Return response
            return Response({
                'chat_id': str(chat.id),
                'user_message': {
                    'role': 'user',
                    'content': message,
                    'created_at': chat.messages.filter(role='user').last().created_at
                },
                'assistant_message': {
                    'role': assistant_message.role,
                    'content': assistant_message.content,
                    'created_at': assistant_message.created_at,
                    'tokens_used': assistant_message.tokens_used,
                    'processing_time': assistant_message.processing_time
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'error': 'Произошла ошибка при обработке сообщения.',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Prediction Forum Views
class PredictionPostViewSet(viewsets.ModelViewSet):
    """
    API endpoint for prediction posts.
    - List all predictions
    - Create new prediction
    - Retrieve, update, delete specific prediction
    """
    queryset = PredictionPost.objects.all().order_by('-created_at')
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_serializer_class(self):
        if self.action == 'create':
            return PredictionPostCreateSerializer
        return PredictionPostSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    @action(detail=True, methods=['post'], url_path='like')
    def like(self, request, pk=None):
        """Like/unlike a prediction post"""
        post = self.get_object()
        like, created = PredictionLike.objects.get_or_create(
            user=request.user,
            post=post
        )
        
        if not created:
            # Unlike
            like.delete()
            post.likes_count = max(0, post.likes_count - 1)
            post.save()
            return Response({'status': 'unliked', 'likes_count': post.likes_count})
        else:
            # Like
            post.likes_count += 1
            post.save()
            return Response({'status': 'liked', 'likes_count': post.likes_count})

    @action(detail=True, methods=['get'], url_path='comments')
    def comments(self, request, pk=None):
        """Get comments for a prediction post"""
        post = self.get_object()
        comments = post.comments.all().order_by('created_at')
        serializer = PredictionCommentSerializer(comments, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='comments')
    def add_comment(self, request, pk=None):
        """Add comment to a prediction post"""
        post = self.get_object()
        serializer = PredictionCommentSerializer(
            data=request.data, 
            context={'request': request, 'post': post}
        )
        
        if serializer.is_valid():
            comment = serializer.save()
            post.comments_count += 1
            post.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Cryptocurrency Views
from .serializers import (
    CryptoCurrencySerializer, CryptoWalletSerializer, CryptoWalletCreateSerializer,
    CryptoTransactionSerializer, CryptoBuySerializer, CryptoSellSerializer,
    CryptoTransferSerializer, CryptoPortfolioSerializer, CryptoPriceHistorySerializer
)
from .services.crypto_service import CryptoService


class CryptoCurrencyViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for cryptocurrencies.
    - List all active cryptocurrencies
    - Retrieve specific cryptocurrency with price history
    """
    queryset = CryptoCurrency.objects.filter(is_active=True)
    serializer_class = CryptoCurrencySerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=True, methods=['get'], url_path='history')
    def price_history(self, request, pk=None):
        """Get price history for a cryptocurrency"""
        crypto = self.get_object()
        days = request.query_params.get('days', 7)
        
        try:
            days = int(days)
            if days > 365:
                days = 365
        except ValueError:
            days = 7
        
        history = crypto.price_history.all()[:days * 24]  # Limit results
        serializer = CryptoPriceHistorySerializer(history, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='update-prices')
    def update_prices(self, request):
        """Update cryptocurrency prices (admin only)"""
        if not request.user.is_staff:
            return Response(
                {'error': 'Permission denied'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        crypto_service = CryptoService()
        updated_count = crypto_service.update_crypto_prices()
        
        return Response({
            'message': f'Updated prices for {updated_count} cryptocurrencies'
        })


class CryptoWalletViewSet(viewsets.ModelViewSet):
    """
    API endpoint for crypto wallets.
    - List user's wallets
    - Create new wallet
    - Retrieve wallet details
    """
    serializer_class = CryptoWalletSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return CryptoWallet.objects.filter(user=self.request.user, is_active=True)

    def get_serializer_class(self):
        if self.action == 'create':
            return CryptoWalletCreateSerializer
        return CryptoWalletSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        crypto_service = CryptoService()
        wallet = crypto_service.create_wallet(
            self.request.user, 
            serializer.validated_data['cryptocurrency_id']
        )
        return wallet

    @action(detail=True, methods=['get'], url_path='transactions')
    def transactions(self, request, pk=None):
        """Get transactions for a specific wallet"""
        wallet = self.get_object()
        transactions = wallet.transactions.all()[:50]  # Last 50 transactions
        serializer = CryptoTransactionSerializer(transactions, many=True)
        return Response(serializer.data)


class CryptoTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for crypto transactions.
    - List user's transactions
    - Retrieve specific transaction
    """
    serializer_class = CryptoTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return CryptoTransaction.objects.filter(user=self.request.user)


class CryptoBuyView(APIView):
    """Buy cryptocurrency with USD"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CryptoBuySerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            try:
                crypto_service = CryptoService()
                transaction = crypto_service.buy_cryptocurrency(
                    user=request.user,
                    cryptocurrency_id=serializer.validated_data['cryptocurrency_id'],
                    usd_amount=serializer.validated_data['usd_amount']
                )
                
                response_serializer = CryptoTransactionSerializer(transaction)
                return Response(response_serializer.data, status=status.HTTP_201_CREATED)
                
            except ValueError as e:
                return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response(
                    {'error': 'Transaction failed'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CryptoSellView(APIView):
    """Sell cryptocurrency for USD"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CryptoSellSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            try:
                crypto_service = CryptoService()
                transaction = crypto_service.sell_cryptocurrency(
                    user=request.user,
                    wallet_id=serializer.validated_data['wallet_id'],
                    crypto_amount=serializer.validated_data['crypto_amount']
                )
                
                response_serializer = CryptoTransactionSerializer(transaction)
                return Response(response_serializer.data, status=status.HTTP_201_CREATED)
                
            except ValueError as e:
                return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response(
                    {'error': 'Transaction failed'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CryptoTransferView(APIView):
    """Transfer cryptocurrency to another address"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CryptoTransferSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            try:
                crypto_service = CryptoService()
                transaction = crypto_service.transfer_cryptocurrency(
                    user=request.user,
                    wallet_id=serializer.validated_data['wallet_id'],
                    to_address=serializer.validated_data['to_address'],
                    crypto_amount=serializer.validated_data['crypto_amount']
                )
                
                response_serializer = CryptoTransactionSerializer(transaction)
                return Response(response_serializer.data, status=status.HTTP_201_CREATED)
                
            except ValueError as e:
                return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response(
                    {'error': 'Transfer failed'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CryptoPortfolioView(APIView):
    """Get user's crypto portfolio summary"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        crypto_service = CryptoService()
        portfolio_data = crypto_service.get_user_portfolio(request.user)
        
        serializer = CryptoPortfolioSerializer(portfolio_data)
        return Response(serializer.data)


class CryptoInitializeView(APIView):
    """Initialize popular cryptocurrencies (admin only)"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        crypto_service = CryptoService()
        created_count = crypto_service.initialize_popular_cryptocurrencies()
        
        return Response({
            'message': f'Initialized {created_count} new cryptocurrencies'
        })


class UserAnalyticsView(APIView):
    """
    Comprehensive user analytics and statistics
    Provides detailed financial overview for the user
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        try:
            # Get current date for calculations
            now = timezone.now()
            current_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            last_month = (current_month - timedelta(days=1)).replace(day=1)
            
            # Cards analytics
            cards_data = self._get_cards_analytics(user)
            
            # Transactions analytics
            transactions_data = self._get_transactions_analytics(user, current_month, last_month)
            
            # Financial products analytics
            loans_data = self._get_loans_analytics(user)
            deposits_data = self._get_deposits_analytics(user)
            mortgages_data = self._get_mortgages_analytics(user)
            
            # Crypto analytics
            crypto_data = self._get_crypto_analytics(user)
            
            # Overall financial health
            financial_health = self._calculate_financial_health(user, cards_data, loans_data, deposits_data)
            
            analytics = {
                'user_info': {
                    'full_name': user.get_full_name(),
                    'phone_number': user.phone_number,
                    'member_since': user.date_joined.strftime('%Y-%m-%d'),
                    'last_activity': user.last_login.strftime('%Y-%m-%d %H:%M') if user.last_login else None,
                },
                'cards': cards_data,
                'transactions': transactions_data,
                'loans': loans_data,
                'deposits': deposits_data,
                'mortgages': mortgages_data,
                'crypto': crypto_data,
                'financial_health': financial_health,
                'generated_at': now.strftime('%Y-%m-%d %H:%M:%S')
            }
            
            return Response(analytics, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to generate analytics: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _get_cards_analytics(self, user):
        """Get detailed cards analytics"""
        cards = Card.objects.filter(owner=user)
        
        total_balance = sum(card.balance for card in cards)
        active_cards = cards.filter(is_blocked=False).count()
        blocked_cards = cards.filter(is_blocked=True).count()
        
        # Find most used card (by transaction count)
        most_used_card = None
        max_transactions = 0
        
        for card in cards:
            transaction_count = Transaction.objects.filter(user=user).count()  # Simplified
            if transaction_count > max_transactions:
                max_transactions = transaction_count
                most_used_card = {
                    'name': card.card_name,
                    'number': card.card_number[-4:],  # Last 4 digits
                    'transaction_count': transaction_count
                }
        
        return {
            'total_cards': cards.count(),
            'active_cards': active_cards,
            'blocked_cards': blocked_cards,
            'total_balance': float(total_balance),
            'average_balance': float(total_balance / cards.count()) if cards.count() > 0 else 0,
            'most_used_card': most_used_card,
            'cards_list': [
                {
                    'id': str(card.id),
                    'name': card.card_name,
                    'balance': float(card.balance),
                    'is_blocked': card.is_blocked,
                    'is_default': card.is_default,
                    'last_four': card.card_number[-4:] if card.card_number else '****'
                }
                for card in cards
            ]
        }
    
    def _get_transactions_analytics(self, user, current_month, last_month):
        """Get detailed transactions analytics"""
        all_transactions = Transaction.objects.filter(user=user)
        current_month_transactions = all_transactions.filter(timestamp__gte=current_month)
        last_month_transactions = all_transactions.filter(
            timestamp__gte=last_month, 
            timestamp__lt=current_month
        )
        
        # Income vs Expense analysis
        total_income = all_transactions.filter(transaction_type=1).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        total_expense = all_transactions.filter(transaction_type=2).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        # Monthly comparison
        current_month_income = current_month_transactions.filter(transaction_type=1).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        current_month_expense = current_month_transactions.filter(transaction_type=2).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        last_month_income = last_month_transactions.filter(transaction_type=1).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        last_month_expense = last_month_transactions.filter(transaction_type=2).aggregate(
            total=Sum('amount')
        )['total'] or 0
        
        # Calculate trends
        income_trend = self._calculate_trend(current_month_income, last_month_income)
        expense_trend = self._calculate_trend(current_month_expense, last_month_expense)
        
        return {
            'total_transactions': all_transactions.count(),
            'current_month_transactions': current_month_transactions.count(),
            'total_income': float(total_income),
            'total_expense': float(total_expense),
            'net_balance': float(total_income - total_expense),
            'current_month': {
                'income': float(current_month_income),
                'expense': float(current_month_expense),
                'net': float(current_month_income - current_month_expense),
                'transaction_count': current_month_transactions.count()
            },
            'last_month': {
                'income': float(last_month_income),
                'expense': float(last_month_expense),
                'net': float(last_month_income - last_month_expense),
                'transaction_count': last_month_transactions.count()
            },
            'trends': {
                'income_trend': income_trend,
                'expense_trend': expense_trend
            },
            'average_transaction': float(
                all_transactions.aggregate(avg=Avg('amount'))['avg'] or 0
            )
        }
    
    def _get_loans_analytics(self, user):
        """Get detailed loans analytics"""
        loans = Loan.objects.filter(user=user)
        active_loans = loans.filter(is_active=True)
        
        total_borrowed = active_loans.aggregate(total=Sum('total_amount'))['total'] or 0
        total_remaining = active_loans.aggregate(total=Sum('remaining_debt'))['total'] or 0
        
        # Next payment calculation
        next_payment = None
        next_payment_amount = 0
        
        for loan in active_loans:
            # Use the monthly_payment field from the model
            if not next_payment or loan.next_payment_date < next_payment:
                next_payment = loan.next_payment_date
                next_payment_amount = loan.monthly_payment
        
        return {
            'total_loans': loans.count(),
            'active_loans': active_loans.count(),
            'inactive_loans': loans.filter(is_active=False).count(),
            'total_borrowed': float(total_borrowed),
            'total_remaining_debt': float(total_remaining),
            'next_payment': {
                'date': next_payment.strftime('%Y-%m-%d') if next_payment else None,
                'amount': float(next_payment_amount)
            },
            'loans_list': [
                {
                    'id': str(loan.id),
                    'total_amount': float(loan.total_amount),
                    'remaining_debt': float(loan.remaining_debt),
                    'interest_rate': float(loan.interest_rate),
                    'term_months': loan.term_months,
                    'monthly_payment': float(loan.monthly_payment),
                    'is_active': loan.is_active,
                    'issue_date': loan.issue_date.strftime('%Y-%m-%d')
                }
                for loan in loans
            ]
        }
    
    def _get_deposits_analytics(self, user):
        """Get detailed deposits analytics"""
        deposits = Deposit.objects.filter(user=user)
        active_deposits = deposits  # All deposits are considered active
        
        total_deposited = active_deposits.aggregate(total=Sum('amount'))['total'] or 0
        
        # Calculate total interest earned (simplified)
        total_interest = sum(
            float(deposit.amount) * (float(deposit.interest_rate)/100) * (deposit.term_months/12)
            for deposit in active_deposits
        )
        
        average_rate = active_deposits.aggregate(avg=Avg('interest_rate'))['avg'] or 0
        
        return {
            'total_deposits': deposits.count(),
            'active_deposits': active_deposits.count(),
            'total_deposited': float(total_deposited),
            'total_interest_earned': float(total_interest),
            'average_interest_rate': float(average_rate),
            'deposits_list': [
                {
                    'id': str(deposit.id),
                    'amount': float(deposit.amount),
                    'interest_rate': float(deposit.interest_rate),
                    'term_months': deposit.term_months,
                    'start_date': deposit.start_date.strftime('%Y-%m-%d')
                }
                for deposit in deposits
            ]
        }
    
    def _get_mortgages_analytics(self, user):
        """Get detailed mortgages analytics"""
        mortgages = Mortgage.objects.filter(user=user)
        active_mortgages = mortgages.filter(is_active=True)
        
        total_mortgage_amount = active_mortgages.aggregate(total=Sum('property_cost'))['total'] or 0
        total_loan_amount = active_mortgages.aggregate(total=Sum('total_amount'))['total'] or 0
        
        return {
            'total_mortgages': mortgages.count(),
            'active_mortgages': active_mortgages.count(),
            'inactive_mortgages': mortgages.filter(is_active=False).count(),
            'total_property_value': float(total_mortgage_amount),
            'total_loan_amount': float(total_loan_amount),
            'mortgages_list': [
                {
                    'id': str(mortgage.id),
                    'property_cost': float(mortgage.property_cost),
                    'initial_payment': float(mortgage.initial_payment),
                    'total_amount': float(mortgage.total_amount),
                    'interest_rate': float(mortgage.interest_rate),
                    'term_years': mortgage.term_years,
                    'monthly_payment': float(mortgage.monthly_payment),
                    'is_active': mortgage.is_active,
                    'issue_date': mortgage.issue_date.strftime('%Y-%m-%d')
                }
                for mortgage in mortgages
            ]
        }
    
    def _get_crypto_analytics(self, user):
        """Get crypto portfolio analytics"""
        try:
            wallets = CryptoWallet.objects.filter(user=user)
            total_portfolio_value = 0
            
            portfolio = []
            for wallet in wallets:
                # Get current price and calculate value
                crypto_value = float(wallet.balance * wallet.cryptocurrency.current_price_usd)
                total_portfolio_value += crypto_value
                
                portfolio.append({
                    'currency': wallet.cryptocurrency.symbol,
                    'name': wallet.cryptocurrency.name,
                    'balance': float(wallet.balance),
                    'current_price': float(wallet.cryptocurrency.current_price_usd),
                    'value_usd': crypto_value
                })
            
            return {
                'total_wallets': wallets.count(),
                'total_portfolio_value_usd': total_portfolio_value,
                'portfolio': portfolio
            }
        except Exception:
            return {
                'total_wallets': 0,
                'total_portfolio_value_usd': 0,
                'portfolio': []
            }
    
    def _calculate_financial_health(self, user, cards_data, loans_data, deposits_data):
        """Calculate overall financial health score"""
        score = 100  # Start with perfect score
        
        # Deduct points for high debt
        if loans_data['total_remaining_debt'] > 0:
            debt_ratio = loans_data['total_remaining_debt'] / max(cards_data['total_balance'], 1)
            if debt_ratio > 0.5:
                score -= 20
            elif debt_ratio > 0.3:
                score -= 10
        
        # Add points for deposits
        if deposits_data['total_deposited'] > 0:
            score += min(10, deposits_data['total_deposited'] / 10000)
        
        # Deduct points for blocked cards
        if cards_data['blocked_cards'] > 0:
            score -= cards_data['blocked_cards'] * 5
        
        # Ensure score is between 0 and 100
        score = max(0, min(100, score))
        
        # Determine health level
        if score >= 80:
            health_level = 'excellent'
        elif score >= 60:
            health_level = 'good'
        elif score >= 40:
            health_level = 'fair'
        else:
            health_level = 'poor'
        
        return {
            'score': int(score),
            'level': health_level,
            'recommendations': self._get_recommendations(score, loans_data, deposits_data)
        }
    
    def _get_recommendations(self, score, loans_data, deposits_data):
        """Get personalized financial recommendations"""
        recommendations = []
        
        if score < 60:
            recommendations.append("Рассмотрите возможность погашения задолженности")
        
        if loans_data['total_remaining_debt'] > 0:
            recommendations.append("Планируйте досрочное погашение кредитов для экономии на процентах")
        
        if deposits_data['total_deposited'] == 0:
            recommendations.append("Откройте депозит для получения пассивного дохода")
        
        if not recommendations:
            recommendations.append("Отличная финансовая дисциплина! Продолжайте в том же духе")
        
        return recommendations
    
    def _calculate_trend(self, current, previous):
        """Calculate percentage trend between two values"""
        if previous == 0:
            return 0 if current == 0 else 100
        
        return round(((current - previous) / previous) * 100, 2)


class ProfileImageUploadView(APIView):
    """
    Upload and update user profile image
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        try:
            if 'image' not in request.FILES:
                return Response(
                    {'error': 'No image file provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            image_file = request.FILES['image']
            
            # Validate image
            if not self._is_valid_image(image_file):
                return Response(
                    {'error': 'Invalid image format. Please use JPG, PNG, or WEBP'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check file size (max 5MB)
            if image_file.size > 5 * 1024 * 1024:
                return Response(
                    {'error': 'Image too large. Maximum size is 5MB'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Delete old profile image if exists
            user = request.user
            if user.profile_image:
                old_image_path = user.profile_image.path
                if os.path.exists(old_image_path):
                    os.remove(old_image_path)
            
            # Save new image
            user.profile_image = image_file
            user.save()
            
            # Process image (resize if needed)
            self._process_profile_image(user.profile_image.path)
            
            return Response({
                'message': 'Profile image updated successfully',
                'image_url': request.build_absolute_uri(user.profile_image.url)
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to upload image: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request):
        """Delete user profile image"""
        try:
            user = request.user
            if user.profile_image:
                # Delete file from storage
                image_path = user.profile_image.path
                if os.path.exists(image_path):
                    os.remove(image_path)
                
                # Clear database field
                user.profile_image = None
                user.save()
                
                return Response({
                    'message': 'Profile image deleted successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'message': 'No profile image to delete'
                }, status=status.HTTP_404_NOT_FOUND)
                
        except Exception as e:
            return Response(
                {'error': f'Failed to delete image: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _is_valid_image(self, image_file):
        """Validate image format"""
        try:
            img = Image.open(image_file)
            return img.format.lower() in ['jpeg', 'jpg', 'png', 'webp']
        except:
            return False
    
    def _process_profile_image(self, image_path):
        """Resize and optimize profile image"""
        try:
            with Image.open(image_path) as img:
                # Convert to RGB if necessary
                if img.mode in ('RGBA', 'LA', 'P'):
                    img = img.convert('RGB')
                
                # Resize to max 400x400 while maintaining aspect ratio
                img.thumbnail((400, 400), Image.Resampling.LANCZOS)
                
                # Save optimized image
                img.save(image_path, 'JPEG', quality=85, optimize=True)
        except Exception as e:
            print(f"Error processing profile image: {e}")


class CardImageUploadView(APIView):
    """
    Upload and update card image
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request, card_id):
        try:
            # Get the card
            try:
                card = Card.objects.get(id=card_id, owner=request.user)
            except Card.DoesNotExist:
                return Response(
                    {'error': 'Card not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if 'image' not in request.FILES:
                return Response(
                    {'error': 'No image file provided'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            image_file = request.FILES['image']
            
            # Validate image
            if not self._is_valid_image(image_file):
                return Response(
                    {'error': 'Invalid image format. Please use JPG, PNG, or WEBP'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check file size (max 3MB for cards)
            if image_file.size > 3 * 1024 * 1024:
                return Response(
                    {'error': 'Image too large. Maximum size is 3MB'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Delete old card image if exists
            if card.card_image:
                old_image_path = card.card_image.path
                if os.path.exists(old_image_path):
                    os.remove(old_image_path)
            
            # Save new image
            card.card_image = image_file
            card.save()
            
            # Process image (resize for card format)
            self._process_card_image(card.card_image.path)
            
            return Response({
                'message': 'Card image updated successfully',
                'image_url': request.build_absolute_uri(card.card_image.url),
                'card_id': str(card.id)
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to upload card image: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, card_id):
        """Delete card image"""
        try:
            # Get the card
            try:
                card = Card.objects.get(id=card_id, owner=request.user)
            except Card.DoesNotExist:
                return Response(
                    {'error': 'Card not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if card.card_image:
                # Delete file from storage
                image_path = card.card_image.path
                if os.path.exists(image_path):
                    os.remove(image_path)
                
                # Clear database field
                card.card_image = None
                card.save()
                
                return Response({
                    'message': 'Card image deleted successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'message': 'No card image to delete'
                }, status=status.HTTP_404_NOT_FOUND)
                
        except Exception as e:
            return Response(
                {'error': f'Failed to delete card image: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _is_valid_image(self, image_file):
        """Validate image format"""
        try:
            img = Image.open(image_file)
            return img.format.lower() in ['jpeg', 'jpg', 'png', 'webp']
        except:
            return False
    
    def _process_card_image(self, image_path):
        """Resize and optimize card image to card format"""
        try:
            with Image.open(image_path) as img:
                # Convert to RGB if necessary
                if img.mode in ('RGBA', 'LA', 'P'):
                    img = img.convert('RGB')
                
                # Resize to card format (16:10 aspect ratio, max 600x375)
                target_width = 600
                target_height = 375
                
                # Calculate dimensions maintaining aspect ratio
                img_ratio = img.width / img.height
                target_ratio = target_width / target_height
                
                if img_ratio > target_ratio:
                    # Image is wider, fit to height
                    new_height = target_height
                    new_width = int(target_height * img_ratio)
                else:
                    # Image is taller, fit to width
                    new_width = target_width
                    new_height = int(target_width / img_ratio)
                
                # Resize image
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                
                # Crop to exact card dimensions if needed
                if new_width > target_width or new_height > target_height:
                    left = (new_width - target_width) // 2
                    top = (new_height - target_height) // 2
                    right = left + target_width
                    bottom = top + target_height
                    img = img.crop((left, top, right, bottom))
                
                # Save optimized image
                img.save(image_path, 'JPEG', quality=90, optimize=True)
        except Exception as e:
            print(f"Error processing card image: {e}")



