"""
Test Suite: Orders
==================
Tests order creation, listing, status transitions, cancellation, pickup verification.
"""

import pytest
import requests
from decimal import Decimal

from conftest import BASE_URL


@pytest.mark.orders
@pytest.mark.smoke
class TestOrderListing:
    """Test order listing: GET /orders/"""

    url = f"{BASE_URL}/orders/"

    def test_list_orders_authenticated(self, api_session, customer_headers, issue_tracker):
        """Customer can list their orders."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Order listing fails for customer",
                description=f"GET /orders/ returned {resp.status_code}",
                severity="HIGH",
                category="API",
                endpoint="GET /orders/",
            )
        assert resp.status_code == 200

    def test_list_orders_unauthenticated(self, api_session, issue_tracker):
        """Order listing should require auth."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            issue_tracker.add(
                title="Orders accessible without authentication",
                description="GET /orders/ returns data without JWT",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="GET /orders/",
            )
        assert resp.status_code == 401

    def test_cook_list_orders(self, api_session, cook_headers, issue_tracker):
        """Cook can list their received orders."""
        resp = api_session.get(self.url, headers=cook_headers)
        assert resp.status_code == 200

    def test_order_list_has_required_fields(self, api_session, customer_headers, issue_tracker):
        """Order list items should have key fields."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code == 200:
            data = resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            required = ["id", "order_number", "status", "total_amount", "fulfillment_type"]
            for order in orders[:5]:
                for field in required:
                    if field not in order:
                        issue_tracker.add(
                            title=f"Order list missing field: {field}",
                            description=f"Order {order.get('order_number', '?')} missing '{field}'",
                            severity="MEDIUM",
                            category="API",
                            endpoint="GET /orders/",
                        )

    def test_orders_filter_by_status(self, api_session, customer_headers, issue_tracker):
        """Filter orders by status."""
        for status in ["placed", "accepted", "preparing", "completed", "cancelled"]:
            resp = api_session.get(self.url, headers=customer_headers, params={"status": status})
            assert resp.status_code == 200


@pytest.mark.orders
class TestOrderCreation:
    """Test order creation: POST /orders/"""

    url = f"{BASE_URL}/orders/"

    def _get_cook_and_meal(self, api_session):
        """Helper: get a cook ID, meal ID, and pickup slot for testing."""
        meals_resp = api_session.get(f"{BASE_URL}/meals/")
        if meals_resp.status_code != 200:
            return None, None, None

        data = meals_resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])

        for meal in meals:
            if meal.get("is_available") and meal.get("status") == "active":
                cook_id = meal.get("cook_id") or meal.get("cook")
                if isinstance(cook_id, dict):
                    cook_id = cook_id.get("id")
                if not cook_id:
                    continue
                meal_id = meal["id"]

                # Get pickup slots for THIS cook specifically
                slots_resp = api_session.get(
                    f"{BASE_URL}/pickup-slots/",
                    params={"cook": cook_id, "is_available": "true", "status": "open"},
                )
                slots = []
                if slots_resp.status_code == 200:
                    slot_data = slots_resp.json()
                    slots = slot_data if isinstance(slot_data, list) else slot_data.get("results", [])

                if slots:
                    return cook_id, meal_id, slots[0]["id"]

        return None, None, None

    def test_create_order_pickup(self, api_session, customer_headers, issue_tracker):
        """Customer can create a pickup order."""
        cook_id, meal_id, slot_id = self._get_cook_and_meal(api_session)
        if not cook_id or not meal_id:
            issue_tracker.add(
                title="No active meals available for order creation test",
                description="Cannot find an active meal with available cook to test ordering",
                severity="HIGH",
                category="API",
                endpoint="POST /orders/",
            )
            pytest.skip("No active meal found")

        if not slot_id:
            issue_tracker.add(
                title="No available pickup slots for order creation test",
                description="All pickup slots are either booked or unavailable",
                severity="HIGH",
                category="API",
                endpoint="POST /orders/",
                related_tracker_issue="20",
            )
            pytest.skip("No available pickup slot")

        payload = {
            "cook_id": str(cook_id),
            "fulfillment_type": "pickup",
            "items": [{"meal_id": str(meal_id), "quantity": 1}],
            "pickup_slot_id": str(slot_id),
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code not in [200, 201]:
            issue_tracker.add(
                title="Order creation fails",
                description=f"POST /orders/ returned {resp.status_code}: {resp.text[:300]}",
                severity="CRITICAL",
                category="API",
                endpoint="POST /orders/",
                expected="201 Created",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code in [200, 201]

        if resp.status_code in [200, 201]:
            order = resp.json()
            # Validate order fields
            assert order.get("status") == "placed"
            assert order.get("fulfillment_type") == "pickup"

            # Check pricing calculation
            item_total = float(order.get("item_total", 0))
            platform_fee = float(order.get("platform_fee", 0))
            tax = float(order.get("tax_amount", 0))
            total = float(order.get("total_amount", 0))

            expected_platform_fee = round(item_total * 0.03, 2)
            expected_tax = round((item_total + platform_fee) * 0.05, 2)

            if abs(platform_fee - expected_platform_fee) > 0.02:
                issue_tracker.add(
                    title="Platform fee calculation incorrect",
                    description=f"Item total={item_total}, Expected fee={expected_platform_fee}, Got={platform_fee}",
                    severity="HIGH",
                    category="LOGIC",
                    endpoint="POST /orders/",
                    related_tracker_issue="23",
                )

            # Check acceptance deadline is set
            if not order.get("acceptance_deadline"):
                issue_tracker.add(
                    title="Acceptance deadline not set on new order",
                    description="New order missing acceptance_deadline field",
                    severity="HIGH",
                    category="LOGIC",
                    endpoint="POST /orders/",
                    related_tracker_issue="12",
                )

            # Check pickup_code is generated
            if order.get("fulfillment_type") == "pickup" and not order.get("pickup_code"):
                issue_tracker.add(
                    title="Pickup code not generated for pickup order",
                    description="Pickup order should have a 6-digit pickup_code",
                    severity="HIGH",
                    category="LOGIC",
                    endpoint="POST /orders/",
                    related_tracker_issue="51",
                )

            return order

    def test_create_order_without_slot(self, api_session, customer_headers, issue_tracker):
        """Order without required slot should fail."""
        cook_id, meal_id, _ = self._get_cook_and_meal(api_session)
        if not cook_id or not meal_id:
            pytest.skip("No active meal found")

        payload = {
            "cook_id": str(cook_id),
            "fulfillment_type": "pickup",
            "items": [{"meal_id": str(meal_id), "quantity": 1}],
            # No pickup_slot_id
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        assert resp.status_code == 400

    def test_create_order_unauthenticated(self, api_session, issue_tracker):
        """Unauthenticated order creation should fail."""
        resp = api_session.post(self.url, json={"cook_id": "fake", "items": []})
        assert resp.status_code == 401

    def test_create_order_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook should not be able to place orders (customer-only)."""
        resp = api_session.post(self.url, headers=cook_headers, json={
            "cook_id": "00000000-0000-0000-0000-000000000000",
            "fulfillment_type": "pickup",
            "items": [{"meal_id": "00000000-0000-0000-0000-000000000000", "quantity": 1}],
            "pickup_slot_id": "00000000-0000-0000-0000-000000000000",
        })
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Cook can place orders (should be customer-only)",
                description="POST /orders/ succeeds for cook role",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /orders/",
            )
        assert resp.status_code in [400, 403]

    def test_create_order_zero_quantity(self, api_session, customer_headers, issue_tracker):
        """Order with zero quantity should fail."""
        cook_id, meal_id, slot_id = self._get_cook_and_meal(api_session)
        if not cook_id or not meal_id or not slot_id:
            pytest.skip("No active meal/slot found")

        payload = {
            "cook_id": str(cook_id),
            "fulfillment_type": "pickup",
            "items": [{"meal_id": str(meal_id), "quantity": 0}],
            "pickup_slot_id": str(slot_id),
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Order with zero quantity accepted",
                description="POST /orders/ accepts quantity=0",
                severity="HIGH",
                category="LOGIC",
                endpoint="POST /orders/",
            )
        assert resp.status_code == 400

    def test_create_order_negative_quantity(self, api_session, customer_headers, issue_tracker):
        """Order with negative quantity should fail."""
        cook_id, meal_id, slot_id = self._get_cook_and_meal(api_session)
        if not cook_id or not meal_id or not slot_id:
            pytest.skip("No active meal/slot found")

        payload = {
            "cook_id": str(cook_id),
            "fulfillment_type": "pickup",
            "items": [{"meal_id": str(meal_id), "quantity": -5}],
            "pickup_slot_id": str(slot_id),
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Order with negative quantity accepted",
                description="POST /orders/ accepts quantity=-5, potential pricing exploit",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /orders/",
            )
        assert resp.status_code == 400


