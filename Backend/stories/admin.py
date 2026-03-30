from django.contrib import admin
from .models import Story


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'cook', 'caption', 'created_at', 'expires_at', 'is_active']
    list_filter = ['is_active', 'created_at']
    search_fields = ['cook__display_name', 'caption']
