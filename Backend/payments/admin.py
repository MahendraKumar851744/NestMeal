from django.contrib import admin
from .models import Payment, CookPayout


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'customer', 'amount', 'method', 'status', 'paid_at', 'created_at']
    list_filter = ['status', 'method', 'gateway']
    search_fields = ['id', 'order__order_number', 'customer__full_name', 'gateway_transaction_id']
    readonly_fields = ['id', 'created_at']


@admin.register(CookPayout)
class CookPayoutAdmin(admin.ModelAdmin):
    list_display = ['id', 'cook', 'period_start', 'period_end', 'net_amount', 'status', 'paid_at']
    list_filter = ['status']
    search_fields = ['cook__display_name', 'bank_reference']
    readonly_fields = ['id', 'created_at']
