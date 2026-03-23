from django.contrib import admin
from .models import Review, ReviewImage


class ReviewImageInline(admin.TabularInline):
    model = ReviewImage
    extra = 0
    readonly_fields = ['id', 'created_at']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'cook', 'meal', 'rating', 'is_visible', 'is_flagged', 'created_at']
    list_filter = ['rating', 'is_visible', 'is_flagged']
    search_fields = ['customer__full_name', 'cook__display_name', 'comment']
    readonly_fields = ['id', 'created_at', 'updated_at']
    inlines = [ReviewImageInline]


@admin.register(ReviewImage)
class ReviewImageAdmin(admin.ModelAdmin):
    list_display = ['id', 'review', 'image_url', 'created_at']
    readonly_fields = ['id', 'created_at']
