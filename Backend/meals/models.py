import uuid
from django.db import models
from accounts.models import CookProfile


class Meal(models.Model):
    CATEGORY_CHOICES = [
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snack', 'Snack'),
        ('dessert', 'Dessert'),
        ('beverage', 'Beverage'),
        ('meal_kit', 'Meal Kit'),
    ]
    MEAL_TYPE_CHOICES = [
        ('veg', 'Vegetarian'),
        ('non_veg', 'Non-Vegetarian'),
        ('egg', 'Egg'),
    ]
    SPICE_CHOICES = [
        ('mild', 'Mild'),
        ('medium', 'Medium'),
        ('spicy', 'Spicy'),
        ('extra_spicy', 'Extra Spicy'),
    ]
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('archived', 'Archived'),
    ]
    CURRENCY_CHOICES = [
        ('AUD', 'AUD'),
        ('INR', 'INR'),
        ('USD', 'USD'),
        ('EUR', 'EUR'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='meals')
    title = models.CharField(max_length=100)
    description = models.TextField(max_length=1000, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='AUD')
    category = models.CharField(max_length=10, choices=CATEGORY_CHOICES)
    cuisine_type = models.CharField(max_length=100, blank=True)
    meal_type = models.CharField(max_length=7, choices=MEAL_TYPE_CHOICES)
    dietary_tags = models.JSONField(default=list, blank=True)
    allergen_info = models.JSONField(default=list, blank=True)
    spice_level = models.CharField(max_length=12, choices=SPICE_CHOICES, default='medium')
    serving_size = models.CharField(max_length=100, blank=True)
    calories_approx = models.IntegerField(null=True, blank=True)
    preparation_time_mins = models.IntegerField(default=30)
    fulfillment_modes = models.JSONField(default=list)  # ['pickup', 'delivery']
    is_available = models.BooleanField(default=True)
    available_days = models.JSONField(default=list)  # ['mon','tue',...]
    order_cutoff_time = models.TimeField(null=True, blank=True, help_text='Orders must be placed before this time (e.g. 08:00 for lunch)')
    total_orders = models.IntegerField(default=0)
    avg_rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    tags = models.JSONField(default=list, blank=True)
    includes = models.JSONField(default=list, blank=True, help_text='List of items included with the meal, e.g. ["onion", "lemon", "raita"]')
    is_featured = models.BooleanField(default=False)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='draft')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'meals'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def effective_price(self):
        if self.discount_percentage > 0:
            return round(self.price * (1 - self.discount_percentage / 100), 2)
        return self.price

    @property
    def is_past_cutoff(self):
        """True if today is an available day and current time is past the cutoff."""
        if not self.order_cutoff_time:
            return False
        from django.utils import timezone
        now = timezone.localtime()
        day_codes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        today_code = day_codes[now.weekday()]
        if today_code in [d.lower() for d in self.available_days]:
            return now.time() > self.order_cutoff_time
        return False


class MealExtra(models.Model):
    """Add-on / extra item that can be added to a meal (e.g. extra rice, drink)."""
    
    # Re-using choices for consistency
    MEAL_TYPE_CHOICES = [
        ('veg', 'Vegetarian'),
        ('non_veg', 'Non-Vegetarian'),
        ('egg', 'Egg'),
    ]
    CURRENCY_CHOICES = [
        ('AUD', 'AUD'),
        ('INR', 'INR'),
        ('USD', 'USD'),
        ('EUR', 'EUR'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    meal = models.ForeignKey(Meal, on_delete=models.CASCADE, related_name='extras')
    
    name = models.CharField(max_length=100)
    item_type = models.CharField(max_length=7, choices=MEAL_TYPE_CHOICES, default='veg') # <-- NEW FIELD
    price = models.DecimalField(max_digits=8, decimal_places=2)
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='AUD') # <-- NEW FIELD
    
    is_available = models.BooleanField(default=True)
    display_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'meal_extras'
        ordering = ['display_order', 'name']

    def __str__(self):
        return f"{self.name} ({self.get_item_type_display()}) (+{self.price} {self.currency}) for {self.meal.title}"

class MealImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    meal = models.ForeignKey(Meal, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='meal_images/')
    display_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'meal_images'
        ordering = ['display_order']

    def __str__(self):
        return f"Image for {self.meal.title}"


class PickupSlot(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('full', 'Full'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='pickup_slots')
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    max_orders = models.IntegerField(default=10)
    booked_orders = models.IntegerField(default=0)
    is_available = models.BooleanField(default=True)
    location_label = models.CharField(max_length=100, blank=True)
    location_street = models.CharField(max_length=255, blank=True)
    location_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    location_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'pickup_slots'
        ordering = ['date', 'start_time']

    def __str__(self):
        return f"{self.cook.display_name} - {self.date} {self.start_time}-{self.end_time}"

    def save(self, *args, **kwargs):
        if self.booked_orders >= self.max_orders:
            self.is_available = False
            self.status = 'full'
        super().save(*args, **kwargs)



class RecurringSlotTemplate(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='slot_templates')
    days_of_week = models.JSONField(default=list)  # ['mon','tue',...]
    start_time = models.TimeField()
    end_time = models.TimeField()
    max_orders = models.IntegerField(default=10)
    effective_from = models.DateField()
    effective_until = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    slot_type = models.CharField(max_length=10, default='pickup', choices=[('pickup', 'Pickup'), ('delivery', 'Delivery')])
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'recurring_slot_templates'

    def __str__(self):
        return f"{self.cook.display_name} template - {self.days_of_week}"
