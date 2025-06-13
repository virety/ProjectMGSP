from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.contrib.auth.hashers import make_password, check_password
from django.db import models
from django.utils.translation import gettext_lazy as _
import uuid
import random
import string
from datetime import date, timedelta

class UserManager(BaseUserManager):
    """Define a model manager for User model with no username field."""

    def _create_user(self, phone_number, password, **extra_fields):
        """Create and save a User with the given phone number and password."""
        if not phone_number:
            raise ValueError('The given phone number must be set')
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(phone_number, password, **extra_fields)

    def create_superuser(self, phone_number, password, **extra_fields):
        """Create and save a SuperUser with the given phone number and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(phone_number, password, **extra_fields)


class User(AbstractUser):
    username = None # We use phone_number instead
    phone_number = models.CharField(max_length=15, unique=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    middle_name = models.CharField(max_length=30, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    profile_image = models.ImageField(upload_to='profiles/', null=True, blank=True)
    
    pin_code = models.CharField(max_length=128, blank=True)
    avatar = models.URLField(blank=True) # Assuming avatar is a URL to an image
    
    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    objects = UserManager()

    def set_pin(self, raw_pin):
        self.pin_code = make_password(str(raw_pin))
        self.save()

    def check_pin(self, raw_pin):
        return check_password(str(raw_pin), self.pin_code)

    def get_default_card(self):
        # The default card is the first one created.
        return self.cards.order_by('card_issue_date').first()

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.phone_number})"


class Transaction(models.Model):
    TRANSACTION_TYPES = [
        (0, 'Expense'),
        (1, 'Income'),
        # Add other types if needed, based on app logic
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    title = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    timestamp = models.DateTimeField(auto_now_add=True)
    transaction_type = models.SmallIntegerField(choices=TRANSACTION_TYPES, default=0)

    def __str__(self):
        return f'{self.title} ({self.get_transaction_type_display()}) - {self.amount}'


class Card(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cards')
    card_name = models.CharField(max_length=100)
    card_number = models.CharField(max_length=19, unique=True)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    card_expiry_date = models.DateField()
    card_issue_date = models.DateField(auto_now_add=True)
    cvv = models.CharField(max_length=3)
    is_default = models.BooleanField(default=False)
    is_blocked = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    card_image = models.ImageField(upload_to='cards/', null=True, blank=True)
    
    # Fields from CDUser that seem to belong to Card
    gradient_start_hex = models.CharField(max_length=7, blank=True)
    gradient_end_hex = models.CharField(max_length=7, blank=True)
    
    def __str__(self):
        return f"{self.card_name} - {self.card_number[-4:]}"

    @staticmethod
    def generate_card_number():
        return ''.join(random.choices(string.digits, k=16))

    @staticmethod
    def generate_cvv():
        return ''.join(random.choices(string.digits, k=3))

    @staticmethod
    def generate_expiration_date():
        return date.today() + timedelta(days=365 * 4) # 4 years from now


class Deposit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='deposits')
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2) # e.g., 5.75 for 5.75%
    term_months = models.IntegerField()
    start_date = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"Deposit of {self.amount} for {self.user.phone_number}"


class Loan(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='loans')
    total_amount = models.DecimalField(max_digits=15, decimal_places=2)
    remaining_debt = models.DecimalField(max_digits=15, decimal_places=2)
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)
    term_months = models.IntegerField()
    monthly_payment = models.DecimalField(max_digits=10, decimal_places=2)
    issue_date = models.DateField(auto_now_add=True)
    next_payment_date = models.DateField()
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"Loan of {self.total_amount} for {self.user.phone_number}"


class Mortgage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mortgages')
    property_cost = models.DecimalField(max_digits=15, decimal_places=2)
    initial_payment = models.DecimalField(max_digits=15, decimal_places=2)
    total_amount = models.DecimalField(max_digits=15, decimal_places=2)
    term_years = models.IntegerField()
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)
    monthly_payment = models.DecimalField(max_digits=10, decimal_places=2)
    issue_date = models.DateField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"Mortgage for {self.user.phone_number}"


class Application(models.Model):
    APPLICATION_TYPES = [
        ('LOAN', 'Loan'),
        ('MORTGAGE', 'Mortgage'),
        ('DEPOSIT', 'Deposit'),
        ('CARD', 'Card'),
    ]
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='applications')
    application_type = models.CharField(max_length=10, choices=APPLICATION_TYPES)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    details = models.JSONField() # To store amount, term, etc.
    rejection_reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Application for {self.get_application_type_display()} for {self.user.phone_number} - {self.get_status_display()}"


class Currency(models.Model):
    code = models.CharField(max_length=3, primary_key=True, help_text="ISO 4217 currency code")
    name = models.CharField(max_length=50)
    flag_emoji = models.CharField(max_length=5, blank=True)

    class Meta:
        verbose_name = "Currency"
        verbose_name_plural = "Currencies"

    def __str__(self):
        return f"{self.code} ({self.name})"


class CurrencyHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency = models.ForeignKey(Currency, on_delete=models.CASCADE, related_name='history')
    base_currency = models.CharField(max_length=3, default='RUB', help_text="The base currency for the rate (e.g., RUB)")
    rate = models.DecimalField(max_digits=20, decimal_places=10, help_text="Rate of the currency against the base currency")
    timestamp = models.DateTimeField(help_text="The timestamp of the recorded rate")

    class Meta:
        verbose_name = "Currency History"
        verbose_name_plural = "Currency History"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['currency', 'timestamp']),
        ]

    def __str__(self):
        return f"{self.currency.code} to {self.base_currency} at {self.timestamp}: {self.rate}"


class ForumPost(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forum_posts')
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Social features
    likes_count = models.IntegerField(default=0)
    comments_count = models.IntegerField(default=0)
    is_pinned = models.BooleanField(default=False)
    is_locked = models.BooleanField(default=False)

    class Meta:
        ordering = ['-is_pinned', '-created_at']

    def __str__(self):
        return self.title


class ForumComment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forum_comments')
    post = models.ForeignKey(ForumPost, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Comment by {self.author.get_full_name()} on {self.post.title}"


class ForumLike(models.Model):
    """Likes on forum posts"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forum_likes')
    post = models.ForeignKey(ForumPost, on_delete=models.CASCADE, related_name='likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'post']
        verbose_name = "Forum Like"
        verbose_name_plural = "Forum Likes"

    def __str__(self):
        return f"{self.user.get_full_name()} likes {self.post.title}"


class Terminal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_active = models.BooleanField(default=True)
    services = models.JSONField(default=dict, blank=True) # e.g., {"cash_in": true, "cash_out": true}

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = "Terminal"
        verbose_name_plural = "Terminals"


class AIChat(models.Model):
    """AI Chat session for a user"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ai_chats')
    title = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-updated_at']
        verbose_name = "AI Chat"
        verbose_name_plural = "AI Chats"

    def __str__(self):
        return f"AI Chat {self.title or 'Untitled'} for {self.user.phone_number}"

    def get_title(self):
        """Generate title from first user message if not set"""
        if self.title:
            return self.title
        first_message = self.messages.filter(role='user').first()
        if first_message:
            return first_message.content[:50] + ('...' if len(first_message.content) > 50 else '')
        return "New Chat"


class AIChatMessage(models.Model):
    """Individual message in an AI chat"""
    ROLE_CHOICES = [
        ('user', 'User'),
        ('assistant', 'Assistant'),
        ('system', 'System'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chat = models.ForeignKey(AIChat, on_delete=models.CASCADE, related_name='messages')
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Optional fields for metadata
    tokens_used = models.IntegerField(null=True, blank=True)
    model_used = models.CharField(max_length=50, blank=True)
    processing_time = models.FloatField(null=True, blank=True)  # in seconds

    class Meta:
        ordering = ['created_at']
        verbose_name = "AI Chat Message"
        verbose_name_plural = "AI Chat Messages"

    def __str__(self):
        return f"{self.get_role_display()}: {self.content[:50]}..."


class PredictionPost(models.Model):
    """Forum post with market predictions"""
    DIRECTION_CHOICES = [
        ('up', 'Up'),
        ('down', 'Down'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prediction_posts')
    currency_pair = models.CharField(max_length=10, help_text="e.g., USD/RUB")
    prediction_text = models.TextField()
    direction = models.CharField(max_length=4, choices=DIRECTION_CHOICES)
    confidence = models.IntegerField(help_text="Confidence level 1-100")
    target_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Social features
    likes_count = models.IntegerField(default=0)
    comments_count = models.IntegerField(default=0)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Prediction Post"
        verbose_name_plural = "Prediction Posts"

    def __str__(self):
        return f"{self.currency_pair} {self.get_direction_display()} prediction by {self.author.phone_number}"


class PredictionComment(models.Model):
    """Comments on prediction posts"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prediction_comments')
    post = models.ForeignKey(PredictionPost, on_delete=models.CASCADE, related_name='comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = "Prediction Comment"
        verbose_name_plural = "Prediction Comments"

    def __str__(self):
        return f"Comment by {self.author.phone_number} on {self.post.currency_pair}"


class PredictionLike(models.Model):
    """Likes on prediction posts"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prediction_likes')
    post = models.ForeignKey(PredictionPost, on_delete=models.CASCADE, related_name='likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'post']
        verbose_name = "Prediction Like"
        verbose_name_plural = "Prediction Likes"

    def __str__(self):
        return f"{self.user.phone_number} likes {self.post.currency_pair}"


# Cryptocurrency Models
class CryptoCurrency(models.Model):
    """Supported cryptocurrencies"""
    id = models.CharField(max_length=50, primary_key=True, help_text="CoinGecko ID (e.g., bitcoin)")
    symbol = models.CharField(max_length=10, unique=True, help_text="Symbol (e.g., BTC)")
    name = models.CharField(max_length=100, help_text="Full name (e.g., Bitcoin)")
    icon_url = models.URLField(blank=True, help_text="Icon URL from CoinGecko")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Current market data (updated periodically)
    current_price_usd = models.DecimalField(max_digits=20, decimal_places=8, default=0)
    market_cap = models.BigIntegerField(default=0)
    price_change_24h = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    last_updated = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Cryptocurrency"
        verbose_name_plural = "Cryptocurrencies"
        ordering = ['symbol']

    def __str__(self):
        return f"{self.symbol} ({self.name})"


class CryptoWallet(models.Model):
    """User's cryptocurrency wallet"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='crypto_wallets')
    cryptocurrency = models.ForeignKey(CryptoCurrency, on_delete=models.CASCADE)
    balance = models.DecimalField(max_digits=20, decimal_places=8, default=0)
    wallet_address = models.CharField(max_length=255, blank=True, help_text="Wallet address (if applicable)")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['user', 'cryptocurrency']
        verbose_name = "Crypto Wallet"
        verbose_name_plural = "Crypto Wallets"

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.cryptocurrency.symbol}: {self.balance}"

    @property
    def balance_usd(self):
        """Calculate balance in USD"""
        return self.balance * self.cryptocurrency.current_price_usd

    def generate_wallet_address(self):
        """Generate a mock wallet address"""
        import hashlib
        data = f"{self.user.id}{self.cryptocurrency.id}{self.created_at}"
        return hashlib.sha256(data.encode()).hexdigest()[:34]


class CryptoTransaction(models.Model):
    """Cryptocurrency transactions"""
    TRANSACTION_TYPES = [
        ('buy', 'Buy'),
        ('sell', 'Sell'),
        ('transfer_in', 'Transfer In'),
        ('transfer_out', 'Transfer Out'),
        ('exchange', 'Exchange'),
    ]

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='crypto_transactions')
    wallet = models.ForeignKey(CryptoWallet, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Transaction amounts
    crypto_amount = models.DecimalField(max_digits=20, decimal_places=8)
    usd_amount = models.DecimalField(max_digits=15, decimal_places=2)
    fee_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    
    # Exchange rate at time of transaction
    exchange_rate = models.DecimalField(max_digits=20, decimal_places=8)
    
    # For transfers
    from_address = models.CharField(max_length=255, blank=True)
    to_address = models.CharField(max_length=255, blank=True)
    
    # Transaction hash (for blockchain transactions)
    transaction_hash = models.CharField(max_length=255, blank=True)
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Crypto Transaction"
        verbose_name_plural = "Crypto Transactions"

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.transaction_type} {self.crypto_amount} {self.wallet.cryptocurrency.symbol}"

    def generate_transaction_hash(self):
        """Generate a mock transaction hash"""
        import hashlib
        import time
        data = f"{self.id}{self.user.id}{time.time()}"
        return hashlib.sha256(data.encode()).hexdigest()


