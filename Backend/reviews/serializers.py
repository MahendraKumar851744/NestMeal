from django.utils import timezone
from datetime import timedelta
from rest_framework import serializers
from .models import Review, ReviewImage


class ReviewImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewImage
        fields = ['id', 'review', 'image_url', 'created_at']
        read_only_fields = ['id', 'created_at']


class ReviewSerializer(serializers.ModelSerializer):
    images = ReviewImageSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    cook_name = serializers.CharField(source='cook.display_name', read_only=True)
    meal_title = serializers.CharField(source='meal.title', read_only=True, default=None)

    class Meta:
        model = Review
        fields = [
            'id', 'order', 'customer', 'customer_name', 'cook', 'cook_name',
            'meal', 'meal_title', 'rating', 'delivery_rating', 'comment',
            'cook_reply', 'cook_replied_at', 'is_visible', 'is_flagged',
            'images', 'created_at', 'updated_at',
        ]
        read_only_fields = fields


class ReviewCreateSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()
    rating = serializers.IntegerField(min_value=1, max_value=5)
    delivery_rating = serializers.IntegerField(min_value=1, max_value=5, required=False, allow_null=True)
    comment = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')

    def validate_order_id(self, value):
        from orders.models import Order
        try:
            order = Order.objects.select_related('cook').get(id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order not found.")

        user = self.context['request'].user
        if order.customer != user:
            raise serializers.ValidationError("You can only review your own orders.")
        if order.status != 'completed':
            raise serializers.ValidationError("You can only review completed orders.")

        # Check 7-day review window
        if order.updated_at and timezone.now() > order.updated_at + timedelta(days=7):
            raise serializers.ValidationError("Review window has expired (7 days after completion).")

        # Check for existing review
        if Review.objects.filter(order=order).exists():
            raise serializers.ValidationError("A review already exists for this order.")

        self.context['order'] = order
        return value


class ReviewUpdateSerializer(serializers.Serializer):
    rating = serializers.IntegerField(min_value=1, max_value=5, required=False)
    comment = serializers.CharField(max_length=500, required=False, allow_blank=True)

    def validate(self, data):
        review = self.context.get('review')
        if review and timezone.now() > review.created_at + timedelta(hours=48):
            raise serializers.ValidationError("You can only edit a review within 48 hours of creation.")
        return data


class CookReplySerializer(serializers.Serializer):
    cook_reply = serializers.CharField(max_length=300)
