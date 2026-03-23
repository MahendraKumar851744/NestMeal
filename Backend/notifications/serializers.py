from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'title', 'message', 'channel', 'event_type',
            'reference_id', 'is_read', 'created_at',
        ]
        read_only_fields = fields
