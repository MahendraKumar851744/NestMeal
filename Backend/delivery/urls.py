from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DeliveryZoneViewSet, DeliverySlotViewSet, CalculateDeliveryFeeView

router = DefaultRouter()
router.register(r'delivery-zones', DeliveryZoneViewSet, basename='delivery-zone')
router.register(r'delivery-slots', DeliverySlotViewSet, basename='delivery-slot')

urlpatterns = [
    path('', include(router.urls)),
    path('delivery/calculate-fee/', CalculateDeliveryFeeView.as_view(), name='calculate-delivery-fee'),
]
