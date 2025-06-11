from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User, Transaction, Card, Deposit, Loan, Mortgage, Application
from decimal import Decimal

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ('phone_number', 'password', 'first_name', 'last_name', 'email')
        extra_kwargs = {
            'first_name': {'required': True, 'allow_blank': False},
            'last_name': {'required': True, 'allow_blank': False},
            'email': {'required': True, 'allow_blank': False},
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data['phone_number'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            email=validated_data['email']
        )
        return user

class AuthTokenSerializer(serializers.Serializer):
    phone_number = serializers.CharField(
        label="Phone Number",
        write_only=True
    )
    password = serializers.CharField(
        label="Password",
        style={'input_type': 'password'},
        trim_whitespace=False,
        write_only=True
    )
    token = serializers.CharField(
        label="Token",
        read_only=True
    )

    def validate(self, attrs):
        phone_number = attrs.get('phone_number')
        password = attrs.get('password')

        if phone_number and password:
            user = authenticate(request=self.context.get('request'),
                                phone_number=phone_number, password=password)

            if not user:
                msg = 'Unable to log in with provided credentials.'
                raise serializers.ValidationError(msg, code='authorization')
        else:
            msg = 'Must include "phone_number" and "password".'
            raise serializers.ValidationError(msg, code='authorization')

        attrs['user'] = user
        return attrs

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'phone_number', 'first_name', 'last_name', 'email')

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ('id', 'user', 'title', 'amount', 'transaction_type', 'timestamp')

class CardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Card
        fields = [
            'id', 'card_name', 'card_number', 'balance', 
            'card_expiry_date', 'gradient_start_hex', 'gradient_end_hex'
        ]

class DepositSerializer(serializers.ModelSerializer):
    class Meta:
        model = Deposit
        fields = ['id', 'amount', 'interest_rate', 'term_months', 'start_date']
        read_only_fields = ['interest_rate', 'start_date']

class LoanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Loan
        fields = [
            'id', 'total_amount', 'term_months', 'interest_rate', 
            'monthly_payment', 'issue_date', 'next_payment_date', 'remaining_debt'
        ]
        read_only_fields = [
            'interest_rate', 'monthly_payment', 'issue_date', 
            'next_payment_date', 'remaining_debt'
        ]
        
    def validate(self, data):
        if data['total_amount'] < 10000:
            raise serializers.ValidationError("Минимальная сумма кредита - 10 000")
        if not (1 <= data['term_months'] <= 60):
            raise serializers.ValidationError("Срок кредита должен быть от 1 до 60 месяцев.")
        return data

class MortgageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mortgage
        fields = '__all__'

class ApplicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Application
        fields = '__all__'
        read_only_fields = ('user', 'status', 'rejection_reason')

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'first_name', 'last_name', 'middle_name', 'email', 'avatar']
        read_only_fields = ['phone_number']
        extra_kwargs = {
            'first_name': {'allow_blank': False},
            'last_name': {'allow_blank': False},
            'email': {'allow_blank': False},
        }

class TransferSerializer(serializers.Serializer):
    sender_card_number = serializers.CharField(max_length=20)
    recipient_identifier = serializers.CharField(max_length=100)
    amount = serializers.DecimalField(max_digits=15, decimal_places=2)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Сумма перевода должна быть положительной.")
        return value 