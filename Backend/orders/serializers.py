from decimal import Decimal
from django.conf import settings
from django.utils import timezone
from rest_framework import serializers

from accounts.models import CookProfile
from coupons.models import Coupon, CouponUsage
from delivery.models import DeliverySlot
from meals.models import Meal, PickupSlot
from orders.models import Order, OrderItem


# ---------------------------------------------------------------------------
# Read serializers
# ---------------------------------------------------------------------------

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = [
            'id', 'meal', 'meal_title', 'quantity',
            'unit_price', 'line_total',
        ]
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    cook_display_name = serializers.CharField(source='cook.display_name', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'customer', 'customer_name',
            'cook', 'cook_display_name', 'fulfillment_type',
            # Pickup
            'pickup_slot', 'pickup_code', 'pickup_time_actual',
            # Delivery
            'delivery_slot',
            'delivery_address_street', 'delivery_address_city',
            'delivery_address_state', 'delivery_address_zip',
            'delivery_address_lat', 'delivery_address_lng',
            'delivery_fee', 'delivery_distance_km',
            'delivery_status', 'rider_name', 'rider_phone',
            'estimated_delivery_at', 'delivered_at',
            # Pricing
            'item_total', 'platform_fee', 'tax_amount',
            'discount_amount', 'total_amount',
            # Misc
            'coupon_code', 'special_instructions',
            'status', 'payment_status',
            'cancellation_reason', 'cancelled_by',
            'created_at', 'updated_at',
            # Nested
            'items',
        ]
        read_only_fields = fields


