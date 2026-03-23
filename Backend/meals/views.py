from datetime import timedelta

from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.filters import OrderingFilter, SearchFilter
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from django_filters.rest_framework import DjangoFilterBackend

from accounts.permissions import IsAdmin, IsCook, IsCustomer

from .filters import MealFilter
from .models import Meal, MealImage, PickupSlot, RecurringSlotTemplate
from .serializers import (
    MealCreateUpdateSerializer,
    MealDetailSerializer,
    MealImageSerializer,
    MealListSerializer,
    MealSerializer,
    PickupSlotSerializer,
    RecurringSlotTemplateSerializer,
)


# ---------------------------------------------------------------------------
# Meal ViewSet
# ---------------------------------------------------------------------------

class MealViewSet(viewsets.ModelViewSet):
    """
    Public endpoints for browsing meals, cook-only endpoints for managing
    them.

    * ``list``  / ``retrieve`` — public (no auth required)
    * ``create`` / ``update`` / ``partial_update`` / ``destroy`` — cook only
    """

    queryset = (
        Meal.objects
        .select_related('cook')
        .prefetch_related('images')
        .all()
    )
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = MealFilter
    search_fields = [
        'title', 'description', 'tags',
        'cook__display_name',
    ]
    ordering_fields = ['price', 'avg_rating', 'created_at', 'total_orders']
    ordering = ['-created_at']

    # --- permission routing ------------------------------------------------

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [AllowAny()]
        return [IsAuthenticated(), IsCook()]

    # --- serializer routing ------------------------------------------------

    def get_serializer_class(self):
        if self.action == 'list':
            return MealListSerializer
        if self.action == 'retrieve':
            return MealDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return MealCreateUpdateSerializer
        return MealSerializer

    # --- queryset scoping --------------------------------------------------

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user

        # Authenticated cooks see ALL their own meals (including draft/paused)
        if user.is_authenticated and user.role == 'cook':
            try:
                cook_profile = user.cook_profile
                if self.action in ('list', 'retrieve'):
                    # Show the cook's own meals (any status) plus other active meals
                    qs = qs.filter(
                        Q(cook=cook_profile) | Q(status='active')
                    )
                else:
                    # Management endpoints scoped to own meals only
                    qs = qs.filter(cook=cook_profile)
            except Exception:
                if self.action in ('list', 'retrieve'):
                    qs = qs.filter(status='active')
                else:
                    qs = qs.none()
        elif self.action in ('list', 'retrieve'):
            # Public views only show active meals
            qs = qs.filter(status='active')
        return qs

    # --- destroy override: soft-archive ------------------------------------

    def perform_destroy(self, instance):
        # Verify ownership
        if instance.cook_id != self.request.user.cook_profile.id:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('You can only delete your own meals.')
        instance.status = 'archived'
        instance.is_available = False
        instance.save(update_fields=['status', 'is_available', 'updated_at'])


# ---------------------------------------------------------------------------
# MealImage ViewSet (cook only, own meals)
# ---------------------------------------------------------------------------

class MealImageViewSet(viewsets.ModelViewSet):
    serializer_class = MealImageSerializer
    permission_classes = [IsAuthenticated, IsCook]
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        meal_id = self.kwargs.get('meal_pk')
        return (
            MealImage.objects
            .filter(meal_id=meal_id, meal__cook=self.request.user.cook_profile)
        )

    def perform_create(self, serializer):
        meal_id = self.kwargs.get('meal_pk')
        try:
            meal = Meal.objects.get(
                pk=meal_id, cook=self.request.user.cook_profile,
            )
        except Meal.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound('Meal not found or you do not own it.')
        serializer.save(meal=meal)


# ---------------------------------------------------------------------------
# PickupSlot ViewSet
# ---------------------------------------------------------------------------

class PickupSlotViewSet(viewsets.ModelViewSet):
    """
    * ``list`` — public (filter by cook and/or date)
    * ``create`` / ``update`` / ``destroy`` — cook only, own slots
    """

    serializer_class = PickupSlotSerializer
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['cook', 'date', 'status', 'is_available']
    ordering_fields = ['date', 'start_time']
    ordering = ['date', 'start_time']

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [AllowAny()]
        return [IsAuthenticated(), IsCook()]

    def get_queryset(self):
        qs = PickupSlot.objects.select_related('cook').all()
        if self.action not in ('list', 'retrieve'):
            if self.request.user.is_authenticated and self.request.user.role == 'cook':
                try:
                    qs = qs.filter(cook=self.request.user.cook_profile)
                except Exception:
                    qs = qs.none()
        return qs

    def perform_create(self, serializer):
        serializer.save(cook=self.request.user.cook_profile)


# ---------------------------------------------------------------------------
# RecurringSlotTemplate ViewSet (cook only)
# ---------------------------------------------------------------------------

class RecurringSlotTemplateViewSet(viewsets.ModelViewSet):
    serializer_class = RecurringSlotTemplateSerializer
    permission_classes = [IsAuthenticated, IsCook]

    def get_queryset(self):
        try:
            return RecurringSlotTemplate.objects.filter(
                cook=self.request.user.cook_profile,
            )
        except Exception:
            return RecurringSlotTemplate.objects.none()

    def perform_create(self, serializer):
        serializer.save(cook=self.request.user.cook_profile)


# ---------------------------------------------------------------------------
# Featured Meals (public)
# ---------------------------------------------------------------------------

class FeaturedMealsView(generics.ListAPIView):
    """Return featured, active meals."""
    serializer_class = MealListSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return (
            Meal.objects
            .select_related('cook')
            .prefetch_related('images')
            .filter(is_featured=True, status='active', is_available=True)
            .order_by('-created_at')
        )


# ---------------------------------------------------------------------------
# Available Now (public)
# ---------------------------------------------------------------------------

class AvailableNowView(generics.ListAPIView):
    """
    Meals whose cook has at least one open pickup or delivery slot within
    the next 2 hours.
    """
    serializer_class = MealListSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        now = timezone.now()
        two_hours = now + timedelta(hours=2)
        today = now.date()
        current_time = now.time()
        end_time = two_hours.time()

        # Cooks with an open pickup slot in the next 2 hours
        cooks_with_slots = PickupSlot.objects.filter(
            date=today,
            start_time__lte=end_time,
            end_time__gte=current_time,
            is_available=True,
            status='open',
        ).values_list('cook_id', flat=True)

        return (
            Meal.objects
            .select_related('cook')
            .prefetch_related('images')
            .filter(
                status='active',
                is_available=True,
                cook_id__in=cooks_with_slots,
            )
            .order_by('-avg_rating')
        )
