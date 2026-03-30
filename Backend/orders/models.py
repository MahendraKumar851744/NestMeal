import uuid
import random
import string
from django.db import models
from accounts.models import User, CookProfile
from meals.models import Meal, PickupSlot
from delivery.models import DeliverySlot


class Order(models.Model):
    FULFILLMENT_CHOICES = [
        ('pickup', 'Pickup'),
        ('delivery', 'Delivery'),
    ]
    STATUS_CHOICES = [
        ('placed', 'Placed'),
        ('accepted', 'Accepted'),
        ('preparing', 'Preparing'),
        ('ready_for_pickup', 'Ready for Pickup'),
        ('picked_up', 'Picked Up'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('completed', 'Completed'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
    ]
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('refunded', 'Refunded'),
        ('partially_refunded', 'Partially Refunded'),
        ('failed', 'Failed'),
    ]
    DELIVERY_STATUS_CHOICES = [
        ('placed', 'Placed'),
        ('accepted', 'Accepted'),
        ('preparing', 'Preparing'),
        ('ready_for_pickup', 'Ready for Pickup'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('completed', 'Completed'),
        ('failed_delivery', 'Failed Delivery'),
    ]
    CANCELLED_BY_CHOICES = [
        ('customer', 'Customer'),
        ('cook', 'Cook'),
        ('system', 'System'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=30, unique=True, editable=False)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='orders')
    fulfillment_type = models.CharField(max_length=10, choices=FULFILLMENT_CHOICES)

    # Pickup fields
    pickup_slot = models.ForeignKey(PickupSlot, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    pickup_code = models.CharField(max_length=6, blank=True)
    pickup_time_actual = models.DateTimeField(null=True, blank=True)

    # Delivery fields
    delivery_slot = models.ForeignKey(DeliverySlot, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    delivery_address_street = models.CharField(max_length=255, blank=True)
    delivery_address_city = models.CharField(max_length=100, blank=True)
    delivery_address_state = models.CharField(max_length=100, blank=True)
    delivery_address_zip = models.CharField(max_length=20, blank=True)
    delivery_address_lat = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    delivery_address_lng = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    delivery_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_distance_km = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    delivery_status = models.CharField(max_length=20, choices=DELIVERY_STATUS_CHOICES, null=True, blank=True)
    rider_name = models.CharField(max_length=255, blank=True)
    rider_phone = models.CharField(max_length=20, blank=True)
    estimated_delivery_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    # Pricing
    item_total = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    platform_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    tax_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    discount_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    coupon_code = models.CharField(max_length=50, blank=True)
    special_instructions = models.TextField(max_length=300, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='placed')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')

    acceptance_deadline = models.DateTimeField(null=True, blank=True, help_text='Cook must accept before this time')

    cancellation_reason = models.TextField(blank=True)
    cancelled_by = models.CharField(max_length=10, choices=CANCELLED_BY_CHOICES, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'orders'
        ordering = ['-created_at']

    def __str__(self):
        return self.order_number

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = self._generate_short_order_number()
        if self.fulfillment_type == 'pickup' and not self.pickup_code:
            self.pickup_code = ''.join(random.choices(string.digits, k=6))
        # Set acceptance deadline for new orders (2 minutes)
        if self.status == 'placed' and not self.acceptance_deadline:
            from django.utils import timezone
            from datetime import timedelta
            self.acceptance_deadline = timezone.now() + timedelta(minutes=2)
        super().save(*args, **kwargs)

    @staticmethod
    def _generate_short_order_number():
        """Generate a short order number like HB-A1B2 for easy verification."""
        chars = string.ascii_uppercase + string.digits
        for _ in range(20):
            code = ''.join(random.choices(chars, k=4))
            candidate = f"HB-{code}"
            if not Order.objects.filter(order_number=candidate).exists():
                return candidate
        # Fallback: 6-char code if 4-char space is crowded
        code = ''.join(random.choices(chars, k=6))
        return f"HB-{code}"


class OrderItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    meal = models.ForeignKey(Meal, on_delete=models.SET_NULL, null=True)
    meal_title = models.CharField(max_length=100)
    quantity = models.IntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = 'order_items'

    def __str__(self):
        return f"{self.meal_title} x{self.quantity}"

    def save(self, *args, **kwargs):
        self.line_total = self.quantity * self.unit_price
        super().save(*args, **kwargs)
