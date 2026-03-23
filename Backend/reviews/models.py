import uuid
from django.db import models
from accounts.models import User, CookProfile
from meals.models import Meal
from orders.models import Order


class Review(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='review')
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews')
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='reviews')
    meal = models.ForeignKey(Meal, on_delete=models.SET_NULL, null=True, related_name='reviews')
    rating = models.IntegerField()  # 1-5
    delivery_rating = models.IntegerField(null=True, blank=True)  # 1-5, delivery orders only
    comment = models.TextField(max_length=500, blank=True)
    cook_reply = models.TextField(max_length=300, blank=True)
    cook_replied_at = models.DateTimeField(null=True, blank=True)
    is_visible = models.BooleanField(default=True)
    is_flagged = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'reviews'
        ordering = ['-created_at']

    def __str__(self):
        return f"Review by {self.customer.full_name} - {self.rating}/5"

    def save(self, *args, **kwargs):
        if self.rating <= 2:
            self.is_flagged = True
        super().save(*args, **kwargs)


class ReviewImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='images')
    image_url = models.URLField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'review_images'

    def __str__(self):
        return f"Image for review {self.review.id}"
