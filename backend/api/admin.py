from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, Transaction, Card, Deposit, Loan, 
    Mortgage, Application, Currency, CurrencyHistory, ForumPost, ForumComment, ForumLike, Terminal,
    AIChat, AIChatMessage, PredictionPost, PredictionComment, PredictionLike,
    CryptoCurrency, CryptoWallet, CryptoTransaction, CryptoPriceHistory
)
from .forms import CustomUserCreationForm, CustomUserChangeForm

class CustomUserAdmin(BaseUserAdmin):
    model = User
    # Which fields to display in the list view
    list_display = ('phone_number', 'email', 'first_name', 'last_name', 'is_staff')
    # Which fields to use for searching
    search_fields = ('phone_number', 'email', 'first_name', 'last_name')
    # What to use for ordering
    ordering = ('phone_number',)

    # Define fieldsets for the edit form
    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'middle_name', 'email', 'avatar')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    # Add fields that are not in fieldsets but should be editable
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'password', 'first_name', 'last_name', 'email', 'is_staff'),
        }),
    )

admin.site.register(User, CustomUserAdmin)

@admin.register(Application)
class ApplicationAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "application_type",
        "status",
        "created_at",
        "updated_at",
    )
    list_filter = ("status", "application_type")
    search_fields = ("user__phone_number",)

@admin.register(Currency)
class CurrencyAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "flag_emoji")
    search_fields = ("code", "name")

@admin.register(CurrencyHistory)
class CurrencyHistoryAdmin(admin.ModelAdmin):
    list_display = ("currency", "base_currency", "rate", "timestamp")
    list_filter = ("currency", "base_currency")
    search_fields = ("currency__code",)
    date_hierarchy = "timestamp"

admin.site.register(Transaction)

@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ('card_number', 'owner', 'balance', 'is_active')
    search_fields = ('card_number', 'owner__phone_number')
    list_filter = ('is_active',)
    raw_id_fields = ('owner',)

@admin.register(Deposit)
class DepositAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'interest_rate', 'start_date')
    search_fields = ('user__phone_number',)
    raw_id_fields = ('user',)

@admin.register(Loan)
class LoanAdmin(admin.ModelAdmin):
    list_display = ('user', 'total_amount', 'remaining_debt', 'interest_rate', 'is_active')
    search_fields = ('user__phone_number',)
    list_filter = ('is_active',)
    raw_id_fields = ('user',)

@admin.register(Mortgage)
class MortgageAdmin(admin.ModelAdmin):
    list_display = ('user', 'property_cost', 'total_amount', 'interest_rate', 'is_active')
    search_fields = ('user__phone_number',)
    list_filter = ('is_active',)
    raw_id_fields = ('user',)

@admin.register(ForumPost)
class ForumPostAdmin(admin.ModelAdmin):
    list_display = ('title', 'author', 'likes_count', 'comments_count', 'is_pinned', 'is_locked', 'created_at')
    search_fields = ('title', 'content', 'author__phone_number')
    list_filter = ('is_pinned', 'is_locked', 'created_at', 'author')
    readonly_fields = ('likes_count', 'comments_count', 'created_at', 'updated_at')
    raw_id_fields = ('author',)

@admin.register(ForumComment)
class ForumCommentAdmin(admin.ModelAdmin):
    list_display = ('post', 'author', 'content_preview', 'created_at')
    search_fields = ('content', 'author__phone_number')
    list_filter = ('created_at', 'author')
    raw_id_fields = ('author', 'post')
    readonly_fields = ('created_at', 'updated_at')

    def content_preview(self, obj):
        return obj.content[:100] + ('...' if len(obj.content) > 100 else '')
    content_preview.short_description = 'Content Preview'

@admin.register(ForumLike)
class ForumLikeAdmin(admin.ModelAdmin):
    list_display = ('user', 'post', 'created_at')
    search_fields = ('user__phone_number', 'post__title')
    list_filter = ('created_at',)
    raw_id_fields = ('user', 'post')

@admin.register(Terminal)
class TerminalAdmin(admin.ModelAdmin):
    list_display = ('name', 'address', 'is_active')
    search_fields = ('name', 'address')
    list_filter = ('is_active',)


# AI Chat Admin
@admin.register(AIChat)
class AIChatAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'created_at', 'updated_at', 'is_active')
    search_fields = ('user__phone_number', 'title')
    list_filter = ('is_active', 'created_at')
    raw_id_fields = ('user',)
    readonly_fields = ('created_at', 'updated_at')

    def get_title(self, obj):
        return obj.get_title()
    get_title.short_description = 'Title'


