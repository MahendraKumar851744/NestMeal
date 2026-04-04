import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'admin')
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [
        ('customer', 'Customer'),
        ('cook', 'Cook'),
        ('admin', 'Admin'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    profile_picture_url = models.URLField(blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name', 'phone', 'role']

    class Meta:
        db_table = 'users'

    def __str__(self):
        return f"{self.full_name} ({self.role})"


class CustomerProfile(models.Model):
    FULFILLMENT_CHOICES = [
        ('pickup', 'Pickup'),
        ('delivery', 'Delivery'),
        ('no_preference', 'No Preference'),
    ]
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('suspended', 'Suspended'),
        ('deleted', 'Deleted'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='customer_profile')
    wallet_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    preferred_fulfillment = models.CharField(max_length=15, choices=FULFILLMENT_CHOICES, default='no_preference')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')

    class Meta:
        db_table = 'customer_profiles'

    def __str__(self):
        return f"Customer: {self.user.full_name}"


class Address(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    label = models.CharField(max_length=50, default='Home')
    street = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    zip_code = models.CharField(max_length=20)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'addresses'

    def __str__(self):
        return f"{self.label}: {self.street}, {self.city}"


class CookProfile(models.Model):
    STATUS_CHOICES = [
        ('pending_verification', 'Pending Verification'),
        ('active', 'Active'),
        ('suspended', 'Suspended'),
        ('deactivated', 'Deactivated'),
    ]
    DELIVERY_FEE_CHOICES = [
        ('flat', 'Flat'),
        ('per_km', 'Per KM'),
        ('free', 'Free'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='cook_profile')
    display_name = models.CharField(max_length=255)
    bio = models.TextField(max_length=500, blank=True)
    
    is_available = models.BooleanField(
        default=True, 
        help_text="Allows the cook to manually toggle their visibility to customers."
    )
    
    kitchen_street = models.CharField(max_length=255)
    kitchen_city = models.CharField(max_length=100)
    kitchen_state = models.CharField(max_length=100)
    kitchen_zip = models.CharField(max_length=20)
    kitchen_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    kitchen_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)

    pickup_instructions = models.TextField(blank=True)

    delivery_enabled = models.BooleanField(default=False)
    delivery_radius_km = models.DecimalField(max_digits=5, decimal_places=2, default=5.00)
    delivery_fee_type = models.CharField(max_length=10, choices=DELIVERY_FEE_CHOICES, null=True, blank=True)
    delivery_fee_value = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_min_order = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)

    food_safety_certificate_url = models.URLField(blank=True, null=True)
    government_id = models.CharField(max_length=100, blank=True)

    bank_account_number = models.CharField(max_length=50, blank=True)
    bank_ifsc = models.CharField(max_length=20, blank=True)
    bank_account_holder = models.CharField(max_length=255, blank=True)

    commission_rate = models.DecimalField(max_digits=4, decimal_places=2, default=0.10)
    avg_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    total_reviews = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    status = models.CharField(max_length=25, choices=STATUS_CHOICES, default='pending_verification')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cook_profiles'

    def __str__(self):
        return self.display_name



class Follow(models.Model):
    """A customer follows a cook."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='followers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'follows'
        unique_together = ('customer', 'cook')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.full_name} follows {self.cook.display_name}"


class PhoneOTP(models.Model):
    """Stores OTP codes for phone number verification."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=20)
    otp_code = models.CharField(max_length=6)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otps', null=True, blank=True)
    is_verified = models.BooleanField(default=False)
    attempts = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        db_table = 'phone_otps'
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.phone} ({'verified' if self.is_verified else 'pending'})"

    @property
    def is_expired(self):
        from django.utils import timezone
        return timezone.now() > self.expires_at


class AdminProfile(models.Model):
    ROLE_CHOICES = [
        ('super_admin', 'Super Admin'),
        ('support_agent', 'Support Agent'),
        ('finance_admin', 'Finance Admin'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='admin_profile')
    admin_role = models.CharField(max_length=15, choices=ROLE_CHOICES, default='support_agent')
    permissions = models.JSONField(default=list)
    status = models.CharField(max_length=10, default='active')

    class Meta:
        db_table = 'admin_profiles'

    def __str__(self):
        return f"Admin: {self.user.full_name} ({self.admin_role})"