@pytest.mark.orders
class TestOrderDetail:
    """Test order detail: GET /orders/<id>/"""

    def test_order_detail(self, api_session, customer_headers, issue_tracker):
        """Customer can view order detail."""
        list_resp = api_session.get(f"{BASE_URL}/orders/", headers=customer_headers)
        if list_resp.status_code == 200:
            data = list_resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            if orders:
                order_id = orders[0]["id"]
                resp = api_session.get(
                    f"{BASE_URL}/orders/{order_id}/",
                    headers=customer_headers,
                )
                assert resp.status_code == 200
                detail = resp.json()
                assert "items" in detail
                assert "total_amount" in detail


@pytest.mark.orders
@pytest.mark.critical
class TestOrderStatusTransitions:
    """Test order status updates: POST /orders/<id>/update-status/"""

    def _get_placed_order(self, api_session, cook_headers):
        """Get a placed order for the cook."""
        resp = api_session.get(
            f"{BASE_URL}/orders/",
            headers=cook_headers,
            params={"status": "placed"},
        )
        if resp.status_code == 200:
            data = resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            if orders:
                return orders[0]
        return None

    def test_accept_order(self, api_session, cook_headers, issue_tracker):
        """Cook can accept a placed order."""
        order = self._get_placed_order(api_session, cook_headers)
        if not order:
            pytest.skip("No placed order available for cook")

        resp = api_session.post(
            f"{BASE_URL}/orders/{order['id']}/update-status/",
            headers=cook_headers,
            json={"status": "accepted"},
        )
        if resp.status_code != 200:
            issue_tracker.add(
                title="Cook cannot accept order",
                description=f"POST /orders/<id>/update-status/ returned {resp.status_code}: {resp.text[:200]}",
                severity="HIGH",
                category="API",
                endpoint="POST /orders/<id>/update-status/",
                related_tracker_issue="50",
            )
        assert resp.status_code == 200

    def test_invalid_status_transition(self, api_session, cook_headers, issue_tracker):
        """Invalid status transition should fail (e.g., placed -> completed)."""
        order = self._get_placed_order(api_session, cook_headers)
        if not order:
            pytest.skip("No placed order available")

        resp = api_session.post(
            f"{BASE_URL}/orders/{order['id']}/update-status/",
            headers=cook_headers,
            json={"status": "completed"},
        )
        if resp.status_code == 200:
            issue_tracker.add(
                title="Invalid order status transition allowed (placed->completed)",
                description="Order jumped from 'placed' directly to 'completed'",
                severity="CRITICAL",
                category="LOGIC",
                endpoint="POST /orders/<id>/update-status/",
                related_tracker_issue="50",
                expected="400 with transition error",
                actual="200 OK",
            )
        assert resp.status_code == 400

    def test_customer_cannot_update_status(self, api_session, customer_headers, issue_tracker):
        """Customer should not be able to update order status."""
        list_resp = api_session.get(f"{BASE_URL}/orders/", headers=customer_headers)
        if list_resp.status_code == 200:
            data = list_resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            if orders:
                resp = api_session.post(
                    f"{BASE_URL}/orders/{orders[0]['id']}/update-status/",
                    headers=customer_headers,
                    json={"status": "accepted"},
                )
                if resp.status_code == 200:
                    issue_tracker.add(
                        title="Customer can update order status (cook-only)",
                        description="POST /orders/<id>/update-status/ succeeds for customer",
                        severity="CRITICAL",
                        category="SECURITY",
                        endpoint="POST /orders/<id>/update-status/",
                    )
                assert resp.status_code in [403, 400]