@admin.register(AIChatMessage)
class AIChatMessageAdmin(admin.ModelAdmin):
    list_display = ('chat', 'role', 'content_preview', 'created_at', 'tokens_used')
    search_fields = ('content', 'chat__user__phone_number')
    list_filter = ('role', 'created_at', 'model_used')
    raw_id_fields = ('chat',)
    readonly_fields = ('created_at', 'tokens_used', 'model_used', 'processing_time')

    def content_preview(self, obj):
        return obj.content[:100] + ('...' if len(obj.content) > 100 else '')
    content_preview.short_description = 'Content Preview'


# Prediction Forum Admin
@admin.register(PredictionPost)
class PredictionPostAdmin(admin.ModelAdmin):
    list_display = ('currency_pair', 'author', 'direction', 'confidence', 'likes_count', 'created_at')
    search_fields = ('currency_pair', 'prediction_text', 'author__phone_number')
    list_filter = ('direction', 'created_at', 'currency_pair')
    raw_id_fields = ('author',)
    readonly_fields = ('likes_count', 'comments_count', 'created_at', 'updated_at')


@admin.register(PredictionComment)
class PredictionCommentAdmin(admin.ModelAdmin):
    list_display = ('post', 'author', 'content_preview', 'created_at')
    search_fields = ('content', 'author__phone_number')
    list_filter = ('created_at',)
    raw_id_fields = ('author', 'post')
    readonly_fields = ('created_at', 'updated_at')

    def content_preview(self, obj):
        return obj.content[:100] + ('...' if len(obj.content) > 100 else '')
    content_preview.short_description = 'Content Preview'


@admin.register(PredictionLike)
class PredictionLikeAdmin(admin.ModelAdmin):
    list_display = ('user', 'post', 'created_at')
    search_fields = ('user__phone_number', 'post__currency_pair')
    list_filter = ('created_at',)
    raw_id_fields = ('user', 'post')


# Cryptocurrency Admin
@admin.register(CryptoCurrency)
class CryptoCurrencyAdmin(admin.ModelAdmin):
    list_display = ('symbol', 'name', 'current_price_usd', 'price_change_24h', 'market_cap', 'is_active', 'last_updated')
    search_fields = ('symbol', 'name', 'id')
    list_filter = ('is_active', 'last_updated')
    readonly_fields = ('created_at', 'last_updated')
    ordering = ['symbol']

    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing existing object
            return self.readonly_fields + ('id',)
        return self.readonly_fields


@admin.register(CryptoWallet)
class CryptoWalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'cryptocurrency', 'balance', 'balance_usd_display', 'wallet_address', 'is_active', 'created_at')
    search_fields = ('user__phone_number', 'cryptocurrency__symbol', 'wallet_address')
    list_filter = ('is_active', 'cryptocurrency', 'created_at')
    raw_id_fields = ('user', 'cryptocurrency')
    readonly_fields = ('created_at', 'updated_at', 'balance_usd_display')

    def balance_usd_display(self, obj):
        return f"${obj.balance_usd:.2f}"
    balance_usd_display.short_description = 'Balance USD'


@admin.register(CryptoTransaction)
class CryptoTransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'cryptocurrency_symbol', 'transaction_type', 'status', 'crypto_amount', 'usd_amount', 'created_at')
    search_fields = ('user__phone_number', 'wallet__cryptocurrency__symbol', 'transaction_hash')
    list_filter = ('transaction_type', 'status', 'created_at', 'wallet__cryptocurrency')
    raw_id_fields = ('user', 'wallet')
    readonly_fields = ('created_at', 'completed_at', 'transaction_hash')

    def cryptocurrency_symbol(self, obj):
        return obj.wallet.cryptocurrency.symbol
    cryptocurrency_symbol.short_description = 'Crypto'


@admin.register(CryptoPriceHistory)
class CryptoPriceHistoryAdmin(admin.ModelAdmin):
    list_display = ('cryptocurrency', 'price_usd', 'market_cap', 'volume_24h', 'timestamp')
    search_fields = ('cryptocurrency__symbol',)
    list_filter = ('cryptocurrency', 'timestamp')
    raw_id_fields = ('cryptocurrency',)
    readonly_fields = ('timestamp',)
    date_hierarchy = 'timestamp'

    def has_add_permission(self, request):
        return False  # Price history is auto-generated
