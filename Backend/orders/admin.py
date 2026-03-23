from django.contrib import admin
from orders.models import Order, OrderItem


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('id', 'meal', 'meal_title', 'quantity', 'unit_price', 'line_total')


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_number', 'customer', 'cook', 'fulfillment_type',
        'status', 'payment_status', 'total_amount', 'created_at',
    )
    list_filter = (
        'status', 'payment_status', 'fulfillment_type',
        'created_at', 'cancelled_by',
    )
    search_fields = (
        'order_number', 'customer__full_name', 'customer__email',
        'cook__display_name', 'coupon_code',
    )
    readonly_fields = (
        'id', 'order_number', 'pickup_code', 'created_at', 'updated_at',
    )
    inlines = [OrderItemInline]
    ordering = ('-created_at',)


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'order', 'meal_title', 'quantity', 'unit_price', 'line_total')
    list_filter = ('order__status',)
    search_fields = ('meal_title', 'order__order_number')
    readonly_fields = ('id',)
