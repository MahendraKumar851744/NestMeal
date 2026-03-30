from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from .models import DeliveryZone, DeliverySlot
from .serializers import (
    DeliveryZoneSerializer, DeliverySlotSerializer, DeliveryFeeCalculationSerializer,
)


class DeliveryZoneViewSet(viewsets.ModelViewSet):
    serializer_class = DeliveryZoneSerializer
    permission_classes = [IsAuthenticated, IsCook]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return DeliveryZone.objects.all()
        return DeliveryZone.objects.filter(cook=user.cook_profile)

    def perform_create(self, serializer):
        serializer.save(cook=self.request.user.cook_profile)


class DeliverySlotViewSet(viewsets.ModelViewSet):
    serializer_class = DeliverySlotSerializer

    def get_queryset(self):
        from django.utils import timezone

        queryset = DeliverySlot.objects.select_related('cook')
        today = timezone.now().date()

        user = self.request.user
        if user.is_authenticated and user.role == 'cook':
            queryset = queryset.filter(cook=user.cook_profile)
        elif self.action == 'list':
            # Only show future, available, open slots to customers
            queryset = queryset.filter(
                is_available=True, status='open', date__gte=today,
            )

        # Filter by cook
        cook_id = self.request.query_params.get('cook_id')
        if cook_id:
            queryset = queryset.filter(cook_id=cook_id)

        # Filter by date
        date = self.request.query_params.get('date')
        if date:
            queryset = queryset.filter(date=date)

        return queryset

    def get_permissions(self):
        if self.action == 'list':
            return [AllowAny()]
        return [IsAuthenticated(), IsCook()]

    def perform_create(self, serializer):
        serializer.save(cook=self.request.user.cook_profile)


class CalculateDeliveryFeeView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = DeliveryFeeCalculationSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        cook = serializer.context['cook']
        customer_lat = serializer.validated_data['customer_lat']
        customer_lng = serializer.validated_data['customer_lng']

        if not cook.kitchen_latitude or not cook.kitchen_longitude:
            return Response(
                {'detail': 'Cook kitchen location is not set.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        distance_km = DeliveryFeeCalculationSerializer.haversine_distance(
            cook.kitchen_latitude, cook.kitchen_longitude,
            customer_lat, customer_lng,
        )
        distance_km = round(distance_km, 2)

        # Check if within delivery radius
        if distance_km > float(cook.delivery_radius_km):
            return Response({
                'available': False,
                'distance_km': distance_km,
                'message': 'Delivery is not available for this distance.',
                'max_radius_km': float(cook.delivery_radius_km),
            })

        # Check delivery zones for fee calculation
        zones = DeliveryZone.objects.filter(cook=cook, is_active=True)
        delivery_fee = float(cook.delivery_fee_value)
        estimated_mins = 45  # default

        for zone in zones:
            if zone.zone_type == 'radius' and zone.radius_km and distance_km <= float(zone.radius_km):
                if zone.delivery_fee_type == 'flat':
                    delivery_fee = float(zone.delivery_fee_value)
                elif zone.delivery_fee_type == 'per_km':
                    delivery_fee = round(float(zone.delivery_fee_value) * distance_km, 2)
                elif zone.delivery_fee_type == 'free':
                    delivery_fee = 0.0
                estimated_mins = zone.estimated_delivery_mins
                break
        else:
            # Use cook's default fee settings if no zone matched
            if cook.delivery_fee_type == 'per_km':
                delivery_fee = round(float(cook.delivery_fee_value) * distance_km, 2)
            elif cook.delivery_fee_type == 'free':
                delivery_fee = 0.0

        return Response({
            'available': True,
            'distance_km': distance_km,
            'delivery_fee': delivery_fee,
            'estimated_delivery_mins': estimated_mins,
            'min_order_value': float(cook.delivery_min_order),
        })
