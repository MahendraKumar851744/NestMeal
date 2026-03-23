from rest_framework import generics, status, viewsets, filters
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    User,
    CustomerProfile,
    CookProfile,
    Address,
)
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    CustomerProfileSerializer,
    CookProfileSerializer,
    AddressSerializer,
    ChangePasswordSerializer,
)
from .permissions import IsCook, IsCustomer, IsAdmin, IsOwnerOrAdmin


# ---------------------------------------------------------------------------
# Authentication views
# ---------------------------------------------------------------------------

class RegisterView(generics.CreateAPIView):
    """POST /register/ -- create a new user and its role-specific profile."""

    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for immediate login after registration
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'user': UserSerializer(user).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """POST /login/ -- authenticate and return JWT tokens."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = UserLoginSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'user': UserSerializer(user).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                },
            },
            status=status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Current-user views
# ---------------------------------------------------------------------------

class UserProfileView(generics.RetrieveUpdateAPIView):
    """GET/PUT /me/ -- retrieve or update the currently authenticated user."""

    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        user = self.get_object()
        # Only allow updating a safe subset of fields
        allowed_fields = {'full_name', 'phone', 'profile_picture_url'}
        data = {k: v for k, v in request.data.items() if k in allowed_fields}

        for attr, value in data.items():
            setattr(user, attr, value)
        user.save(update_fields=list(data.keys()))
        return Response(UserSerializer(user).data)


class ChangePasswordView(APIView):
    """POST /me/change-password/ -- change the authenticated user's password."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {'detail': 'Password updated successfully.'},
            status=status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Customer profiles
# ---------------------------------------------------------------------------

class CustomerProfileViewSet(viewsets.ModelViewSet):
    """CRUD for customer profiles. Customers see only their own profile;
    admins can list/manage all."""

    serializer_class = CustomerProfileSerializer
    permission_classes = [IsAuthenticated, IsCustomer | IsAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return CustomerProfile.objects.select_related('user').all()
        return CustomerProfile.objects.select_related('user').filter(user=user)


# ---------------------------------------------------------------------------
# Cook profiles
# ---------------------------------------------------------------------------

class CookProfileViewSet(viewsets.ModelViewSet):
    """CRUD for cook profiles. Cooks see only their own profile;
    admins can list/manage all. Supports filtering by kitchen_city."""

    serializer_class = CookProfileSerializer
    permission_classes = [IsAuthenticated, IsCook | IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['kitchen_city', 'status', 'is_active']
    search_fields = ['display_name', 'kitchen_city']
    ordering_fields = ['avg_rating', 'total_reviews', 'created_at']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return CookProfile.objects.select_related('user').prefetch_related(
                'pickup_locations'
            ).all()
        return CookProfile.objects.select_related('user').prefetch_related(
            'pickup_locations'
        ).filter(user=user)


class CookPublicListView(generics.ListAPIView):
    """GET /cooks/ -- public listing of verified, active cooks for browsing.
    Supports filtering by city and searching by display_name."""

    serializer_class = CookProfileSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['kitchen_city']
    search_fields = ['display_name', 'bio', 'kitchen_city']
    ordering_fields = ['avg_rating', 'total_reviews']
    ordering = ['-avg_rating']

    def get_queryset(self):
        return (
            CookProfile.objects
            .select_related('user')
            .prefetch_related('pickup_locations')
            .filter(status='active', is_active=True)
        )


class CookPublicDetailView(generics.RetrieveAPIView):
    """GET /cooks/<id>/ -- public detail of a single cook profile."""

    serializer_class = CookProfileSerializer
    permission_classes = [AllowAny]
    lookup_field = 'pk'

    def get_queryset(self):
        return (
            CookProfile.objects
            .select_related('user')
            .prefetch_related('pickup_locations')
            .filter(status='active', is_active=True)
        )


# ---------------------------------------------------------------------------
# Addresses
# ---------------------------------------------------------------------------

class AddressViewSet(viewsets.ModelViewSet):
    """CRUD for the authenticated user's addresses."""

    serializer_class = AddressSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrAdmin]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return Address.objects.select_related('user').all()
        return Address.objects.filter(user=user)
