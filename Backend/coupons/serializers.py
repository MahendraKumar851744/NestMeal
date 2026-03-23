from django.utils import timezone
from rest_framework import serializers
from .models import Coupon, CouponUsage


class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = [
            'id', 'code', 'description', 'discount_type', 'discount_value',
            'applies_to_delivery_fee', 'min_order_value', 'valid_from',
            'valid_until', 'usage_limit_total', 'usage_limit_per_user',
            'used_count', 'applicable_to', 'applicable_fulfillment',
            'applicable_ids', 'is_active', 'created_by', 'created_at',
        ]
        read_only_fields = ['id', 'used_count', 'created_at']


class CouponCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = [
            'code', 'description', 'discount_type', 'discount_value',
            'applies_to_delivery_fee', 'min_order_value', 'valid_from',
            'valid_until', 'usage_limit_total', 'usage_limit_per_user',
            'applicable_to', 'applicable_fulfillment', 'applicable_ids',
            'is_active', 'created_by',
        ]

    def validate_code(self, value):
        if Coupon.objects.filter(code=value.upper()).exists():
            raise serializers.ValidationError("A coupon with this code already exists.")
        return value.upper()

    def validate(self, data):
        if data.get('valid_from') and data.get('valid_until'):
            if data['valid_from'] >= data['valid_until']:
                raise serializers.ValidationError(
                    {"valid_until": "Expiry date must be after start date."}
                )
        return data


class CouponValidateSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=50)
    order_value = serializers.DecimalField(max_digits=10, decimal_places=2)
    fulfillment_type = serializers.ChoiceField(choices=['pickup', 'delivery'])

    def validate(self, data):
        code = data['code'].upper()
        try:
            coupon = Coupon.objects.get(code=code)
        except Coupon.DoesNotExist:
            raise serializers.ValidationError({"code": "Invalid coupon code."})

        now = timezone.now()

        if not coupon.is_active:
            raise serializers.ValidationError({"code": "This coupon is no longer active."})
        if now < coupon.valid_from:
            raise serializers.ValidationError({"code": "This coupon is not yet valid."})
        if now > coupon.valid_until:
            raise serializers.ValidationError({"code": "This coupon has expired."})
        if coupon.used_count >= coupon.usage_limit_total:
            raise serializers.ValidationError({"code": "This coupon has reached its usage limit."})

        # Check fulfillment type
        if coupon.applicable_fulfillment != 'all':
            expected = 'pickup' if coupon.applicable_fulfillment == 'pickup_only' else 'delivery'
            if data['fulfillment_type'] != expected:
                raise serializers.ValidationError(
                    {"code": f"This coupon is only valid for {expected} orders."}
                )

        # Check minimum order value
        if data['order_value'] < coupon.min_order_value:
            raise serializers.ValidationError(
                {"code": f"Minimum order value of {coupon.min_order_value} required."}
            )

        # Check per-user usage
        user = self.context['request'].user
        user_usage_count = CouponUsage.objects.filter(coupon=coupon, user=user).count()
        if user_usage_count >= coupon.usage_limit_per_user:
            raise serializers.ValidationError(
                {"code": "You have already used this coupon the maximum number of times."}
            )

        # Check new_users applicability
        if coupon.applicable_to == 'new_users':
            from orders.models import Order
            if Order.objects.filter(customer=user, status='completed').exists():
                raise serializers.ValidationError(
                    {"code": "This coupon is only valid for new users."}
                )

        # Calculate discount
        if coupon.discount_type == 'percentage':
            discount = round(data['order_value'] * coupon.discount_value / 100, 2)
        else:
            discount = coupon.discount_value

        # Discount cannot exceed order value
        discount = min(discount, data['order_value'])

        data['coupon'] = coupon
        data['discount_amount'] = discount
        return data
