"""
Test Suite: Delivery, Stories, Notifications
=============================================
Tests delivery zones/slots/fee calculation, stories CRUD, notifications.
"""

import pytest
from conftest import BASE_URL


@pytest.mark.delivery
class TestDeliveryZones:
    """Test delivery zone CRUD: /delivery-zones/"""

    url = f"{BASE_URL}/delivery-zones/"

    def test_list_delivery_zones(self, api_session, issue_tracker):
        """List delivery zones."""
        resp = api_session.get(self.url)
        assert resp.status_code in [200, 401]

    def test_create_zone_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook can create delivery zones."""
        payload = {
            "name": "Test Zone",
            "zone_type": "radius",
            "radius_km": "5.00",
            "center_lat": "-37.8136276",
            "center_lng": "144.9630576",
        }
        resp = api_session.post(self.url, headers=cook_headers, json=payload)
        if resp.status_code not in [200, 201, 400]:
            issue_tracker.add(
                title="Delivery zone creation fails",
                description=f"POST /delivery-zones/ returned {resp.status_code}: {resp.text[:200]}",
                severity="MEDIUM",
                category="API",
                endpoint="POST /delivery-zones/",
            )
        assert resp.status_code in [200, 201, 400]

    def test_create_zone_as_customer_forbidden(self, api_session, customer_headers, issue_tracker):
        """Customer should not create delivery zones."""
        resp = api_session.post(self.url, headers=customer_headers, json={
            "name": "Hack Zone",
            "zone_type": "radius",
            "radius_km": "5.00",
        })
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Customer can create delivery zones (cook-only)",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /delivery-zones/",
                description="POST /delivery-zones/ succeeds for customer",
            )
        assert resp.status_code in [400, 403]


@pytest.mark.delivery
class TestDeliverySlots:
    """Test delivery slot CRUD: /delivery-slots/"""

    url = f"{BASE_URL}/delivery-slots/"

    def test_list_delivery_slots(self, api_session, issue_tracker):
        """List delivery slots."""
        resp = api_session.get(self.url)
        assert resp.status_code in [200, 401]

    def test_delivery_slots_have_dates(self, api_session, issue_tracker):
        """Delivery slots should have valid dates."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            data = resp.json()
            slots = data if isinstance(data, list) else data.get("results", [])
            from datetime import date
            today = date.today().isoformat()
            past_slots = [s for s in slots if s.get("date", today) < today and s.get("is_available")]
            if past_slots:
                issue_tracker.add(
                    title="Past delivery slots still marked as available",
                    description=f"{len(past_slots)} slots with past dates are still available",
                    severity="HIGH",
                    category="LOGIC",
                    endpoint="GET /delivery-slots/",
                    related_tracker_issue="20",
                    expected="Past slots should be unavailable",
                    actual=f"{len(past_slots)} past slots still available",
                )


@pytest.mark.delivery
class TestDeliveryFeeCalculation:
    """Test delivery fee calculation: POST /delivery/calculate-fee/"""

    url = f"{BASE_URL}/delivery/calculate-fee/"

    def test_calculate_fee(self, api_session, issue_tracker):
        """Calculate delivery fee with valid coordinates."""
        # Get a cook first
        cooks_resp = api_session.get(f"{BASE_URL}/accounts/cooks/")
        if cooks_resp.status_code == 200:
            data = cooks_resp.json()
            cooks = data if isinstance(data, list) else data.get("results", [])
            if cooks:
                payload = {
                    "cook_id": cooks[0]["id"],
                    "delivery_lat": -37.8136276,
                    "delivery_lng": 144.9630576,
                }
                resp = api_session.post(self.url, json=payload)
                if resp.status_code not in [200, 400]:
                    issue_tracker.add(
                        title="Delivery fee calculation fails",
                        description=f"POST /delivery/calculate-fee/ returned {resp.status_code}",
                        severity="MEDIUM",
                        category="API",
                        endpoint="POST /delivery/calculate-fee/",
                    )
                assert resp.status_code in [200, 400]

    def test_calculate_fee_missing_coords(self, api_session, issue_tracker):
        """Fee calculation without coordinates should fail."""
        resp = api_session.post(self.url, json={})
        assert resp.status_code == 400


@pytest.mark.stories
class TestStories:
    """Test story endpoints: /stories/"""

    def test_story_feed(self, api_session, customer_headers, issue_tracker):
        """Customer can view story feed."""
        resp = api_session.get(f"{BASE_URL}/stories/feed/", headers=customer_headers)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Story feed fails",
                description=f"GET /stories/feed/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /stories/feed/",
            )
        assert resp.status_code == 200

    def test_story_feed_unauthenticated(self, api_session, issue_tracker):
        """Story feed without auth."""
        resp = api_session.get(f"{BASE_URL}/stories/feed/")
        # May or may not require auth
        assert resp.status_code in [200, 401]

    def test_my_stories_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook can view their own stories."""
        resp = api_session.get(f"{BASE_URL}/stories/my/", headers=cook_headers)
        assert resp.status_code == 200

    def test_create_story_requires_auth(self, api_session, issue_tracker):
        """Story creation requires auth."""
        resp = api_session.post(f"{BASE_URL}/stories/", json={"caption": "Test"})
        assert resp.status_code == 401

    def test_create_story_as_customer_forbidden(self, api_session, customer_headers, issue_tracker):
        """Customer should not create stories (cook-only)."""
        resp = api_session.post(
            f"{BASE_URL}/stories/",
            headers=customer_headers,
            json={"caption": "Customer story attempt"},
        )
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Customer can create stories (cook-only)",
                description="POST /stories/ succeeds for customer role",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /stories/",
            )
        assert resp.status_code in [400, 403]

    def test_cook_stories_by_id(self, api_session, issue_tracker):
        """View stories for a specific cook."""
        cooks_resp = api_session.get(f"{BASE_URL}/accounts/cooks/")
        if cooks_resp.status_code == 200:
            data = cooks_resp.json()
            cooks = data if isinstance(data, list) else data.get("results", [])
            if cooks:
                resp = api_session.get(f"{BASE_URL}/stories/cook/{cooks[0]['id']}/")
                assert resp.status_code == 200


@pytest.mark.notifications
class TestNotifications:
    """Test notification endpoints: /notifications/"""

    url = f"{BASE_URL}/notifications/"

    def test_list_notifications_authenticated(self, api_session, customer_headers, issue_tracker):
        """Customer can list their notifications."""
        resp = api_session.get(self.url, headers=customer_headers)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Notification listing fails",
                description=f"GET /notifications/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /notifications/",
            )
        assert resp.status_code == 200

    def test_notifications_unauthenticated(self, api_session, issue_tracker):
        """Notifications require auth."""
        resp = api_session.get(self.url)
        assert resp.status_code == 401
