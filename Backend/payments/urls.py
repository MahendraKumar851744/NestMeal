from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PaymentViewSet, CookPayoutViewSet, WalletTopUpView

router = DefaultRouter()
router.register(r'payments', PaymentViewSet, basename='payment')
router.register(r'payouts', CookPayoutViewSet, basename='payout')

urlpatterns = [
    path('payments/wallet/top-up/', WalletTopUpView.as_view(), name='wallet-top-up'),
    path('', include(router.urls)),
]
