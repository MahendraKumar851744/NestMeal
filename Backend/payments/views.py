import stripe
from django.conf import settings
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from .models import Payment, CookPayout
from .serializers import (
    PaymentSerializer,
    PaymentCreateSerializer,
    PaymentIntentResponseSerializer,
    CookPayoutSerializer,
)

stripe.api_key = settings.STRIPE_SECRET_KEY


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
        """Create a Stripe PaymentIntent and return the client_secret."""
        serializer = PaymentCreateSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        order = serializer.context['order']
        method = serializer.validated_data.get('method', 'card')

        # Amount in cents for Stripe
        amount_cents = int(order.total_amount * 100)

        try:
            intent = stripe.PaymentIntent.create(
                amount=amount_cents,
                currency=settings.STRIPE_CURRENCY,
                metadata={
                    'order_id': str(order.id),
                    'order_number': order.order_number,
                    'customer_email': request.user.email,
                },
                automatic_payment_methods={'enabled': True},
            )
        except stripe.error.StripeError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Create payment record in our DB
        payment = Payment.objects.create(
            order=order,
            customer=request.user,
            amount=order.total_amount,
            currency='AUD',
            method=method,
            gateway='stripe',
            stripe_payment_intent_id=intent.id,
            stripe_client_secret=intent.client_secret,
            status='requires_payment',
        )

        return Response(
            {
                'payment_id': str(payment.id),
                'client_secret': intent.client_secret,
                'stripe_payment_intent_id': intent.id,
                'publishable_key': settings.STRIPE_PUBLISHABLE_KEY,
                'amount': float(order.total_amount),
                'currency': 'AUD',
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['post'], url_path='confirm')
    def confirm_payment(self, request):
        """
        Called by the frontend after Stripe payment sheet succeeds.
        Verifies with Stripe and updates order status.
        """
        payment_intent_id = request.data.get('payment_intent_id')
        if not payment_intent_id:
            return Response(
                {'error': 'payment_intent_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            payment = Payment.objects.get(
                stripe_payment_intent_id=payment_intent_id,
                customer=request.user,
            )
        except Payment.DoesNotExist:
            return Response(
                {'error': 'Payment not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Verify with Stripe
        try:
            intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        except stripe.error.StripeError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if intent.status == 'succeeded':
            payment.status = 'success'
            payment.gateway_status = 'succeeded'
            payment.gateway_transaction_id = intent.id
            payment.paid_at = timezone.now()
            payment.save()

            # Update order
            order = payment.order
            order.payment_status = 'paid'
            if order.status in ('placed', 'accepted'):
                order.status = 'preparing'
            order.save(update_fields=['payment_status', 'status'])

            return Response(PaymentSerializer(payment).data)

        elif intent.status == 'requires_payment_method':
            payment.status = 'failed'
            payment.gateway_status = intent.status
            payment.save()
            return Response(
                {'error': 'Payment failed. Please try again.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        else:
            payment.gateway_status = intent.status
            payment.save()
            return Response(
                {
                    'status': intent.status,
                    'message': 'Payment is still processing.',
                },
                status=status.HTTP_202_ACCEPTED,
            )

    @action(detail=False, methods=['get'], url_path='config')
    def stripe_config(self, request):
        """Return the Stripe publishable key for the frontend."""
        return Response({
            'publishable_key': settings.STRIPE_PUBLISHABLE_KEY,
        })


class WalletTopUpView(APIView):
    """POST /payments/wallet/top-up/ — add money to the customer's wallet."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from accounts.models import CustomerProfile
        from .models import WalletTransaction

        amount = request.data.get('amount')
        if amount is None:
            return Response(
                {'error': 'amount is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            amount = round(float(amount), 2)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid amount.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if amount <= 0:
            return Response(
                {'error': 'Amount must be greater than zero.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            profile = request.user.customer_profile
        except CustomerProfile.DoesNotExist:
            return Response(
                {'error': 'Customer profile not found.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from decimal import Decimal
        decimal_amount = Decimal(str(amount))
        new_balance = profile.wallet_balance + decimal_amount
        profile.wallet_balance = new_balance
        profile.save(update_fields=['wallet_balance'])

        WalletTransaction.objects.create(
            user=request.user,
            amount=decimal_amount,
            transaction_type='topup',
            description=f'Wallet top-up of A${amount:.2f}',
            balance_after=new_balance,
        )

        return Response({
            'balance': float(new_balance),
            'amount_added': amount,
            'message': f'A${amount:.2f} added to wallet successfully.',
        })


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
