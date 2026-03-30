from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AvailableNowView,
    FeaturedMealsView,
    MealExtraViewSet,
    MealImageViewSet,
    MealViewSet,
    PickupSlotViewSet,
    RecurringSlotTemplateViewSet,
)

router = DefaultRouter()
router.register(r'meals', MealViewSet, basename='meal')
router.register(r'pickup-slots', PickupSlotViewSet, basename='pickupslot')
router.register(r'slot-templates', RecurringSlotTemplateViewSet, basename='slottemplate')

urlpatterns = [
    # Featured & Available-now (before router so they don't clash with {pk})
    path('meals/featured/', FeaturedMealsView.as_view(), name='meal-featured'),
    path('meals/available-now/', AvailableNowView.as_view(), name='meal-available-now'),

    # Nested meal extras
    path(
        'meals/<uuid:meal_pk>/extras/',
        MealExtraViewSet.as_view({'get': 'list', 'post': 'create'}),
        name='meal-extra-list',
    ),
    path(
        'meals/<uuid:meal_pk>/extras/<uuid:pk>/',
        MealExtraViewSet.as_view({
            'get': 'retrieve',
            'put': 'update',
            'patch': 'partial_update',
            'delete': 'destroy',
        }),
        name='meal-extra-detail',
    ),

    # Nested meal images
    path(
        'meals/<uuid:meal_pk>/images/',
        MealImageViewSet.as_view({'get': 'list', 'post': 'create'}),
        name='meal-image-list',
    ),
    path(
        'meals/<uuid:meal_pk>/images/<uuid:pk>/',
        MealImageViewSet.as_view({
            'get': 'retrieve',
            'put': 'update',
            'patch': 'partial_update',
            'delete': 'destroy',
        }),
        name='meal-image-detail',
    ),

    # Router-generated routes
    path('', include(router.urls)),
]
