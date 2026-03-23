from rest_framework import serializers
from .models import Payment, CookPayout


class PaymentSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'order', 'order_number', 'customer', 'customer_name',
            'amount', 'currency', 'method', 'gateway',
            'gateway_transaction_id', 'gateway_status', 'status',
            'refund_amount', 'refund_reason', 'refund_initiated_at',
            'paid_at', 'created_at',
        ]
        read_only_fields = fields


class PaymentCreateSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()
    method = serializers.ChoiceField(choices=Payment.METHOD_CHOICES)
    gateway = serializers.CharField(max_length=50, default='razorpay')

    def validate_order_id(self, value):
        from orders.models import Order
        try:
            order = Order.objects.get(id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order not found.")
        if order.customer != self.context['request'].user:
            raise serializers.ValidationError("You can only pay for your own orders.")
        if order.payment_status == 'paid':
            raise serializers.ValidationError("This order has already been paid.")
        if hasattr(order, 'payment') and order.payment.status == 'success':
            raise serializers.ValidationError("A successful payment already exists for this order.")
        self.context['order'] = order
        return value


class CookPayoutSerializer(serializers.ModelSerializer):
    cook_name = serializers.CharField(source='cook.display_name', read_only=True)

    class Meta:
        model = CookPayout
        fields = [
            'id', 'cook', 'cook_name', 'period_start', 'period_end',
            'gross_amount', 'delivery_fees_collected', 'commission_deducted',
            'net_amount', 'status', 'bank_reference', 'paid_at', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']
