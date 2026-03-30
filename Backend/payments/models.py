import uuid
from django.db import models
from accounts.models import User, CookProfile
from orders.models import Order


class WalletTransaction(models.Model):
    """Tracks every credit/debit to a customer's wallet."""
    TYPE_CHOICES = [
        ('topup', 'Top Up'),
        ('payment', 'Payment'),
        ('refund', 'Refund'),
        ('cashback', 'Cashback'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallet_transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_type = models.CharField(max_length=15, choices=TYPE_CHOICES)
    description = models.CharField(max_length=255)
    balance_after = models.DecimalField(max_digits=10, decimal_places=2)
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, related_name='wallet_transactions')
    gateway_transaction_id = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'wallet_transactions'
        ordering = ['-created_at']

    def __str__(self):
        sign = '+' if self.amount > 0 else ''
        return f"Wallet {self.transaction_type}: {sign}{self.amount} for {self.user.full_name}"


class Payment(models.Model):
    METHOD_CHOICES = [
        ('card', 'Card'),
        ('upi', 'UPI'),
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('net_banking', 'Net Banking'),
        ('wallet', 'Wallet'),
    ]
    STATUS_CHOICES = [
        ('initiated', 'Initiated'),
        ('requires_payment', 'Requires Payment'),
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('refund_initiated', 'Refund Initiated'),
        ('refunded', 'Refunded'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='payment')
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='AUD')
    method = models.CharField(max_length=15, choices=METHOD_CHOICES)
    gateway = models.CharField(max_length=50, default='stripe')
    gateway_transaction_id = models.CharField(max_length=255, blank=True)
    stripe_payment_intent_id = models.CharField(max_length=255, blank=True)
    stripe_client_secret = models.CharField(max_length=255, blank=True)
    gateway_status = models.CharField(max_length=50, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='initiated')
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    refund_reason = models.CharField(max_length=255, blank=True)
    refund_initiated_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payments'

    def __str__(self):
        return f"Payment {self.id} - {self.status}"


class CookPayout(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cook = models.ForeignKey(CookProfile, on_delete=models.CASCADE, related_name='payouts')
    period_start = models.DateField()
    period_end = models.DateField()
    gross_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    delivery_fees_collected = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    commission_deducted = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    net_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')
    bank_reference = models.CharField(max_length=255, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'cook_payouts'

    def __str__(self):
        return f"Payout to {self.cook.display_name} ({self.period_start} - {self.period_end})"
