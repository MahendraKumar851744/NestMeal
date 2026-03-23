from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView,
    LoginView,
    UserProfileView,
    ChangePasswordView,
    CustomerProfileViewSet,
    CookProfileViewSet,
    CookPublicListView,
    CookPublicDetailView,
    AddressViewSet,
)

router = DefaultRouter()
router.register(r'addresses', AddressViewSet, basename='address')
router.register(r'cook-profiles', CookProfileViewSet, basename='cook-profile')
router.register(r'customer-profiles', CustomerProfileViewSet, basename='customer-profile')

urlpatterns = [
    # Authentication
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # Current user
    path('me/', UserProfileView.as_view(), name='user-profile'),
    path('me/change-password/', ChangePasswordView.as_view(), name='change-password'),

    # Public cook listing and detail
    path('cooks/', CookPublicListView.as_view(), name='cook-public-list'),
    path('cooks/<uuid:pk>/', CookPublicDetailView.as_view(), name='cook-public-detail'),

    # Router-generated CRUD routes
    path('', include(router.urls)),
]
