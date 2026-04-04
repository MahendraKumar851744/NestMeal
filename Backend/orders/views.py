from decimal import Decimal
from django.db.models import Sum, Count, Q
from django.utils import timezone
from rest_framework import viewsets, status, generics
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsCook, IsCustomer, IsAdmin
from orders.models import Order, OrderItem, OrderMessage
from orders.serializers import (
    OrderSerializer,
    OrderListSerializer,
    OrderCreateSerializer,
    OrderStatusUpdateSerializer,
    OrderCancelSerializer,
    OrderMessageSerializer,
    OrderMessageCreateSerializer,
)


class OrderViewSet(viewsets.GenericViewSet):
    """
    ViewSet for managing orders.

    list            – GET    /orders/
    retrieve        – GET    /orders/{id}/
    create          – POST   /orders/
    update_status   – POST   /orders/{id}/update-status/
    cancel          – POST   /orders/{id}/cancel/
    verify_pickup   – POST   /orders/{id}/verify-pickup/
    stats           – GET    /orders/stats/
    """

    queryset = Order.objects.select_related('customer', 'cook', 'pickup_slot', 'delivery_slot')
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'list':
            return OrderListSerializer
        if self.action == 'create':
            return OrderCreateSerializer
        if self.action == 'update_status':
            return OrderStatusUpdateSerializer
        if self.action == 'cancel':
            return OrderCancelSerializer
        return OrderSerializer

    # ---- helpers ----

    def _get_order(self, pk):
        try:
            return Order.objects.select_related(
                'customer', 'cook', 'pickup_slot', 'delivery_slot',
            ).get(pk=pk)
        except Order.DoesNotExist:
            return None

    def _can_access_order(self, user, order):
        if user.role == 'admin':
            return True
        if user.role == 'customer' and order.customer == user:
            return True
        if user.role == 'cook' and hasattr(user, 'cook_profile') and order.cook == user.cook_profile:
            return True
        return False

    # ---- list ----

    def list(self, request):
        user = request.user
        qs = self.get_queryset()

        # Role-based filtering
        if user.role == 'customer':
            qs = qs.filter(customer=user)
        elif user.role == 'cook' and hasattr(user, 'cook_profile'):
            qs = qs.filter(cook=user.cook_profile)
        elif user.role != 'admin':
            return Response(
                {'detail': 'Not authorized.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Query-param filters
        filter_status = request.query_params.get('status')
        if filter_status:
            qs = qs.filter(status=filter_status)

        fulfillment_type = request.query_params.get('fulfillment_type')
        if fulfillment_type:
            qs = qs.filter(fulfillment_type=fulfillment_type)

        date_from = request.query_params.get('date_from')
        if date_from:
            qs = qs.filter(created_at__date__gte=date_from)

        date_to = request.query_params.get('date_to')
        if date_to:
            qs = qs.filter(created_at__date__lte=date_to)

        serializer = OrderListSerializer(qs, many=True)
        return Response(serializer.data)

    # ---- retrieve ----

    def retrieve(self, request, pk=None):
        order = self._get_order(pk)
        if not order:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)
        if not self._can_access_order(request.user, order):
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = OrderSerializer(order)
        return Response(serializer.data)

    # ---- create ----

    def create(self, request):
        if request.user.role != 'customer':
            return Response(
                {'detail': 'Only customers can place orders.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = OrderCreateSerializer(
            data=request.data,
            context={'request': request},
        )
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    # ---- update status ----

    @action(detail=True, methods=['post'], url_path='update-status')
    def update_status(self, request, pk=None):
        order = self._get_order(pk)
        if not order:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Only cook who owns the order or admin can update status
        user = request.user
        is_cook_owner = (
            user.role == 'cook'
            and hasattr(user, 'cook_profile')
            and order.cook == user.cook_profile
        )
        if not (is_cook_owner or user.role == 'admin'):
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = OrderStatusUpdateSerializer(
            data=request.data,
            context={'order': order},
        )
        serializer.is_valid(raise_exception=True)

        order.status = serializer.validated_data['status']

        # Set timestamps when applicable
        if order.status == 'delivered':
            order.delivered_at = timezone.now()
            order.delivery_status = 'delivered'
        elif order.status == 'out_for_delivery':
            order.delivery_status = 'out_for_delivery'
        elif order.status == 'picked_up':
            order.delivered_at = timezone.now()
        elif order.status == 'completed':
            if not order.delivered_at:
                order.delivered_at = timezone.now()

        order.save()
        return Response(OrderSerializer(order).data)

    # ---- cancel ----

    @action(detail=True, methods=['post'], url_path='cancel')
    def cancel(self, request, pk=None):
        order = self._get_order(pk)
        if not order:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user

        # Determine who is cancelling
        if user.role == 'customer' and order.customer == user:
            cancelled_by = 'customer'
        elif user.role == 'cook' and hasattr(user, 'cook_profile') and order.cook == user.cook_profile:
            cancelled_by = 'cook'
        elif user.role == 'admin':
            cancelled_by = 'system'
        else:
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        # Only allow cancellation from certain statuses
        if order.status not in ('placed', 'accepted'):
            return Response(
                {'detail': 'Order cannot be cancelled at this stage.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = OrderCancelSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        order.status = 'cancelled'
        order.cancelled_by = cancelled_by
        order.cancellation_reason = serializer.validated_data['cancellation_reason']
        order.save()

        return Response(OrderSerializer(order).data)

    # ---- verify pickup ----

    @action(detail=True, methods=['post'], url_path='verify-pickup')
    def verify_pickup(self, request, pk=None):
        order = self._get_order(pk)
        if not order:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Only the cook who owns this order can verify
        user = request.user
        is_cook_owner = (
            user.role == 'cook'
            and hasattr(user, 'cook_profile')
            and order.cook == user.cook_profile
        )
        if not (is_cook_owner or user.role == 'admin'):
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        if order.fulfillment_type != 'pickup':
            return Response(
                {'detail': 'This order is not a pickup order.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if order.status != 'ready_for_pickup':
            return Response(
                {'detail': 'Order is not ready for pickup verification.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        code = request.data.get('pickup_code', '')
        if code != order.pickup_code:
            return Response(
                {'detail': 'Invalid pickup code.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        order.status = 'picked_up'
        order.pickup_time_actual = timezone.now()
        order.save()

        return Response(OrderSerializer(order).data)

    # ---- stats (cook dashboard) ----

    @action(detail=False, methods=['get'], url_path='stats')
    def stats(self, request):
        user = request.user
        if user.role != 'cook' or not hasattr(user, 'cook_profile'):
            return Response({'detail': 'Cook access only.'}, status=status.HTTP_403_FORBIDDEN)

        cook_profile = user.cook_profile
        orders = Order.objects.filter(cook=cook_profile)

        total_orders = orders.count()
        completed_orders = orders.filter(
            status__in=['completed', 'delivered', 'picked_up'],
        ).count()
        cancelled_orders = orders.filter(status='cancelled').count()
        total_revenue = orders.filter(
            status__in=['completed', 'delivered', 'picked_up'],
        ).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')

        # Today's stats
        today = timezone.now().date()
        today_orders = orders.filter(created_at__date=today).count()
        today_revenue = orders.filter(
            created_at__date=today,
            status__in=['completed', 'delivered', 'picked_up'],
        ).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')

        pending_orders = orders.filter(status='placed').count()

        return Response({
            'total_orders': total_orders,
            'completed_orders': completed_orders,
            'cancelled_orders': cancelled_orders,
            'total_revenue': str(total_revenue),
            'today_orders': today_orders,
            'today_revenue': str(today_revenue),
            'pending_orders': pending_orders,
        })

    # ── Chat ─────────────────────────────────────────────────────────────────

    def _get_order_for_chat(self, request, pk):
        """Return the order if the requester is the customer or the cook."""
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return None, Response(
                {'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND
            )
        user = request.user
        is_customer = order.customer == user
        is_cook = (
            hasattr(user, 'cook_profile') and order.cook == user.cook_profile
        )
        if not (is_customer or is_cook):
            return None, Response(
                {'detail': 'Not authorised.'}, status=status.HTTP_403_FORBIDDEN
            )
        return order, None

    @action(detail=True, methods=['get', 'post'], url_path='messages',
            permission_classes=[IsAuthenticated])
    def messages(self, request, pk=None):
        """
        GET  /orders/{id}/messages/ — fetch all chat messages.
        POST /orders/{id}/messages/ — send a chat message.
        """
        order, err = self._get_order_for_chat(request, pk)
        if err:
            return err

        if request.method == 'GET':
            msgs = order.messages.select_related('sender').all()
            serializer = OrderMessageSerializer(
                msgs, many=True, context={'request': request}
            )
            return Response(serializer.data)

        # POST
        closed_statuses = {'completed', 'cancelled', 'rejected'}
        if order.status in closed_statuses:
            return Response(
                {'detail': 'Chat is closed for this order.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = OrderMessageCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        is_cook = (
            hasattr(user, 'cook_profile') and order.cook == user.cook_profile
        )
        msg = OrderMessage.objects.create(
            order=order,
            sender=user,
            sender_role='cook' if is_cook else 'customer',
            message=serializer.validated_data['message'],
        )
        return Response(
            OrderMessageSerializer(msg, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class OrderStatsView(generics.GenericAPIView):
    """
    Alternative standalone view for cook dashboard statistics.
    GET /orders/stats/
    """
    permission_classes = [IsAuthenticated, IsCook]

    def get(self, request):
        cook_profile = request.user.cook_profile
        orders = Order.objects.filter(cook=cook_profile)

        completed_statuses = ['completed', 'delivered', 'picked_up']
        total_orders = orders.count()
        completed_orders = orders.filter(status__in=completed_statuses).count()
        cancelled_orders = orders.filter(status='cancelled').count()
        total_revenue = orders.filter(
            status__in=completed_statuses,
        ).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')

        today = timezone.now().date()
        today_orders = orders.filter(created_at__date=today).count()
        today_revenue = orders.filter(
            created_at__date=today,
            status__in=completed_statuses,
        ).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')

        pending_orders = orders.filter(status='placed').count()

        return Response({
            'total_orders': total_orders,
            'completed_orders': completed_orders,
            'cancelled_orders': cancelled_orders,
            'total_revenue': str(total_revenue),
            'today_orders': today_orders,
            'today_revenue': str(today_revenue),
            'pending_orders': pending_orders,
        })