@pytest.mark.orders
@pytest.mark.critical
class TestOrderCancellation:
    """Test order cancellation: POST /orders/<id>/cancel/ (Issue #38)"""

    def test_cancel_order_with_reason(self, api_session, customer_headers, issue_tracker):
        """Customer can cancel an order with a reason."""
        list_resp = api_session.get(
            f"{BASE_URL}/orders/",
            headers=customer_headers,
            params={"status": "placed"},
        )
        if list_resp.status_code == 200:
            data = list_resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            if not orders:
                pytest.skip("No placed order to cancel")

            order = orders[0]
            resp = api_session.post(
                f"{BASE_URL}/orders/{order['id']}/cancel/",
                headers=customer_headers,
                json={"cancellation_reason": "Changed my mind - testing"},
            )
            if resp.status_code not in [200, 204]:
                issue_tracker.add(
                    title="Order cancellation fails with valid reason",
                    description=f"POST /orders/<id>/cancel/ returned {resp.status_code}: {resp.text[:300]}",
                    severity="CRITICAL",
                    category="API",
                    endpoint="POST /orders/<id>/cancel/",
                    related_tracker_issue="38",
                    expected="200 OK",
                    actual=f"{resp.status_code}: {resp.text[:200]}",
                    steps_to_reproduce=[
                        "Login as customer",
                        "Get a placed order",
                        "POST /orders/<id>/cancel/ with cancellation_reason",
                        "Check response",
                    ],
                )
            assert resp.status_code in [200, 204]

    def test_cancel_order_without_reason(self, api_session, customer_headers, issue_tracker):
        """Cancel without reason should fail (required field)."""
        list_resp = api_session.get(
            f"{BASE_URL}/orders/",
            headers=customer_headers,
            params={"status": "placed"},
        )
        if list_resp.status_code == 200:
            data = list_resp.json()
            orders = data if isinstance(data, list) else data.get("results", [])
            if not orders:
                pytest.skip("No placed order to cancel")

            resp = api_session.post(
                f"{BASE_URL}/orders/{orders[0]['id']}/cancel/",
                headers=customer_headers,
                json={},
            )
            assert resp.status_code == 400