class OrderListSerializer(serializers.ModelSerializer):
    cook_display_name = serializers.CharField(source='cook.display_name', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'status', 'total_amount',
            'fulfillment_type', 'created_at', 'cook_display_name',
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Create serializers
# ---------------------------------------------------------------------------

class OrderItemCreateSerializer(serializers.Serializer):
    meal_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    cook_id = serializers.UUIDField()
    fulfillment_type = serializers.ChoiceField(choices=['pickup', 'delivery'])
    items = OrderItemCreateSerializer(many=True, allow_empty=False)

    # Slot selection
    pickup_slot_id = serializers.UUIDField(required=False, allow_null=True)
    delivery_slot_id = serializers.UUIDField(required=False, allow_null=True)

    # Delivery address
    delivery_address_street = serializers.CharField(max_length=255, required=False, default='')
    delivery_address_city = serializers.CharField(max_length=100, required=False, default='')
    delivery_address_state = serializers.CharField(max_length=100, required=False, default='')
    delivery_address_zip = serializers.CharField(max_length=20, required=False, default='')
    delivery_address_lat = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True, default=None,
    )
    delivery_address_lng = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True, default=None,
    )

    # Optional
    coupon_code = serializers.CharField(max_length=50, required=False, default='')
    special_instructions = serializers.CharField(max_length=300, required=False, default='')

    # ----- helpers -----

    def _get_cook(self, cook_id):
        try:
            return CookProfile.objects.get(id=cook_id, status='active')
        except CookProfile.DoesNotExist:
            raise serializers.ValidationError({'cook_id': 'Cook not found or not active.'})

    def _get_meals(self, items_data, cook):
        meal_ids = [item['meal_id'] for item in items_data]
        meals = Meal.objects.filter(id__in=meal_ids, cook=cook, status='active', is_available=True)
        meals_map = {str(m.id): m for m in meals}
        for item in items_data:
            if str(item['meal_id']) not in meals_map:
                raise serializers.ValidationError(
                    {'items': f"Meal {item['meal_id']} is not available from this cook."}
                )
        return meals_map

    def _calculate_delivery_fee(self, cook, delivery_distance_km):
        if not cook.delivery_enabled:
            raise serializers.ValidationError(
                {'fulfillment_type': 'This cook does not offer delivery.'}
            )
        fee_type = cook.delivery_fee_type
        if fee_type == 'free':
            return Decimal('0.00'), delivery_distance_km
        if fee_type == 'per_km':
            distance = delivery_distance_km or Decimal('0.00')
            return (cook.delivery_fee_value * distance).quantize(Decimal('0.01')), distance
        # flat
        return cook.delivery_fee_value, delivery_distance_km

    def _validate_coupon(self, code, user, cook, fulfillment_type, item_total):
        if not code:
            return Decimal('0.00')
        now = timezone.now()
        try:
            coupon = Coupon.objects.get(code=code, is_active=True)
        except Coupon.DoesNotExist:
            raise serializers.ValidationError({'coupon_code': 'Invalid or inactive coupon.'})

        if now < coupon.valid_from or now > coupon.valid_until:
            raise serializers.ValidationError({'coupon_code': 'Coupon has expired or is not yet valid.'})
        if coupon.used_count >= coupon.usage_limit_total:
            raise serializers.ValidationError({'coupon_code': 'Coupon usage limit reached.'})
        user_usage = CouponUsage.objects.filter(coupon=coupon, user=user).count()
        if user_usage >= coupon.usage_limit_per_user:
            raise serializers.ValidationError({'coupon_code': 'You have already used this coupon.'})
        if item_total < coupon.min_order_value:
            raise serializers.ValidationError(
                {'coupon_code': f'Minimum order value of {coupon.min_order_value} required.'}
            )
        # Fulfillment check
        if coupon.applicable_fulfillment == 'pickup_only' and fulfillment_type != 'pickup':
            raise serializers.ValidationError({'coupon_code': 'Coupon valid for pickup orders only.'})
        if coupon.applicable_fulfillment == 'delivery_only' and fulfillment_type != 'delivery':
            raise serializers.ValidationError({'coupon_code': 'Coupon valid for delivery orders only.'})

        # Calculate discount
        if coupon.discount_type == 'percentage':
            discount = (item_total * coupon.discount_value / Decimal('100')).quantize(Decimal('0.01'))
        else:
            discount = coupon.discount_value

        return min(discount, item_total)

    # ----- validation -----

    def validate(self, attrs):
        fulfillment = attrs['fulfillment_type']

        if fulfillment == 'pickup':
            if not attrs.get('pickup_slot_id'):
                raise serializers.ValidationError(
                    {'pickup_slot_id': 'Pickup slot is required for pickup orders.'}
                )
        elif fulfillment == 'delivery':
            if not attrs.get('delivery_slot_id'):
                raise serializers.ValidationError(
                    {'delivery_slot_id': 'Delivery slot is required for delivery orders.'}
                )
            if not attrs.get('delivery_address_street'):
                raise serializers.ValidationError(
                    {'delivery_address_street': 'Delivery address is required.'}
                )
        return attrs

    # ----- create -----

    def create(self, validated_data):
        user = self.context['request'].user
        cook = self._get_cook(validated_data['cook_id'])
        items_data = validated_data['items']
        meals_map = self._get_meals(items_data, cook)
        fulfillment = validated_data['fulfillment_type']

        # ---- Build order items and calculate item_total ----
        item_total = Decimal('0.00')
        order_items_to_create = []
        for item in items_data:
            meal = meals_map[str(item['meal_id'])]
            unit_price = meal.effective_price
            line_total = unit_price * item['quantity']
            item_total += line_total
            order_items_to_create.append({
                'meal': meal,
                'meal_title': meal.title,
                'quantity': item['quantity'],
                'unit_price': unit_price,
                'line_total': line_total,
            })

        # ---- Pricing ----
        platform_fee_rate = Decimal(str(getattr(settings, 'PLATFORM_FEE_RATE', '0.03')))
        tax_rate = Decimal(str(getattr(settings, 'TAX_RATE', '0.05')))

        platform_fee = (item_total * platform_fee_rate).quantize(Decimal('0.01'))
        tax_amount = ((item_total + platform_fee) * tax_rate).quantize(Decimal('0.01'))

        # ---- Delivery fee ----
        delivery_fee = Decimal('0.00')
        delivery_distance_km = None
        pickup_slot = None
        delivery_slot = None

        if fulfillment == 'delivery':
            delivery_distance_km = Decimal('0.00')  # would be calculated via geo in production
            delivery_fee, delivery_distance_km = self._calculate_delivery_fee(
                cook, delivery_distance_km,
            )
            # Validate delivery slot
            try:
                delivery_slot = DeliverySlot.objects.get(
                    id=validated_data['delivery_slot_id'],
                    cook=cook,
                    is_available=True,
                    status='open',
                )
            except DeliverySlot.DoesNotExist:
                raise serializers.ValidationError(
                    {'delivery_slot_id': 'Delivery slot not available.'}
                )
        else:
            # Validate pickup slot
            try:
                pickup_slot = PickupSlot.objects.get(
                    id=validated_data['pickup_slot_id'],
                    cook=cook,
                    is_available=True,
                    status='open',
                )
            except PickupSlot.DoesNotExist:
                raise serializers.ValidationError(
                    {'pickup_slot_id': 'Pickup slot not available.'}
                )

        # ---- Coupon ----
        discount_amount = self._validate_coupon(
            validated_data.get('coupon_code', ''),
            user,
            cook,
            fulfillment,
            item_total,
        )

        # ---- Total ----
        total_amount = item_total + platform_fee + tax_amount + delivery_fee - discount_amount
        total_amount = max(total_amount, Decimal('0.00'))

        # ---- Create order ----
        order = Order.objects.create(
            customer=user,
            cook=cook,
            fulfillment_type=fulfillment,
            pickup_slot=pickup_slot,
            delivery_slot=delivery_slot,
            delivery_address_street=validated_data.get('delivery_address_street', ''),
            delivery_address_city=validated_data.get('delivery_address_city', ''),
            delivery_address_state=validated_data.get('delivery_address_state', ''),
            delivery_address_zip=validated_data.get('delivery_address_zip', ''),
            delivery_address_lat=validated_data.get('delivery_address_lat'),
            delivery_address_lng=validated_data.get('delivery_address_lng'),
            delivery_fee=delivery_fee,
            delivery_distance_km=delivery_distance_km,
            item_total=item_total,
            platform_fee=platform_fee,
            tax_amount=tax_amount,
            discount_amount=discount_amount,
            total_amount=total_amount,
            coupon_code=validated_data.get('coupon_code', ''),
            special_instructions=validated_data.get('special_instructions', ''),
        )

        # ---- Create order items ----
        for oi in order_items_to_create:
            OrderItem.objects.create(order=order, **oi)

        # ---- Increment slot booked_orders ----
        if pickup_slot:
            pickup_slot.booked_orders += 1
            pickup_slot.save()
        if delivery_slot:
            delivery_slot.booked_orders += 1
            delivery_slot.save()

        # ---- Record coupon usage ----
        if validated_data.get('coupon_code'):
            coupon = Coupon.objects.get(code=validated_data['coupon_code'])
            CouponUsage.objects.create(coupon=coupon, user=user, order=order)
            coupon.used_count += 1
            coupon.save(update_fields=['used_count'])

        return order


