from django.contrib import admin
from .models import Meal, MealExtra, MealImage, PickupSlot, RecurringSlotTemplate


class MealImageInline(admin.TabularInline):
    model = MealImage
    extra = 0
    fields = ['image', 'display_order']  
    
class MealExtraInline(admin.TabularInline):
    model = MealExtra
    extra = 0
    fields = ['name', 'price', 'is_available', 'display_order']


@admin.register(Meal)
class MealAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'cook', 'category', 'meal_type', 'price',
        'discount_percentage', 'spice_level', 'avg_rating',
        'is_available', 'is_featured', 'status', 'total_orders',
        'created_at',
    ]
    list_filter = [
        'category', 'meal_type', 'spice_level', 'status',
        'is_available', 'is_featured', 'currency',
    ]
    search_fields = [
        'title', 'description', 'cuisine_type',
        'cook__display_name', 'cook__user__email',
    ]
    readonly_fields = ['id', 'total_orders', 'avg_rating', 'created_at', 'updated_at']
    inlines = [MealImageInline, MealExtraInline]
    list_per_page = 25


@admin.register(MealImage)
class MealImageAdmin(admin.ModelAdmin):
    list_display = ['id', 'meal', 'display_order', 'created_at']
    list_filter = ['created_at']
    search_fields = ['meal__title']
    readonly_fields = ['id', 'created_at']


@admin.register(PickupSlot)
class PickupSlotAdmin(admin.ModelAdmin):
    list_display = [
        'cook', 'date', 'start_time', 'end_time',
        'max_orders', 'booked_orders', 'is_available', 'status',
    ]
    list_filter = ['date', 'status', 'is_available']
    search_fields = [
        'cook__display_name', 'cook__user__email',
        'location_label', 'location_street',
    ]
    readonly_fields = ['id', 'created_at']
    list_per_page = 25


@admin.register(RecurringSlotTemplate)
class RecurringSlotTemplateAdmin(admin.ModelAdmin):
    list_display = [
        'cook', 'days_of_week', 'start_time', 'end_time',
        'max_orders', 'slot_type', 'is_active',
        'effective_from', 'effective_until',
    ]
    list_filter = ['slot_type', 'is_active', 'effective_from']
    search_fields = ['cook__display_name', 'cook__user__email']
    readonly_fields = ['id', 'created_at']
    list_per_page = 25
