from django.urls import path
from .views import (
    UserRegistrationView, 
    UserLoginView,
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
    TransferView
)

urlpatterns = [
    path('register/', UserRegistrationView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('cards/', CardListView.as_view(), name='card-list'),
    path('cards/<uuid:pk>/set-default/', SetDefaultCardView.as_view(), name='card-set-default'),
    path('transactions/', TransactionListView.as_view(), name='transaction-list'),
    path('transfer/', TransferView.as_view(), name='transfer'),
    path('admin/check-score/<int:user_id>/', AdminCreditScoreCheck.as_view(), name='admin-check-score'),
    
    # Application endpoints
    path('loan/apply/', LoanCreateView.as_view(), name='loan-apply'),
    path('mortgage/apply/', MortgageCreateView.as_view(), name='mortgage-apply'),
    path('deposit/apply/', DepositCreateView.as_view(), name='deposit-apply'),
    path('card/apply/', CardCreateView.as_view(), name='card-apply'),
    
    # Admin application management
    path('admin/applications/<uuid:pk>/update/', ApplicationUpdateView.as_view(), name='admin-application-update'),
] 