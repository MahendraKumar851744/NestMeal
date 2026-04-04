from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import (
    User,
    CustomerProfile,
    CookProfile,
    Address,
    AdminProfile,
    Follow,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'full_name', 'role', 'is_verified', 'is_active', 'created_at']
    list_filter = ['role', 'is_verified', 'is_active', 'is_staff']
    search_fields = ['email', 'full_name', 'phone']
    ordering = ['-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']

    fieldsets = (
        (None, {'fields': ('id', 'email', 'password')}),
        ('Personal info', {'fields': ('full_name', 'phone', 'profile_picture_url')}),
        ('Role & status', {'fields': ('role', 'is_verified', 'is_active', 'is_staff', 'is_superuser')}),
        ('Permissions', {'fields': ('groups', 'user_permissions')}),
        ('Dates', {'fields': ('created_at', 'updated_at')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'full_name', 'phone', 'role', 'password1', 'password2'),
        }),
    )


@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'wallet_balance', 'preferred_fulfillment', 'status']
    list_filter = ['status', 'preferred_fulfillment']
    search_fields = ['user__email', 'user__full_name']
    readonly_fields = ['id']


@admin.register(CookProfile)
class CookProfileAdmin(admin.ModelAdmin):
    list_display = [
        'display_name', 'user', 'kitchen_city', 'avg_rating',
        'total_reviews', 'is_active', 'status', 'created_at',
    ]
    list_filter = ['status', 'is_active', 'kitchen_city', 'delivery_enabled']
    search_fields = ['display_name', 'user__email', 'user__full_name', 'kitchen_city']
    readonly_fields = ['id', 'avg_rating', 'total_reviews', 'created_at', 'updated_at']


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['label', 'user', 'street', 'city', 'state', 'is_default', 'created_at']
    list_filter = ['is_default', 'city', 'state']
    search_fields = ['user__email', 'user__full_name', 'street', 'city']
    readonly_fields = ['id', 'created_at']


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ['customer', 'cook', 'created_at']
    list_filter = ['created_at']
    search_fields = ['customer__email', 'customer__full_name', 'cook__display_name']
    readonly_fields = ['id', 'created_at']


@admin.register(AdminProfile)
class AdminProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'admin_role', 'status']
    list_filter = ['admin_role', 'status']
    search_fields = ['user__email', 'user__full_name']
    readonly_fields = ['id']
