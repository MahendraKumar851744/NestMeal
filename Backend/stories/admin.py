from django.contrib import admin
from .models import Story, StoryView


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'cook', 'caption', 'created_at', 'expires_at', 'is_active']
    list_filter = ['is_active', 'created_at']
    search_fields = ['cook__display_name', 'caption']


@admin.register(StoryView)
class StoryViewAdmin(admin.ModelAdmin):
    list_display = ['id', 'story', 'customer', 'viewed_at']
    list_filter = ['viewed_at']
    search_fields = ['customer__email', 'story__cook__display_name']
    readonly_fields = ['story', 'customer', 'viewed_at']
