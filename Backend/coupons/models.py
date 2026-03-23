import uuid
from django.db import models


class Coupon(models.Model):
    DISCOUNT_TYPE_CHOICES = [
        ('percentage', 'Percentage'),
        ('flat_amount', 'Flat Amount'),
    ]
    APPLICABLE_TO_CHOICES = [
        ('all', 'All'),
        ('specific_cooks', 'Specific Cooks'),
        ('specific_meals', 'Specific Meals'),
        ('new_users', 'New Users'),
    ]
    FULFILLMENT_CHOICES = [
        ('all', 'All'),
        ('pickup_only', 'Pickup Only'),
        ('delivery_only', 'Delivery Only'),
    ]
    CREATED_BY_CHOICES = [
        ('admin', 'Admin'),
        ('cook', 'Cook'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=50, unique=True)
    description = models.CharField(max_length=255)
    discount_type = models.CharField(max_length=15, choices=DISCOUNT_TYPE_CHOICES)
    discount_value = models.DecimalField(max_digits=8, decimal_places=2)
    applies_to_delivery_fee = models.BooleanField(default=False)
    min_order_value = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    usage_limit_total = models.IntegerField(default=100)
    usage_limit_per_user = models.IntegerField(default=1)
    used_count = models.IntegerField(default=0)
    applicable_to = models.CharField(max_length=20, choices=APPLICABLE_TO_CHOICES, default='all')
    applicable_fulfillment = models.CharField(max_length=15, choices=FULFILLMENT_CHOICES, default='all')
    applicable_ids = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True)
    created_by = models.CharField(max_length=10, choices=CREATED_BY_CHOICES, default='admin')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'coupons'

    def __str__(self):
        return self.code


class CouponUsage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coupon = models.ForeignKey(Coupon, on_delete=models.CASCADE, related_name='usages')
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='coupon_usages')
    order = models.ForeignKey('orders.Order', on_delete=models.CASCADE, related_name='coupon_usage')
    used_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'coupon_usages'

    def __str__(self):
        return f"{self.coupon.code} used by {self.user.full_name}"
