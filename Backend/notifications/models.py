import uuid
from django.db import models
from accounts.models import User


class Notification(models.Model):
    CHANNEL_CHOICES = [
        ('push', 'Push'),
        ('email', 'Email'),
        ('sms', 'SMS'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    channel = models.CharField(max_length=5, choices=CHANNEL_CHOICES, default='push')
    event_type = models.CharField(max_length=50)  # order_placed, order_accepted, etc.
    reference_id = models.UUIDField(null=True, blank=True)  # order_id, review_id, etc.
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} -> {self.user.full_name}"
