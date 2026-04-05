import re

from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import (
    User,
    CustomerProfile,
    CookProfile,
    Address,
    AdminProfile,
    Follow,
    PhoneOTP,
)


# ---------------------------------------------------------------------------
# Nested / supporting serializers
# ---------------------------------------------------------------------------


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = [
            'id', 'user', 'label', 'street', 'city', 'state', 'zip_code',
            'latitude', 'longitude', 'is_default', 'created_at',
        ]
        read_only_fields = ['id', 'user', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        # If this address is marked as default, unset any existing default.
        if validated_data.get('is_default'):
            Address.objects.filter(
                user=validated_data['user'], is_default=True
            ).update(is_default=False)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        if validated_data.get('is_default'):
            Address.objects.filter(
                user=instance.user, is_default=True
            ).exclude(pk=instance.pk).update(is_default=False)
        return super().update(instance, validated_data)


# ---------------------------------------------------------------------------
# Profile serializers
# ---------------------------------------------------------------------------

class CustomerProfileSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)

    class Meta:
        model = CustomerProfile
        fields = [
            'id', 'user', 'user_email', 'full_name',
            'wallet_balance', 'preferred_fulfillment', 'status',
        ]
        read_only_fields = ['id', 'user', 'wallet_balance']


class CookProfileSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    followers_count = serializers.IntegerField(read_only=True, default=0)
    is_followed = serializers.BooleanField(read_only=True, default=False)
    profile_image_url = serializers.SerializerMethodField()

    def get_profile_image_url(self, obj):
        request = self.context.get('request')
        if obj.profile_image and request:
            return request.build_absolute_uri(obj.profile_image.url)
        elif obj.profile_image:
            return obj.profile_image.url
        return None

    class Meta:
        model = CookProfile
        fields = [
            'id', 'user', 'user_email', 'full_name',
            'display_name', 'bio', 'is_available',
            'profile_image_url',
            'kitchen_street', 'kitchen_city', 'kitchen_state', 'kitchen_zip',
            'kitchen_latitude', 'kitchen_longitude',
            'pickup_instructions',
            'delivery_enabled', 'delivery_radius_km',
            'delivery_fee_type', 'delivery_fee_value', 'delivery_min_order',
            'food_safety_certificate_url', 'government_id',
            'bank_account_number', 'bank_ifsc', 'bank_account_holder',
            'commission_rate', 'avg_rating', 'total_reviews',
            'followers_count', 'is_followed',
            'is_active', 'status', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'profile_image_url', 'commission_rate',
            'avg_rating', 'total_reviews', 'followers_count', 'is_followed',
            'created_at', 'updated_at',
        ]


class AdminProfileSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)

    class Meta:
        model = AdminProfile
        fields = [
            'id', 'user', 'user_email', 'full_name',
            'admin_role', 'permissions', 'status',
        ]
        read_only_fields = ['id', 'user']


# ---------------------------------------------------------------------------
# User serializer (read-only representation)
# ---------------------------------------------------------------------------

class UserSerializer(serializers.ModelSerializer):
    customer_profile = CustomerProfileSerializer(read_only=True)
    cook_profile = CookProfileSerializer(read_only=True)
    admin_profile = AdminProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'full_name', 'phone', 'role',
            'profile_picture_url', 'is_verified', 'is_active',
            'created_at', 'updated_at',
            'customer_profile', 'cook_profile', 'admin_profile',
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True)

    # Optional cook-specific fields sent at registration time
    display_name = serializers.CharField(
        max_length=255, required=False, write_only=True
    )
    kitchen_street = serializers.CharField(
        max_length=255, required=False, write_only=True
    )
    kitchen_city = serializers.CharField(
        max_length=100, required=False, write_only=True
    )
    kitchen_state = serializers.CharField(
        max_length=100, required=False, write_only=True
    )
    kitchen_zip = serializers.CharField(
        max_length=20, required=False, write_only=True
    )

    class Meta:
        model = User
        fields = [
            'email', 'full_name', 'phone', 'role', 'password',
            'password_confirm', 'profile_picture_url',
            # cook extras
            'display_name', 'kitchen_street', 'kitchen_city',
            'kitchen_state', 'kitchen_zip',
        ]

    @staticmethod
    def _strip_html(value):
        """Remove HTML/script tags from a string to prevent stored XSS."""
        return re.sub(r'<[^>]+>', '', value).strip()

    def validate_full_name(self, value):
        sanitized = self._strip_html(value)
        if not sanitized:
            raise serializers.ValidationError('Full name is required.')
        return sanitized

    def validate_display_name(self, value):
        if value:
            return self._strip_html(value)
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password_confirm'):
            raise serializers.ValidationError(
                {'password_confirm': 'Passwords do not match.'}
            )
        role = attrs.get('role')
        if role == 'cook':
            for field in [
                'display_name', 'kitchen_street', 'kitchen_city',
                'kitchen_state', 'kitchen_zip',
            ]:
                if not attrs.get(field):
                    raise serializers.ValidationError(
                        {field: f'{field} is required for cook registration.'}
                    )
        return attrs

    def create(self, validated_data):
        # Pop cook-specific fields before creating the user
        cook_fields = {}
        for field in [
            'display_name', 'kitchen_street', 'kitchen_city',
            'kitchen_state', 'kitchen_zip',
        ]:
            value = validated_data.pop(field, None)
            if value is not None:
                cook_fields[field] = value

        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)

        # Automatically create the matching profile
        if user.role == 'customer':
            CustomerProfile.objects.create(user=user)
        elif user.role == 'cook':
            CookProfile.objects.create(user=user, **cook_fields)
        elif user.role == 'admin':
            AdminProfile.objects.create(user=user)

        return user


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(
            request=self.context.get('request'),
            email=attrs['email'],
            password=attrs['password'],
        )
        if not user:
            raise serializers.ValidationError('Invalid email or password.')
        if not user.is_active:
            raise serializers.ValidationError('Account is deactivated.')
        attrs['user'] = user
        return attrs


# ---------------------------------------------------------------------------
# Change password
# ---------------------------------------------------------------------------

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(
        write_only=True, validators=[validate_password]
    )
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError(
                {'new_password_confirm': 'New passwords do not match.'}
            )
        return attrs

    def save(self, **kwargs):
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save(update_fields=['password'])
        return user


# ---------------------------------------------------------------------------
# OTP
# ---------------------------------------------------------------------------

class SendOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Phone number is required.')
        return value


class VerifyOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    otp = serializers.CharField(max_length=6)
