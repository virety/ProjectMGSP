from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers
from .models import User, Transaction, Card, Deposit, Loan, Mortgage, Application, Currency, CurrencyHistory, ForumComment, ForumPost, Terminal, AIChat, AIChatMessage, PredictionPost, PredictionComment, PredictionLike, CryptoCurrency, CryptoWallet, CryptoTransaction, CryptoPriceHistory
from decimal import Decimal
from datetime import datetime, timedelta
from django.utils.translation import gettext_lazy as _

User = get_user_model()

class CurrencyHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CurrencyHistory
        fields = ['rate', 'timestamp']


class CurrencySerializer(serializers.ModelSerializer):
    history = serializers.SerializerMethodField()
    change_percent = serializers.SerializerMethodField()

    class Meta:
        model = Currency
        fields = ['code', 'name', 'flag_emoji', 'change_percent', 'history']

    def get_history(self, obj):
        # Limit history to the last 30 days for performance
        thirty_days_ago = serializers.DateTimeField().to_representation(
            serializers.DateTimeField().to_internal_value(datetime.now()) - timedelta(days=30)
        )
        history_qs = obj.history.filter(timestamp__gte=thirty_days_ago).order_by('timestamp')
        return CurrencyHistorySerializer(history_qs, many=True).data

    def get_change_percent(self, obj):
        # Get the last two history entries to calculate the percentage change
        latest_two = obj.history.order_by('-timestamp')[:2]
        if len(latest_two) < 2:
            return 0.0
        
        latest_rate = latest_two[0].rate
        previous_rate = latest_two[1].rate

        if previous_rate == 0:
            return 0.0

        change = ((latest_rate - previous_rate) / previous_rate) * 100
        return round(float(change), 4)

class AuthTokenSerializer(serializers.Serializer):
    phone_number = serializers.CharField(label=_("Phone Number"))
    password = serializers.CharField(
        label=_("Password"),
        style={'input_type': 'password'},
        trim_whitespace=False
    )

    def validate(self, attrs):
        phone_number = attrs.get('phone_number')
        password = attrs.get('password')

        if phone_number and password:
            user = authenticate(
                request=self.context.get('request'),
                phone_number=phone_number,
                password=password
            )

            if not user:
                msg = _('Unable to log in with provided credentials.')
                raise serializers.ValidationError(msg, code='authorization')
        else:
            msg = _('Must include "phone_number" and "password".')
            raise serializers.ValidationError(msg, code='authorization')

        attrs['user'] = user
        return attrs

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

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'phone_number', 'email', 'first_name', 'last_name', 'date_joined')

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
        fields = ['id', 'amount', 'interest_rate', 'term_months', 'start_date', 'total_interest']
        read_only_fields = ['interest_rate', 'start_date', 'total_interest']

class LoanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Loan
        fields = [
            'id', 'total_amount', 'term_months', 'interest_rate', 
            'monthly_payment', 'issue_date', 'next_payment_date', 'remaining_debt',
            'late_payments', 'next_payment_amount'
        ]
        read_only_fields = [
            'interest_rate', 'monthly_payment', 'issue_date', 
            'next_payment_date', 'remaining_debt', 'late_payments', 'next_payment_amount'
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
        fields = [
            'id', 'property_cost', 'initial_payment', 'total_amount', 'term_years',
            'interest_rate', 'monthly_payment', 'issue_date', 'is_active',
            'late_payments', 'central_bank_rate', 'overpayment'
        ]
        read_only_fields = ['late_payments', 'central_bank_rate', 'overpayment']

class ApplicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Application
        fields = '__all__'
        read_only_fields = ('user', 'status', 'rejection_reason')

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'first_name', 'last_name', 'middle_name', 'email', 'avatar', 'total_balance']
        read_only_fields = ['phone_number', 'total_balance']
        extra_kwargs = {
            'first_name': {'allow_blank': False},
            'last_name': {'allow_blank': False},
            'email': {'allow_blank': False},
        }

class TransferSerializer(serializers.Serializer):
    source_card_id = serializers.UUIDField()
    target_card_number = serializers.CharField(max_length=100)
    amount = serializers.DecimalField(max_digits=15, decimal_places=2)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Сумма перевода должна быть положительной.")
        return value

class ForumCommentSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)

    class Meta:
        model = ForumComment
        fields = ['id', 'author', 'content', 'created_at', 'updated_at']
        read_only_fields = ['author', 'post']

    def create(self, validated_data):
        # The author will be the authenticated user
        validated_data['author'] = self.context['request'].user
        # The post will be injected from the view's context
        validated_data['post'] = self.context['post']
        return super().create(validated_data)

class ForumPostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    comments = ForumCommentSerializer(many=True, read_only=True)
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = ForumPost
        fields = [
            'id', 'author', 'title', 'content', 'created_at', 'updated_at', 
            'likes_count', 'comments_count', 'is_pinned', 'is_locked', 
            'comments', 'is_liked'
        ]
        read_only_fields = ['author', 'likes_count', 'comments_count']

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)

class TerminalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Terminal
        fields = ['id', 'name', 'address', 'latitude', 'longitude', 'is_active', 'services']


# AI Chat Serializers
class AIChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIChatMessage
        fields = ['id', 'role', 'content', 'created_at', 'tokens_used', 'model_used', 'processing_time']
        read_only_fields = ['id', 'created_at', 'tokens_used', 'model_used', 'processing_time']


class AIChatSerializer(serializers.ModelSerializer):
    messages = AIChatMessageSerializer(many=True, read_only=True)
    messages_count = serializers.IntegerField(source='messages.count', read_only=True)
    title = serializers.CharField(read_only=True)

    class Meta:
        model = AIChat
        fields = ['id', 'title', 'created_at', 'updated_at', 'is_active', 'messages_count', 'messages']
        read_only_fields = ['id', 'created_at', 'updated_at', 'user']


class AIChatListSerializer(serializers.ModelSerializer):
    """Simplified serializer for chat list (without messages)"""
    messages_count = serializers.IntegerField(source='messages.count', read_only=True)
    last_message = serializers.SerializerMethodField()
    title = serializers.SerializerMethodField()

    class Meta:
        model = AIChat
        fields = ['id', 'title', 'created_at', 'updated_at', 'messages_count', 'last_message']

    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return {
                'role': last_msg.role,
                'content': last_msg.content[:100] + ('...' if len(last_msg.content) > 100 else ''),
                'created_at': last_msg.created_at
            }
        return None

    def get_title(self, obj):
        return obj.get_title()


class ChatMessageCreateSerializer(serializers.Serializer):
    """Serializer for creating new chat messages"""
    message = serializers.CharField(max_length=2000)
    chat_id = serializers.UUIDField(required=False, allow_null=True)

    def validate_message(self, value):
        if not value.strip():
            raise serializers.ValidationError("Сообщение не может быть пустым.")
        return value.strip()


# Prediction Forum Serializers
class PredictionCommentSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)

    class Meta:
        model = PredictionComment
        fields = ['id', 'author', 'content', 'created_at', 'updated_at']
        read_only_fields = ['author', 'post']

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        validated_data['post'] = self.context['post']
        return super().create(validated_data)


class PredictionPostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    comments = PredictionCommentSerializer(many=True, read_only=True)
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = PredictionPost
        fields = [
            'id', 'author', 'currency_pair', 'prediction_text', 'direction', 
            'confidence', 'target_date', 'created_at', 'updated_at',
            'likes_count', 'comments_count', 'comments', 'is_liked'
        ]
        read_only_fields = ['author', 'likes_count', 'comments_count']

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)

    def validate_confidence(self, value):
        if not (1 <= value <= 100):
            raise serializers.ValidationError("Уверенность должна быть от 1 до 100.")
        return value


class PredictionPostCreateSerializer(serializers.ModelSerializer):
    """Simplified serializer for creating predictions"""
    class Meta:
        model = PredictionPost
        fields = ['currency_pair', 'prediction_text', 'direction', 'confidence', 'target_date']

    def validate_confidence(self, value):
        if not (1 <= value <= 100):
            raise serializers.ValidationError("Уверенность должна быть от 1 до 100.")
        return value

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)


# Cryptocurrency Serializers
class CryptoCurrencySerializer(serializers.ModelSerializer):
    price_change_percent = serializers.SerializerMethodField()
    
    class Meta:
        model = CryptoCurrency
        fields = [
            'id', 'symbol', 'name', 'icon_url', 'current_price_usd', 
            'market_cap', 'price_change_24h', 'price_change_percent', 'last_updated'
        ]
    
    def get_price_change_percent(self, obj):
        if obj.current_price_usd > 0:
            return round((obj.price_change_24h / obj.current_price_usd) * 100, 2)
        return 0


class CryptoWalletSerializer(serializers.ModelSerializer):
    cryptocurrency = CryptoCurrencySerializer(read_only=True)
    balance_usd = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = CryptoWallet
        fields = [
            'id', 'cryptocurrency', 'balance', 'balance_usd', 
            'wallet_address', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'wallet_address', 'created_at', 'updated_at']


