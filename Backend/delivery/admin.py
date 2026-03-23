from django.contrib import admin
from .models import DeliveryZone, DeliverySlot


@admin.register(DeliveryZone)
class DeliveryZoneAdmin(admin.ModelAdmin):
    list_display = ['id', 'cook', 'zone_type', 'radius_km', 'delivery_fee_type', 'delivery_fee_value', 'is_active']
    list_filter = ['zone_type', 'delivery_fee_type', 'is_active']
    search_fields = ['cook__display_name']
    readonly_fields = ['id', 'created_at']


@admin.register(DeliverySlot)
class DeliverySlotAdmin(admin.ModelAdmin):
    list_display = ['id', 'cook', 'date', 'start_time', 'end_time', 'max_orders', 'booked_orders', 'status']
    list_filter = ['status', 'is_available', 'date']
    search_fields = ['cook__display_name']
    readonly_fields = ['id', 'created_at']
