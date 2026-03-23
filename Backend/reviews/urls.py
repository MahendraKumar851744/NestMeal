from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ReviewViewSet, ReviewImageViewSet

router = DefaultRouter()
router.register(r'reviews', ReviewViewSet, basename='review')
router.register(r'review-images', ReviewImageViewSet, basename='review-image')

urlpatterns = [
    path('', include(router.urls)),
]
