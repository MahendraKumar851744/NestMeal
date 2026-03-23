from django.contrib import admin
from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'title', 'channel', 'event_type', 'is_read', 'created_at']
    list_filter = ['channel', 'event_type', 'is_read']
    search_fields = ['user__full_name', 'title', 'message']
    readonly_fields = ['id', 'created_at']
