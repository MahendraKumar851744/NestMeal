import uuid
from datetime import timedelta

from django.db import models
from django.utils import timezone

from accounts.models import CookProfile


class Story(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='stories')
    image = models.ImageField(upload_to='stories/')
    caption = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'stories'
        ordering = ['-created_at']

    def __str__(self):
        return f"Story by {self.cook.display_name} at {self.created_at}"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(hours=24)
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at
