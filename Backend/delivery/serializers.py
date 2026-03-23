import math
from rest_framework import serializers
from .models import DeliveryZone, DeliverySlot


class DeliveryZoneSerializer(serializers.ModelSerializer):
    cook_name = serializers.CharField(source='cook.display_name', read_only=True)

    class Meta:
        model = DeliveryZone
        fields = [
            'id', 'cook', 'cook_name', 'zone_type', 'radius_km',
            'polygon_coords', 'delivery_fee_type', 'delivery_fee_value',
            'min_order_value', 'estimated_delivery_mins', 'is_active', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class DeliverySlotSerializer(serializers.ModelSerializer):
    cook_name = serializers.CharField(source='cook.display_name', read_only=True)

    class Meta:
        model = DeliverySlot
        fields = [
            'id', 'cook', 'cook_name', 'date', 'start_time', 'end_time',
            'max_orders', 'booked_orders', 'is_available', 'status', 'created_at',
        ]
        read_only_fields = ['id', 'booked_orders', 'status', 'created_at']


class DeliveryFeeCalculationSerializer(serializers.Serializer):
    cook_id = serializers.UUIDField()
    customer_lat = serializers.DecimalField(max_digits=10, decimal_places=7)
    customer_lng = serializers.DecimalField(max_digits=10, decimal_places=7)

    def validate_cook_id(self, value):
        from accounts.models import CookProfile
        try:
            cook = CookProfile.objects.get(id=value)
        except CookProfile.DoesNotExist:
            raise serializers.ValidationError("Cook not found.")
        if not cook.delivery_enabled:
            raise serializers.ValidationError("This cook does not offer delivery.")
        self.context['cook'] = cook
        return value

    @staticmethod
    def haversine_distance(lat1, lng1, lat2, lng2):
        """Calculate distance between two coordinates in km."""
        R = 6371  # Earth's radius in km
        lat1, lng1, lat2, lng2 = map(math.radians, [float(lat1), float(lng1), float(lat2), float(lng2)])
        dlat = lat2 - lat1
        dlng = lng2 - lng1
        a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng / 2) ** 2
        c = 2 * math.asin(math.sqrt(a))
        return R * c
