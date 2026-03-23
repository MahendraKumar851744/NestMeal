import uuid
from django.db import models
from accounts.models import CookProfile


class DeliveryZone(models.Model):
    ZONE_TYPE_CHOICES = [
        ('radius', 'Radius'),
        ('polygon', 'Polygon'),
    ]
    FEE_TYPE_CHOICES = [
        ('flat', 'Flat'),
        ('per_km', 'Per KM'),
        ('free', 'Free'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='delivery_zones')
    zone_type = models.CharField(max_length=10, choices=ZONE_TYPE_CHOICES, default='radius')
    radius_km = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    polygon_coords = models.JSONField(default=list, blank=True)
    delivery_fee_type = models.CharField(max_length=10, choices=FEE_TYPE_CHOICES, default='flat')
    delivery_fee_value = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    min_order_value = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    estimated_delivery_mins = models.IntegerField(default=45)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'delivery_zones'

    def __str__(self):
        return f"{self.cook.display_name} - {self.zone_type} zone"


class DeliverySlot(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('full', 'Full'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='delivery_slots')
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    max_orders = models.IntegerField(default=5)
    booked_orders = models.IntegerField(default=0)
    is_available = models.BooleanField(default=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'delivery_slots'
        ordering = ['date', 'start_time']

    def __str__(self):
        return f"{self.cook.display_name} delivery - {self.date} {self.start_time}-{self.end_time}"

    def save(self, *args, **kwargs):
        if self.booked_orders >= self.max_orders:
            self.is_available = False
            self.status = 'full'
        super().save(*args, **kwargs)