class CryptoWalletCreateSerializer(serializers.Serializer):
    cryptocurrency_id = serializers.CharField(max_length=50)
    
    def validate_cryptocurrency_id(self, value):
        try:
            cryptocurrency = CryptoCurrency.objects.get(id=value, is_active=True)
        except CryptoCurrency.DoesNotExist:
            raise serializers.ValidationError("Криптовалюта не найдена или неактивна.")
        return value
    
    def create(self, validated_data):
        user = self.context['request'].user
        cryptocurrency = CryptoCurrency.objects.get(id=validated_data['cryptocurrency_id'])
        
        # Check if wallet already exists
        wallet, created = CryptoWallet.objects.get_or_create(
            user=user,
            cryptocurrency=cryptocurrency,
            defaults={'wallet_address': ''}
        )
        
        if created:
            wallet.wallet_address = wallet.generate_wallet_address()
            wallet.save()
        
        return wallet


class CryptoTransactionSerializer(serializers.ModelSerializer):
    wallet = CryptoWalletSerializer(read_only=True)
    cryptocurrency_symbol = serializers.CharField(source='wallet.cryptocurrency.symbol', read_only=True)
    
    class Meta:
        model = CryptoTransaction
        fields = [
            'id', 'wallet', 'cryptocurrency_symbol', 'transaction_type', 'status',
            'crypto_amount', 'usd_amount', 'fee_amount', 'exchange_rate',
            'from_address', 'to_address', 'transaction_hash', 'notes',
            'created_at', 'completed_at'
        ]
        read_only_fields = [
            'user', 'exchange_rate', 'transaction_hash', 'created_at', 'completed_at'
        ]


class CryptoBuySerializer(serializers.Serializer):
    cryptocurrency_id = serializers.CharField(max_length=50)
    usd_amount = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=Decimal('1'))
    
    def validate_cryptocurrency_id(self, value):
        try:
            cryptocurrency = CryptoCurrency.objects.get(id=value, is_active=True)
        except CryptoCurrency.DoesNotExist:
            raise serializers.ValidationError("Криптовалюта не найдена.")
        return value
    
    def validate_usd_amount(self, value):
        if value < 1:
            raise serializers.ValidationError("Минимальная сумма покупки $1.")
        if value > 10000:
            raise serializers.ValidationError("Максимальная сумма покупки $10,000.")
        return value


class CryptoSellSerializer(serializers.Serializer):
    wallet_id = serializers.UUIDField()
    crypto_amount = serializers.DecimalField(max_digits=20, decimal_places=8, min_value=Decimal('0.00000001'))
    
    def validate_wallet_id(self, value):
        user = self.context['request'].user
        try:
            wallet = CryptoWallet.objects.get(id=value, user=user, is_active=True)
        except CryptoWallet.DoesNotExist:
            raise serializers.ValidationError("Кошелек не найден.")
        return value
    
    def validate(self, data):
        user = self.context['request'].user
        wallet = CryptoWallet.objects.get(id=data['wallet_id'], user=user)
        
        if data['crypto_amount'] > wallet.balance:
            raise serializers.ValidationError("Недостаточно средств в кошельке.")
        
        return data


class CryptoTransferSerializer(serializers.Serializer):
    wallet_id = serializers.UUIDField()
    to_address = serializers.CharField(max_length=255)
    crypto_amount = serializers.DecimalField(max_digits=20, decimal_places=8, min_value=Decimal('0.00000001'))
    
    def validate_wallet_id(self, value):
        user = self.context['request'].user
        try:
            wallet = CryptoWallet.objects.get(id=value, user=user, is_active=True)
        except CryptoWallet.DoesNotExist:
            raise serializers.ValidationError("Кошелек не найден.")
        return value
    
    def validate(self, data):
        user = self.context['request'].user
        wallet = CryptoWallet.objects.get(id=data['wallet_id'], user=user)
        
        if data['crypto_amount'] > wallet.balance:
            raise serializers.ValidationError("Недостаточно средств в кошельке.")
        
        # Check if trying to send to own address
        if data['to_address'] == wallet.wallet_address:
            raise serializers.ValidationError("Нельзя отправить на свой адрес.")
        
        return data


class CryptoPriceHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CryptoPriceHistory
        fields = ['price_usd', 'market_cap', 'volume_24h', 'timestamp']


class CryptoPortfolioSerializer(serializers.Serializer):
    """Serializer for user's crypto portfolio summary"""
    total_balance_usd = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_change_24h = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_change_percent = serializers.DecimalField(max_digits=10, decimal_places=2)
    wallets = CryptoWalletSerializer(many=True)
    top_holdings = serializers.ListField(child=serializers.DictField()) 