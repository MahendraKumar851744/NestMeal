from django.contrib import admin
from .models import Coupon, CouponUsage


@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = [
        'code', 'description', 'discount_type', 'discount_value',
        'is_active', 'used_count', 'usage_limit_total', 'valid_from', 'valid_until',
    ]
    list_filter = ['is_active', 'discount_type', 'applicable_to', 'created_by']
    search_fields = ['code', 'description']
    readonly_fields = ['id', 'used_count', 'created_at']


@admin.register(CouponUsage)
class CouponUsageAdmin(admin.ModelAdmin):
    list_display = ['id', 'coupon', 'user', 'order', 'used_at']
    list_filter = ['used_at']
    search_fields = ['coupon__code', 'user__full_name']
    readonly_fields = ['id', 'used_at']
