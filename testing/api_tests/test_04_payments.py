"""
Test Suite: Payments, Payouts, Wallet
=====================================
Tests payment processing, cook payouts, wallet operations.
"""

import pytest
from conftest import BASE_URL


@pytest.mark.payments
@pytest.mark.smoke
class TestPayments:
    """Test payment endpoints: /payments/"""

    url = f"{BASE_URL}/payments/"

    def test_list_payments_authenticated(self, api_session, customer_headers, issue_tracker):
        """Customer can list their payments."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Payment listing fails",
                description=f"GET /payments/ returned {resp.status_code}",
                severity="HIGH",
                category="API",
                endpoint="GET /payments/",
            )
        assert resp.status_code == 200

    def test_list_payments_unauthenticated(self, api_session, issue_tracker):
        """Payments should require authentication."""
        resp = api_session.get(self.url)
        assert resp.status_code == 401

    def test_payment_has_required_fields(self, api_session, customer_headers, issue_tracker):
        """Payments should have essential fields."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code == 200:
            data = resp.json()
            payments = data if isinstance(data, list) else data.get("results", [])
            for payment in payments[:3]:
                for field in ["id", "amount", "status"]:
                    if field not in payment:
                        issue_tracker.add(
                            title=f"Payment missing field: {field}",
                            description=f"Payment record missing '{field}'",
                            severity="MEDIUM",
                            category="API",
                            endpoint="GET /payments/",
                        )


@pytest.mark.payments
class TestWalletTopUp:
    """Test wallet top-up: POST /payments/wallet/top-up/ (Issue #14)"""

    url = f"{BASE_URL}/payments/wallet/top-up/"

    def test_wallet_topup_endpoint_exists(self, api_session, customer_headers, issue_tracker):
        """Wallet top-up endpoint should exist."""
        resp = api_session.post(
            self.url,
            headers=customer_headers,
            json={"amount": "50.00"},
        )
        if resp.status_code == 404:
            issue_tracker.add(
                title="Wallet top-up endpoint not found",
                description="POST /payments/wallet/top-up/ returns 404",
                severity="HIGH",
                category="API",
                endpoint="POST /payments/wallet/top-up/",
                related_tracker_issue="14",
            )
        if resp.status_code == 405:
            issue_tracker.add(
                title="Wallet top-up endpoint not implemented (405)",
                description="POST /payments/wallet/top-up/ returns 405 Method Not Allowed",
                severity="HIGH",
                category="API",
                endpoint="POST /payments/wallet/top-up/",
                related_tracker_issue="14",
            )
        assert resp.status_code in [200, 201, 400]

    def test_wallet_topup_negative_amount(self, api_session, customer_headers, issue_tracker):
        """Wallet top-up with negative amount should fail."""
        resp = api_session.post(
            self.url,
            headers=customer_headers,
            json={"amount": "-100.00"},
        )
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Wallet accepts negative top-up amount",
                description="POST /payments/wallet/top-up/ accepts negative amount - potential exploit",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /payments/wallet/top-up/",
            )
        assert resp.status_code == 400

    def test_wallet_topup_zero_amount(self, api_session, customer_headers, issue_tracker):
        """Wallet top-up with zero amount should fail."""
        resp = api_session.post(
            self.url,
            headers=customer_headers,
            json={"amount": "0.00"},
        )
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Wallet accepts zero top-up amount",
                description="POST /payments/wallet/top-up/ accepts amount=0",
                severity="MEDIUM",
                category="LOGIC",
                endpoint="POST /payments/wallet/top-up/",
            )


@pytest.mark.payments
class TestCookPayouts:
    """Test cook payouts: /payouts/"""

    url = f"{BASE_URL}/payouts/"

    def test_list_payouts_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook can list their payouts."""
        resp = api_session.get(self.url, headers=cook_headers)
        if resp.status_code not in [200, 403]:
            issue_tracker.add(
                title="Payout listing fails",
                description=f"GET /payouts/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /payouts/",
            )
        assert resp.status_code in [200, 403]

    def test_payouts_unauthenticated(self, api_session, issue_tracker):
        """Payouts should require authentication."""
        resp = api_session.get(self.url)
        assert resp.status_code == 401
