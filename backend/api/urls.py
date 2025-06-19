from django.urls import path, include
from rest_framework_nested import routers
from rest_framework.authtoken.views import obtain_auth_token
from .views import (
    UserRegistrationView,
    ObtainAuthTokenView,
    UserProfileView,
    CardListView,
    SetDefaultCardView,
    TransactionListView,
    AdminCreditScoreCheck,
    LoanCreateView,
    MortgageCreateView,
    DepositCreateView,
    CardCreateView,
    ApplicationUpdateView,
    AdminApplicationListView,
    TransferView,
    CurrencyViewSet,
    ForumPostViewSet,
    ForumCommentViewSet,
    TerminalViewSet,
    CardViewSet,
    AIChatViewSet,
    AIChatMessageView,
    PredictionPostViewSet,
    # Crypto views
    CryptoCurrencyViewSet,
    CryptoWalletViewSet,
    CryptoTransactionViewSet,
    CryptoBuyView,
    CryptoSellView,
    CryptoTransferView,
    CryptoPortfolioView,
    CryptoInitializeView,
    UserAnalyticsView,
    ProfileImageUploadView,
    CardImageUploadView,
)

# Main router for top-level resources
router = routers.DefaultRouter()
router.register(r'cards', CardViewSet, basename='card')
router.register(r'currencies', CurrencyViewSet, basename='currency')
router.register(r'forum/posts', ForumPostViewSet, basename='forum-post')
router.register(r'terminals', TerminalViewSet, basename='terminal')
router.register(r'ai/chats', AIChatViewSet, basename='ai-chat')
router.register(r'predictions', PredictionPostViewSet, basename='prediction')
# Crypto endpoints
router.register(r'crypto/currencies', CryptoCurrencyViewSet, basename='crypto-currency')
router.register(r'crypto/wallets', CryptoWalletViewSet, basename='crypto-wallet')
router.register(r'crypto/transactions', CryptoTransactionViewSet, basename='crypto-transaction')

# Nested router for comments within a forum post
posts_router = routers.NestedSimpleRouter(router, r'forum/posts', lookup='post')
posts_router.register(r'comments', ForumCommentViewSet, basename='forum-post-comments')

urlpatterns = [
    path('', include(router.urls)),
    path('', include(posts_router.urls)),
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', ObtainAuthTokenView.as_view(), name='login'),
    path('user/', UserProfileView.as_view(), name='user-detail'),
    path('cards/', CardListView.as_view(), name='card-list'),
    path('cards/create/', CardCreateView.as_view(), name='card-create'),
    path('cards/<uuid:pk>/set-default/', SetDefaultCardView.as_view(), name='card-set-default'),
    path('transactions/', TransactionListView.as_view(), name='transaction-list'),
    path('transfers/', TransferView.as_view(), name='transfers'),
    path('admin/check-score/<int:user_id>/', AdminCreditScoreCheck.as_view(), name='admin-check-score'),
    
    # Application endpoints
    path('loan/apply/', LoanCreateView.as_view(), name='loan-apply'),
    path('mortgage/apply/', MortgageCreateView.as_view(), name='mortgage-apply'),
    path('deposit/apply/', DepositCreateView.as_view(), name='deposit-apply'),
    path('card/apply/', CardCreateView.as_view(), name='card-apply'),
    
    # Admin application management
    path('admin/applications/', AdminApplicationListView.as_view(), name='admin-applications-list'),
    path('admin/applications/<uuid:pk>/update/', ApplicationUpdateView.as_view(), name='admin-application-update'),
    
    # AI Chat endpoints
    path('ai/chat/', AIChatMessageView.as_view(), name='ai-chat-message'),
    
    # Analytics endpoint
    path('analytics/', UserAnalyticsView.as_view(), name='user-analytics'),
    
    # Image upload endpoints
    path('profile/image/', ProfileImageUploadView.as_view(), name='profile-image-upload'),
    path('cards/<uuid:card_id>/image/', CardImageUploadView.as_view(), name='card-image-upload'),
    
    # Crypto endpoints
    path('crypto/buy/', CryptoBuyView.as_view(), name='crypto-buy'),
    path('crypto/sell/', CryptoSellView.as_view(), name='crypto-sell'),
    path('crypto/transfer/', CryptoTransferView.as_view(), name='crypto-transfer'),
    path('crypto/portfolio/', CryptoPortfolioView.as_view(), name='crypto-portfolio'),
    path('crypto/initialize/', CryptoInitializeView.as_view(), name='crypto-initialize'),
] 