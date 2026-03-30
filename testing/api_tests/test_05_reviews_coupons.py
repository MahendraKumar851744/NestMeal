"""
Test Suite: Reviews & Coupons
=============================
Tests review CRUD, coupon validation, and coupon usage.
"""

import pytest
from conftest import BASE_URL


@pytest.mark.reviews
class TestReviews:
    """Test review endpoints: /reviews/"""

    url = f"{BASE_URL}/reviews/"

    def test_list_reviews_public(self, api_session, issue_tracker):
        """Reviews listing should be public."""
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Review listing fails",
                description=f"GET /reviews/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /reviews/",
            )
        assert resp.status_code == 200

    def test_review_has_required_fields(self, api_session, issue_tracker):
        """Reviews should have essential fields."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            data = resp.json()
            reviews = data if isinstance(data, list) else data.get("results", [])
            for review in reviews[:5]:
                for field in ["id", "rating"]:
                    if field not in review:
                        issue_tracker.add(
                            title=f"Review missing field: {field}",
                            description=f"Review record missing '{field}'",
                            severity="LOW",
                            category="API",
                            endpoint="GET /reviews/",
                        )

    def test_create_review_requires_auth(self, api_session, issue_tracker):
        """Creating a review should require authentication."""
        resp = api_session.post(self.url, json={
            "order": "00000000-0000-0000-0000-000000000000",
            "rating": 5,
            "comment": "Great food!",
        })
        assert resp.status_code == 401

    def test_create_review_as_cook_forbidden(self, api_session, cook_headers, issue_tracker):
        """Cook should not be able to create reviews (customer-only)."""
        resp = api_session.post(self.url, headers=cook_headers, json={
            "order": "00000000-0000-0000-0000-000000000000",
            "rating": 5,
            "comment": "Self-review attempt",
        })
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Cook can create reviews (customer-only)",
                description="POST /reviews/ succeeds for cook role",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /reviews/",
            )
        assert resp.status_code in [400, 403]

    def test_review_rating_validation(self, api_session, customer_headers, issue_tracker):
        """Review rating should be 1-5."""
        for invalid_rating in [0, -1, 6, 100]:
            resp = api_session.post(self.url, headers=customer_headers, json={
                "order": "00000000-0000-0000-0000-000000000000",
                "rating": invalid_rating,
                "comment": "Invalid rating test",
            })
            if resp.status_code in [200, 201]:
                issue_tracker.add(
                    title=f"Review accepts invalid rating: {invalid_rating}",
                    description=f"POST /reviews/ accepts rating={invalid_rating} (should be 1-5)",
                    severity="MEDIUM",
                    category="LOGIC",
                    endpoint="POST /reviews/",
                )

    def test_review_filter_by_cook(self, api_session, issue_tracker):
        """Filter reviews by cook."""
        cooks_resp = api_session.get(f"{BASE_URL}/accounts/cooks/")
        if cooks_resp.status_code == 200:
            data = cooks_resp.json()
            cooks = data if isinstance(data, list) else data.get("results", [])
            if cooks:
                resp = api_session.get(self.url, params={"cook": cooks[0]["id"]})
                assert resp.status_code == 200


@pytest.mark.coupons
class TestCoupons:
    """Test coupon endpoints: /coupons/"""

    url = f"{BASE_URL}/coupons/"

    def test_list_coupons_public(self, api_session, issue_tracker):
        """Coupon listing should be public."""
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Coupon listing fails",
                description=f"GET /coupons/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /coupons/",
            )
        assert resp.status_code == 200

    def test_coupon_has_required_fields(self, api_session, issue_tracker):
        """Coupons should have essential fields."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            data = resp.json()
            coupons = data if isinstance(data, list) else data.get("results", [])
            for coupon in coupons[:3]:
                for field in ["id", "code", "discount_type", "discount_value", "is_active"]:
                    if field not in coupon:
                        issue_tracker.add(
                            title=f"Coupon missing field: {field}",
                            description=f"Coupon missing '{field}'",
                            severity="LOW",
                            category="API",
                            endpoint="GET /coupons/",
                        )

    def test_validate_coupon_requires_auth(self, api_session, issue_tracker):
        """Coupon validation should require auth."""
        resp = api_session.post(f"{self.url}validate/", json={"code": "TEST"})
        # Could be 401 or the route may not exist
        assert resp.status_code in [401, 404, 405]

    def test_create_coupon_as_customer_forbidden(self, api_session, customer_headers, issue_tracker):
        """Customer should not create coupons (admin-only)."""
        resp = api_session.post(self.url, headers=customer_headers, json={
            "code": "HACK100",
            "discount_type": "percentage",
            "discount_value": "100",
            "usage_limit_total": 999,
        })
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Customer can create coupons (admin-only)",
                description="POST /coupons/ succeeds for customer role - potential for unlimited discounts",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /coupons/",
            )
        assert resp.status_code in [400, 403]

    def test_create_coupon_as_cook_forbidden(self, api_session, cook_headers, issue_tracker):
        """Cook should not create coupons (admin-only)."""
        resp = api_session.post(self.url, headers=cook_headers, json={
            "code": "COOKHACK",
            "discount_type": "flat",
            "discount_value": "50",
        })
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Cook can create coupons (admin-only)",
                description="POST /coupons/ succeeds for cook role",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /coupons/",
            )
        assert resp.status_code in [400, 403]

    def test_expired_coupon_validation(self, api_session, customer_headers, issue_tracker):
        """Using expired coupon code should fail."""
        # Just test with a random code
        resp = api_session.post(
            f"{self.url}validate/",
            headers=customer_headers,
            json={"code": "EXPIRED_NONEXISTENT_CODE"},
        )
        # Should be 400 (invalid) or 404 (not found)
        assert resp.status_code in [400, 404, 405]
