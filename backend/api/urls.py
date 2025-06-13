from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserRegistrationView,
    UserProfileView,
    CardViewSet,
    TransactionViewSet,
    LoanViewSet,
    MortgageViewSet,
    NotificationViewSet,
    SupportTicketViewSet,
    ForumPostViewSet,
    ForumCommentViewSet,
    AnalyticsViewSet,
    DepositViewSet,
    TestView,
    send_verification_code,
    verify_phone_number,
    check_verification_status
)

router = DefaultRouter()
router.register(r'users', UserProfileView, basename='user')
router.register(r'cards', CardViewSet)
router.register(r'transactions', TransactionViewSet)
router.register(r'loans', LoanViewSet)
router.register(r'mortgages', MortgageViewSet)
router.register(r'notifications', NotificationViewSet)
router.register(r'support-tickets', SupportTicketViewSet)
router.register(r'forum/posts', ForumPostViewSet)
router.register(r'forum/comments', ForumCommentViewSet)
router.register(r'analytics', AnalyticsViewSet, basename='analytics')
router.register(r'deposits', DepositViewSet)


urlpatterns = [
    path('', include(router.urls)),
    path('register/', UserRegistrationView.as_view(), name='user-registration'),
    path('test/', TestView.as_view(), name='test-view'), # Наш тестовый эндпоинт
    path('send-verification-code/', send_verification_code, name='send-verification-code'),
    path('verify-phone-number/', verify_phone_number, name='verify-phone-number'),
    path('check-verification-status/', check_verification_status, name='check-verification-status'),
] 