@pytest.mark.orders
class TestOrderStats:
    """Test cook order stats: GET /orders/stats/"""

    url = f"{BASE_URL}/orders/stats/"

    def test_cook_order_stats(self, api_session, cook_headers, issue_tracker):
        """Cook can view their order stats."""
        resp = api_session.get(self.url, headers=cook_headers)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Cook order stats endpoint fails",
                description=f"GET /orders/stats/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /orders/stats/",
            )
        assert resp.status_code == 200

    def test_customer_cannot_access_stats(self, api_session, customer_headers, issue_tracker):
        """Customer should not access cook stats."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code == 200:
            issue_tracker.add(
                title="Customer can access cook order stats",
                description="GET /orders/stats/ accessible by customer role",
                severity="MEDIUM",
                category="SECURITY",
                endpoint="GET /orders/stats/",
            )
        assert resp.status_code == 403


@pytest.mark.orders
class TestPickupVerification:
    """Test pickup verification: POST /orders/<id>/verify-pickup/ (Issue #51)"""

    def test_verify_pickup_endpoint_exists(self, api_session, cook_headers, issue_tracker):
        """Verify the pickup verification endpoint exists."""
        # Use a fake order ID just to check the endpoint responds (not 404 for the URL pattern)
        resp = api_session.post(
            f"{BASE_URL}/orders/00000000-0000-0000-0000-000000000000/verify-pickup/",
            headers=cook_headers,
            json={"pickup_code": "123456"},
        )
        # Should be 404 (order not found) not 405 (method not allowed) or 500
        if resp.status_code == 405:
            issue_tracker.add(
                title="Pickup verification endpoint not implemented",
                description="POST /orders/<id>/verify-pickup/ returns 405 Method Not Allowed",
                severity="HIGH",
                category="API",
                endpoint="POST /orders/<id>/verify-pickup/",
                related_tracker_issue="51",
            )
        if resp.status_code == 500:
            issue_tracker.add(
                title="Pickup verification endpoint crashes",
                description=f"POST /orders/<id>/verify-pickup/ returns 500: {resp.text[:200]}",
                severity="CRITICAL",
                category="API",
                endpoint="POST /orders/<id>/verify-pickup/",
                related_tracker_issue="51",
            )
        assert resp.status_code in [200, 400, 404]
