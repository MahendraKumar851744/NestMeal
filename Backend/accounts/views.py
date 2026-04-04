from django.db.models import Count, Exists, OuterRef
from rest_framework import generics, status, viewsets, filters
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django_filters.rest_framework import DjangoFilterBackend

from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import random

from .models import (
    User,
    CustomerProfile,
    CookProfile,
    Address,
    Follow,
    PhoneOTP,
)
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    CustomerProfileSerializer,
    CookProfileSerializer,
    AddressSerializer,
    ChangePasswordSerializer,
    SendOTPSerializer,
    VerifyOTPSerializer,
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

    # ─── NEW ACTIONS FOR ADMIN DASHBOARD ──────────────────────────────

    @action(
        detail=False, 
        methods=['get'], 
        permission_classes=[IsAuthenticated, IsAdmin]
    )
    def pending(self, request):
        """GET /cook-profiles/pending/ -- Fetch all cooks waiting for verification."""
        # Because we are using self.get_queryset(), it already applies the 
        # admin check from above, but the permission_class enforces it strictly.
        pending_cooks = self.get_queryset().filter(status='pending_verification')
        
        page = self.paginate_queryset(pending_cooks)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(pending_cooks, many=True)
        return Response(serializer.data)

    @action(
        detail=True, 
        methods=['post'], 
        permission_classes=[IsAuthenticated, IsAdmin]
    )
    def approve(self, request, pk=None):
        """POST /cook-profiles/<id>/approve/ -- Approve a specific cook profile."""
        cook_profile = self.get_object()

        if cook_profile.status == 'active':
            return Response(
                {"detail": "This cook is already active."}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update both status and ensure is_active is True
        cook_profile.status = 'active'
        cook_profile.is_active = True
        cook_profile.save(update_fields=['status', 'is_active', 'updated_at'])

        return Response(
            {"detail": f"Cook {cook_profile.display_name} has been successfully approved."}, 
            status=status.HTTP_200_OK
        )


def _annotate_cook_queryset(queryset, request):
    """Annotate a CookProfile queryset with followers_count and is_followed."""
    queryset = queryset.annotate(followers_count=Count('followers'))
    if request and request.user and request.user.is_authenticated:
        queryset = queryset.annotate(
            is_followed=Exists(
                Follow.objects.filter(
                    cook=OuterRef('pk'),
                    customer=request.user,
                )
            )
        )
    else:
        from django.db.models import Value
        queryset = queryset.annotate(is_followed=Value(False))
    return queryset


class CookPublicListView(generics.ListAPIView):
    """GET /cooks/ -- public listing of verified, active cooks for browsing.
    Supports filtering by city and searching by display_name."""

    serializer_class = CookProfileSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['kitchen_city']
    search_fields = ['display_name', 'bio', 'kitchen_city']
    ordering_fields = ['avg_rating', 'total_reviews', 'followers_count']
    ordering = ['-avg_rating']

    def get_queryset(self):
        qs = (
            CookProfile.objects
            .select_related('user')
            .prefetch_related('pickup_locations')
            .filter(status='active', is_active=True)
        )
        return _annotate_cook_queryset(qs, self.request)


class CookPublicDetailView(generics.RetrieveAPIView):
    """GET /cooks/<id>/ -- public detail of a single cook profile."""

    serializer_class = CookProfileSerializer
    permission_classes = [AllowAny]
    lookup_field = 'pk'

    def get_queryset(self):
        qs = (
            CookProfile.objects
            .select_related('user')
            .prefetch_related('pickup_locations')
            .filter(status='active', is_active=True)
        )
        return _annotate_cook_queryset(qs, self.request)


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


# ---------------------------------------------------------------------------
# Follow
# ---------------------------------------------------------------------------

class ToggleFollowView(APIView):
    """POST /cooks/<id>/follow/ -- toggle follow/unfollow a cook."""

    permission_classes = [IsAuthenticated, IsCustomer]

    def post(self, request, pk):
        try:
            cook = CookProfile.objects.get(pk=pk, status='active', is_active=True)
        except CookProfile.DoesNotExist:
            return Response(
                {'detail': 'Cook not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        follow, created = Follow.objects.get_or_create(
            customer=request.user,
            cook=cook,
        )
        if not created:
            follow.delete()
            return Response(
                {'status': 'unfollowed', 'is_followed': False},
                status=status.HTTP_200_OK,
            )
        return Response(
            {'status': 'followed', 'is_followed': True},
            status=status.HTTP_201_CREATED,
        )


class MyFollowingListView(generics.ListAPIView):
    """GET /me/following/ -- list cooks the authenticated customer follows."""

    serializer_class = CookProfileSerializer
    permission_classes = [IsAuthenticated, IsCustomer]

    def get_queryset(self):
        cook_ids = Follow.objects.filter(
            customer=self.request.user
        ).values_list('cook_id', flat=True)
        qs = (
            CookProfile.objects
            .select_related('user')
            .prefetch_related('pickup_locations')
            .filter(pk__in=cook_ids, status='active', is_active=True)
        )
        return _annotate_cook_queryset(qs, self.request)


# ---------------------------------------------------------------------------
# OTP Verification
# ---------------------------------------------------------------------------

# Mock OTP for testing — accepts "1234" always.
# Set MOCK_OTP = False in settings to disable when real SMS is connected.
MOCK_OTP_CODE = '1234'
OTP_EXPIRY_MINUTES = 5
OTP_MAX_ATTEMPTS = 5


def _send_sms(phone, otp_code):
    """Placeholder for third-party SMS API integration.
    Replace this function body with the real SMS provider call."""
    # TODO: Integrate real SMS provider (Twilio, MSG91, etc.)
    # For now, OTP is logged to console for development.
    print(f"[SMS MOCK] OTP {otp_code} sent to {phone}")


class SendOTPView(APIView):
    """POST /otp/send/ -- generate and send OTP to a phone number.
    Can be called by anyone (pre-auth for registration, or authenticated users)."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone']

        # Rate limit: max 1 OTP per phone per minute
        one_min_ago = timezone.now() - timedelta(minutes=1)
        recent = PhoneOTP.objects.filter(
            phone=phone, created_at__gte=one_min_ago, is_verified=False
        ).exists()
        if recent:
            return Response(
                {'detail': 'OTP already sent. Please wait before requesting again.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Invalidate previous unverified OTPs for this phone
        PhoneOTP.objects.filter(phone=phone, is_verified=False).delete()

        # Generate a 6-digit OTP
        otp_code = str(random.randint(100000, 999999))

        # Link to user if authenticated
        user = request.user if request.user and request.user.is_authenticated else None

        otp = PhoneOTP.objects.create(
            phone=phone,
            otp_code=otp_code,
            user=user,
            expires_at=timezone.now() + timedelta(minutes=OTP_EXPIRY_MINUTES),
        )

        # Send SMS (mock for now)
        _send_sms(phone, otp_code)

        return Response(
            {
                'detail': 'OTP sent successfully.',
                'phone': phone,
                'expires_in_seconds': OTP_EXPIRY_MINUTES * 60,
            },
            status=status.HTTP_200_OK,
        )


class VerifyOTPView(APIView):
    """POST /otp/verify/ -- verify OTP for a phone number.
    Accepts the mock code "1234" in test mode."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data['phone']
        otp_input = serializer.validated_data['otp']

        # ── Mock OTP: accept "1234" always for testing ──
        mock_enabled = getattr(settings, 'MOCK_OTP', True)
        if mock_enabled and otp_input == MOCK_OTP_CODE:
            # Mark user as verified if we can find them by phone
            users = User.objects.filter(phone=phone, is_verified=False)
            users.update(is_verified=True)
            # Clean up any pending OTPs
            PhoneOTP.objects.filter(phone=phone, is_verified=False).update(is_verified=True)
            return Response(
                {'detail': 'Phone verified successfully.', 'verified': True},
                status=status.HTTP_200_OK,
            )

        # ── Real OTP verification ──
        try:
            otp = PhoneOTP.objects.get(
                phone=phone, is_verified=False
            )
        except PhoneOTP.DoesNotExist:
            return Response(
                {'detail': 'No OTP found for this number. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check expiry
        if otp.is_expired:
            otp.delete()
            return Response(
                {'detail': 'OTP has expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check max attempts
        if otp.attempts >= OTP_MAX_ATTEMPTS:
            otp.delete()
            return Response(
                {'detail': 'Too many attempts. Please request a new OTP.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Verify
        if otp.otp_code != otp_input:
            otp.attempts += 1
            otp.save(update_fields=['attempts'])
            remaining = OTP_MAX_ATTEMPTS - otp.attempts
            return Response(
                {
                    'detail': 'Invalid OTP.',
                    'verified': False,
                    'attempts_remaining': remaining,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Success — mark OTP and user as verified
        otp.is_verified = True
        otp.save(update_fields=['is_verified'])

        User.objects.filter(phone=phone, is_verified=False).update(is_verified=True)

        return Response(
            {'detail': 'Phone verified successfully.', 'verified': True},
            status=status.HTTP_200_OK,
        )


class ResendOTPView(APIView):
    """POST /otp/resend/ -- resend OTP (same as send, but clearer intent)."""

    permission_classes = [AllowAny]

    def post(self, request):
        # Delegate to SendOTPView logic
        return SendOTPView.as_view()(request._request)