class CryptoPriceHistory(models.Model):
    """Historical price data for cryptocurrencies"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cryptocurrency = models.ForeignKey(CryptoCurrency, on_delete=models.CASCADE, related_name='price_history')
    price_usd = models.DecimalField(max_digits=20, decimal_places=8)
    market_cap = models.BigIntegerField()
    volume_24h = models.BigIntegerField(default=0)
    timestamp = models.DateTimeField()

    class Meta:
        ordering = ['-timestamp']
        verbose_name = "Crypto Price History"
        verbose_name_plural = "Crypto Price History"
        indexes = [
            models.Index(fields=['cryptocurrency', 'timestamp']),
        ]

    def __str__(self):
        return f"{self.cryptocurrency.symbol} - ${self.price_usd} at {self.timestamp}"


# Django signals for automatic counter updates
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

@receiver(post_save, sender=ForumComment)
def update_forum_comment_count_on_create(sender, instance, created, **kwargs):
    """Update comment count when a new comment is created"""
    if created:
        instance.post.comments_count = instance.post.comments.count()
        instance.post.save(update_fields=['comments_count'])

@receiver(post_delete, sender=ForumComment)
def update_forum_comment_count_on_delete(sender, instance, **kwargs):
    """Update comment count when a comment is deleted"""
    instance.post.comments_count = instance.post.comments.count()
    instance.post.save(update_fields=['comments_count'])

@receiver(post_save, sender=ForumLike)
def update_forum_like_count_on_create(sender, instance, created, **kwargs):
    """Update like count when a new like is created"""
    if created:
        instance.post.likes_count = instance.post.likes.count()
        instance.post.save(update_fields=['likes_count'])

@receiver(post_delete, sender=ForumLike)
def update_forum_like_count_on_delete(sender, instance, **kwargs):
    """Update like count when a like is deleted"""
    instance.post.likes_count = instance.post.likes.count()
    instance.post.save(update_fields=['likes_count'])

@receiver(post_save, sender=PredictionComment)
def update_prediction_comment_count_on_create(sender, instance, created, **kwargs):
    """Update comment count when a new prediction comment is created"""
    if created:
        instance.post.comments_count = instance.post.comments.count()
        instance.post.save(update_fields=['comments_count'])

@receiver(post_delete, sender=PredictionComment)
def update_prediction_comment_count_on_delete(sender, instance, **kwargs):
    """Update comment count when a prediction comment is deleted"""
    instance.post.comments_count = instance.post.comments.count()
    instance.post.save(update_fields=['comments_count'])

@receiver(post_save, sender=PredictionLike)
def update_prediction_like_count_on_create(sender, instance, created, **kwargs):
    """Update like count when a new prediction like is created"""
    if created:
        instance.post.likes_count = instance.post.likes.count()
        instance.post.save(update_fields=['likes_count'])

@receiver(post_delete, sender=PredictionLike)
def update_prediction_like_count_on_delete(sender, instance, **kwargs):
    """Update like count when a prediction like is deleted"""
    instance.post.likes_count = instance.post.likes.count()
    instance.post.save(update_fields=['likes_count'])
