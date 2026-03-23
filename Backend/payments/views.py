import uuid
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from .models import Payment, CookPayout
from .serializers import PaymentSerializer, PaymentCreateSerializer, CookPayoutSerializer


class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return Payment.objects.all()
        return Payment.objects.filter(customer=user)

    def get_serializer_class(self):
        if self.action == 'create':
            return PaymentCreateSerializer
        return PaymentSerializer

    def create(self, request, *args, **kwargs):
        serializer = PaymentCreateSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        order = serializer.context['order']

        # Create payment record
        payment = Payment.objects.create(
            order=order,
            customer=request.user,
            amount=order.total_amount,
            currency='INR',
            method=serializer.validated_data['method'],
            gateway=serializer.validated_data.get('gateway', 'razorpay'),
            gateway_transaction_id=f"txn_{uuid.uuid4().hex[:20]}",
        )

        # Simulate gateway success
        payment.status = 'success'
        payment.gateway_status = 'captured'
        payment.paid_at = timezone.now()
        payment.save()

        # Update order payment status
        order.payment_status = 'paid'
        order.save(update_fields=['payment_status'])

        return Response(
            PaymentSerializer(payment).data,
            status=status.HTTP_201_CREATED,
        )


class CookPayoutViewSet(viewsets.ModelViewSet):
    serializer_class = CookPayoutSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return CookPayout.objects.all()
        if user.role == 'cook':
            return CookPayout.objects.filter(cook=user.cook_profile)
        return CookPayout.objects.none()

    def get_permissions(self):
        if self.action == 'create':
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        serializer = CookPayoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
