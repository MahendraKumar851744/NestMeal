from django.db.models import Avg, Count
from django.utils import timezone
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from .models import Review, ReviewImage
from .serializers import (
    ReviewSerializer, ReviewCreateSerializer, ReviewUpdateSerializer,
    CookReplySerializer, ReviewImageSerializer,
)


class ReviewViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewSerializer
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        queryset = Review.objects.filter(is_visible=True).select_related(
            'customer', 'cook', 'meal'
        ).prefetch_related('images')

        cook_id = self.request.query_params.get('cook_id')
        meal_id = self.request.query_params.get('meal_id')
        min_rating = self.request.query_params.get('min_rating')

        if cook_id:
            queryset = queryset.filter(cook_id=cook_id)
        if meal_id:
            queryset = queryset.filter(meal_id=meal_id)
        if min_rating:
            queryset = queryset.filter(rating__gte=int(min_rating))

        return queryset

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        if self.action == 'create':
            return [IsAuthenticated(), IsCustomer()]
        if self.action in ['update', 'partial_update']:
            return [IsAuthenticated(), IsCustomer()]
        if self.action == 'reply':
            return [IsAuthenticated(), IsCook()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == 'create':
            return ReviewCreateSerializer
        if self.action in ['update', 'partial_update']:
            return ReviewUpdateSerializer
        if self.action == 'reply':
            return CookReplySerializer
        return ReviewSerializer

    def create(self, request, *args, **kwargs):
        serializer = ReviewCreateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        order = serializer.context['order']
        # Get the first meal from order items if available
        first_item = order.items.select_related('meal').first()
        meal = first_item.meal if first_item else None

        review = Review.objects.create(
            order=order,
            customer=request.user,
            cook=order.cook,
            meal=meal,
            rating=serializer.validated_data['rating'],
            delivery_rating=serializer.validated_data.get('delivery_rating'),
            comment=serializer.validated_data.get('comment', ''),
        )

        self._recalculate_ratings(order.cook, meal)

        return Response(
            ReviewSerializer(review).data,
            status=status.HTTP_201_CREATED,
        )

    def partial_update(self, request, *args, **kwargs):
        review = self.get_object()

        if review.customer != request.user:
            return Response(
                {'detail': 'You can only edit your own reviews.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ReviewUpdateSerializer(
            data=request.data,
            context={'request': request, 'review': review},
        )
        serializer.is_valid(raise_exception=True)

        if 'rating' in serializer.validated_data:
            review.rating = serializer.validated_data['rating']
        if 'comment' in serializer.validated_data:
            review.comment = serializer.validated_data['comment']
        review.save()

        self._recalculate_ratings(review.cook, review.meal)

        return Response(ReviewSerializer(review).data)

    @action(detail=True, methods=['patch'], url_path='reply')
    def reply(self, request, pk=None):
        review = self.get_object()

        # Verify the cook owns this review
        if not hasattr(request.user, 'cook_profile') or review.cook != request.user.cook_profile:
            return Response(
                {'detail': 'You can only reply to reviews on your own orders.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CookReplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        review.cook_reply = serializer.validated_data['cook_reply']
        review.cook_replied_at = timezone.now()
        review.save(update_fields=['cook_reply', 'cook_replied_at'])

        return Response(ReviewSerializer(review).data)

    def _recalculate_ratings(self, cook, meal):
        """Recalculate average rating and total reviews for cook and meal."""
        # Cook ratings
        cook_stats = Review.objects.filter(
            cook=cook, is_visible=True
        ).aggregate(avg=Avg('rating'), count=Count('id'))
        cook.avg_rating = cook_stats['avg'] or 0
        cook.total_reviews = cook_stats['count'] or 0
        cook.save(update_fields=['avg_rating', 'total_reviews'])

        # Meal ratings
        if meal:
            meal_stats = Review.objects.filter(
                meal=meal, is_visible=True
            ).aggregate(avg=Avg('rating'), count=Count('id'))
            meal.avg_rating = meal_stats['avg'] or 0
            meal.save(update_fields=['avg_rating'])


class ReviewImageViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewImageSerializer
    permission_classes = [IsAuthenticated, IsCustomer]
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_queryset(self):
        return ReviewImage.objects.filter(review__customer=self.request.user)

    def create(self, request, *args, **kwargs):
        review_id = request.data.get('review')
        try:
            review = Review.objects.get(id=review_id, customer=request.user)
        except Review.DoesNotExist:
            return Response(
                {'detail': 'Review not found or not yours.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Max 3 images per review
        if review.images.count() >= 3:
            return Response(
                {'detail': 'Maximum 3 images allowed per review.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ReviewImageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(review=review)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