# ---------------------------------------------------------------------------
# Status / cancel serializers
# ---------------------------------------------------------------------------

ALLOWED_STATUS_TRANSITIONS_PICKUP = {
    'placed': ['accepted', 'rejected', 'cancelled'],
    'accepted': ['preparing', 'cancelled'],
    'preparing': ['ready_for_pickup'],
    'ready_for_pickup': ['picked_up'],
    'picked_up': ['completed'],
}

ALLOWED_STATUS_TRANSITIONS_DELIVERY = {
    'placed': ['accepted', 'rejected', 'cancelled'],
    'accepted': ['preparing', 'cancelled'],
    'preparing': ['ready_for_pickup'],
    'ready_for_pickup': ['out_for_delivery'],
    'out_for_delivery': ['delivered'],
    'delivered': ['completed'],
}


class OrderStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[
        'accepted', 'preparing', 'ready_for_pickup',
        'out_for_delivery', 'delivered', 'completed', 'rejected',
        'picked_up',
    ])

    def validate_status(self, value):
        order = self.context.get('order')
        if not order:
            raise serializers.ValidationError('Order context is required.')

        if order.fulfillment_type == 'delivery':
            transitions = ALLOWED_STATUS_TRANSITIONS_DELIVERY
        else:
            transitions = ALLOWED_STATUS_TRANSITIONS_PICKUP

        allowed = transitions.get(order.status, [])
        if value not in allowed:
            raise serializers.ValidationError(
                f"Cannot transition from '{order.status}' to '{value}'. "
                f"Allowed: {allowed}"
            )
        return value


class OrderCancelSerializer(serializers.Serializer):
    cancellation_reason = serializers.CharField(max_length=500)
