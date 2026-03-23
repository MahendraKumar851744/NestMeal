from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from .models import Coupon, CouponUsage
from .serializers import CouponSerializer, CouponCreateSerializer, CouponValidateSerializer


class CouponViewSet(viewsets.ModelViewSet):
    serializer_class = CouponSerializer
    http_method_names = ['get', 'post', 'put', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            from django.utils import timezone
            now = timezone.now()
            return Coupon.objects.filter(
                is_active=True, valid_from__lte=now, valid_until__gte=now
            )
        if user.role == 'admin':
            return Coupon.objects.all()
        if user.role == 'cook':
            return Coupon.objects.filter(created_by='cook', applicable_ids__contains=[str(user.cook_profile.id)])
        # Customer: show active coupons
        from django.utils import timezone
        now = timezone.now()
        return Coupon.objects.filter(
            is_active=True, valid_from__lte=now, valid_until__gte=now
        )

    def get_permissions(self):
        if self.action == 'list':
            return [AllowAny()]
        if self.action == 'validate':
            return [IsAuthenticated(), IsCustomer()]
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == 'create':
            return CouponCreateSerializer
        if self.action == 'validate':
            return CouponValidateSerializer
        return CouponSerializer

    @action(detail=False, methods=['post'], url_path='validate')
    def validate(self, request):
        serializer = CouponValidateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        coupon = serializer.validated_data['coupon']
        discount_amount = serializer.validated_data['discount_amount']

        return Response({
            'valid': True,
            'coupon_code': coupon.code,
            'discount_type': coupon.discount_type,
            'discount_value': str(coupon.discount_value),
            'discount_amount': str(discount_amount),
            'description': coupon.description,
        })
