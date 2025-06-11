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
    phone_number = models.CharField(_('phone number'), max_length=20, unique=True)
    
    # We keep email for communication, but it's not for login
    email = models.EmailField(_('email address'), blank=True)
    
    pin_code = models.CharField(max_length=128, blank=True)
    middle_name = models.CharField(max_length=150, blank=True)
    avatar = models.URLField(blank=True) # Assuming avatar is a URL to an image

    USERNAME_FIELD = 'phone_number'
    # first_name and last_name are required by default in AbstractUser
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
        return self.phone_number


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
    card_name = models.CharField(max_length=100, blank=True)
    card_number = models.CharField(max_length=16, unique=True)
    balance = models.DecimalField(max_digits=15, decimal_places=2, default=0.00)
    card_expiry_date = models.DateField()
    card_issue_date = models.DateField(auto_now_add=True)
    cvv = models.CharField(max_length=4) # Should be stored encrypted in a real app
    is_default = models.BooleanField(default=False)
    
    # Fields from CDUser that seem to belong to Card
    gradient_start_hex = models.CharField(max_length=7, blank=True)
    gradient_end_hex = models.CharField(max_length=7, blank=True)
    
    def __str__(self):
        return f"Card {self.card_number} for {self.owner.phone_number}"

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
        return f"{self.get_application_type_display()} application for {self.user.phone_number} - {self.status}"
