"""
Test Suite: Security & Edge Cases
==================================
Cross-cutting security tests: IDOR, auth bypass, rate limits, CORS, headers.
"""

import pytest
import requests
from conftest import BASE_URL, TEST_CUSTOMERS, TEST_COOKS


@pytest.mark.security
class TestAuthorizationBypass:
    """Test for authorization bypass / IDOR vulnerabilities."""

    def test_customer_cannot_access_other_customer_orders(
        self, api_session, issue_tracker
    ):
        """Customer A should not see Customer B's orders via direct ID."""
        # Login as two different customers
        cred_a = TEST_CUSTOMERS[0]
        cred_b = TEST_CUSTOMERS[1]

        resp_a = api_session.post(f"{BASE_URL}/accounts/login/", json=cred_a)
        resp_b = api_session.post(f"{BASE_URL}/accounts/login/", json=cred_b)

        if resp_a.status_code != 200 or resp_b.status_code != 200:
            pytest.skip("Cannot login as two customers")

        headers_a = {"Authorization": f"Bearer {resp_a.json()['tokens']['access']}"}
        headers_b = {"Authorization": f"Bearer {resp_b.json()['tokens']['access']}"}

        # Get customer B's orders
        orders_b = api_session.get(f"{BASE_URL}/orders/", headers=headers_b)
        if orders_b.status_code == 200:
            data = orders_b.json()
            b_orders = data if isinstance(data, list) else data.get("results", [])
            if b_orders:
                order_id = b_orders[0]["id"]
                # Try to access B's order with A's token
                resp = api_session.get(
                    f"{BASE_URL}/orders/{order_id}/",
                    headers=headers_a,
                )
                if resp.status_code == 200:
                    issue_tracker.add(
                        title="IDOR: Customer can view another customer's order",
                        description=f"Customer A can access Customer B's order {order_id}",
                        severity="CRITICAL",
                        category="SECURITY",
                        endpoint="GET /orders/<id>/",
                        expected="403 or 404",
                        actual="200 OK with order data",
                    )
                    pytest.fail("IDOR vulnerability detected")

    def test_customer_cannot_access_cook_profile_management(
        self, api_session, customer_headers, issue_tracker
    ):
        """Customer should not access cook profile management endpoints."""
        resp = api_session.get(
            f"{BASE_URL}/accounts/cook-profiles/",
            headers=customer_headers,
        )
        if resp.status_code == 200:
            data = resp.json()
            profiles = data if isinstance(data, list) else data.get("results", [])
            if profiles:
                issue_tracker.add(
                    title="Customer can list cook profiles (admin/cook only)",
                    description="GET /accounts/cook-profiles/ returns data for customer role",
                    severity="HIGH",
                    category="SECURITY",
                    endpoint="GET /accounts/cook-profiles/",
                )

    def test_cook_cannot_access_customer_profiles(
        self, api_session, cook_headers, issue_tracker
    ):
        """Cook should not access customer profile management."""
        resp = api_session.get(
            f"{BASE_URL}/accounts/customer-profiles/",
            headers=cook_headers,
        )
        if resp.status_code == 200:
            data = resp.json()
            profiles = data if isinstance(data, list) else data.get("results", [])
            if profiles:
                issue_tracker.add(
                    title="Cook can list customer profiles",
                    description="GET /accounts/customer-profiles/ returns data for cook role",
                    severity="HIGH",
                    category="SECURITY",
                    endpoint="GET /accounts/customer-profiles/",
                )


@pytest.mark.security
class TestInputValidation:
    """Test input validation and edge cases."""

    def test_oversized_payload(self, api_session, customer_headers, issue_tracker):
        """API should reject extremely large payloads."""
        huge_string = "A" * 1_000_000
        resp = api_session.post(
            f"{BASE_URL}/orders/",
            headers=customer_headers,
            json={"special_instructions": huge_string},
        )
        if resp.status_code == 500:
            issue_tracker.add(
                title="Server crashes on oversized payload",
                description="1MB payload in special_instructions causes 500 error",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /orders/",
            )
        assert resp.status_code != 500

    def test_unicode_handling(self, api_session, customer_headers, issue_tracker):
        """API should handle unicode characters."""
        resp = api_session.put(
            f"{BASE_URL}/accounts/me/",
            headers=customer_headers,
            json={"full_name": "Tëst Üsér 测试 🍛"},
        )
        assert resp.status_code in [200, 204, 400]

    def test_null_values_in_required_fields(self, api_session, issue_tracker):
        """Registration with null values should fail gracefully."""
        resp = api_session.post(f"{BASE_URL}/accounts/register/", json={
            "email": None,
            "password": None,
            "full_name": None,
            "phone": None,
            "role": None,
        })
        assert resp.status_code == 400


@pytest.mark.security
class TestCORSAndHeaders:
    """Test security headers and CORS."""

    def test_cors_headers_present(self, api_session, issue_tracker):
        """Response should include CORS headers."""
        resp = api_session.options(
            f"{BASE_URL}/meals/",
            headers={"Origin": "http://localhost:8080"},
        )
        # In debug mode, CORS_ALLOW_ALL_ORIGINS=True, so this should work
        # but in production it should be restrictive
        if "access-control-allow-origin" not in resp.headers:
            issue_tracker.add(
                title="CORS headers missing",
                description="OPTIONS /meals/ does not return Access-Control-Allow-Origin",
                severity="LOW",
                category="SECURITY",
                endpoint="OPTIONS /meals/",
            )

    def test_sensitive_headers_not_exposed(self, api_session, issue_tracker):
        """Response should not expose server internals."""
        resp = api_session.get(f"{BASE_URL}/meals/")
        server_header = resp.headers.get("Server", "")
        if "Django" in server_header or "Python" in server_header:
            issue_tracker.add(
                title="Server version exposed in headers",
                description=f"Server header reveals: {server_header}",
                severity="LOW",
                category="SECURITY",
                endpoint="GET /meals/",
                expected="Generic or no Server header",
                actual=f"Server: {server_header}",
            )


@pytest.mark.security
class TestTokenSecurity:
    """Test JWT token security."""

    def test_expired_token_rejected(self, api_session, issue_tracker):
        """Using a manually crafted expired-looking token should fail."""
        resp = api_session.get(
            f"{BASE_URL}/accounts/me/",
            headers={"Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjF9.invalid"},
        )
        assert resp.status_code == 401

    def test_no_auth_header(self, api_session, issue_tracker):
        """Protected endpoints should return 401 without auth header."""
        endpoints = [
            "/accounts/me/",
            "/orders/",
            "/payments/",
            "/notifications/",
        ]
        for ep in endpoints:
            resp = api_session.get(f"{BASE_URL}{ep}")
            if resp.status_code != 401:
                issue_tracker.add(
                    title=f"Protected endpoint accessible without auth: {ep}",
                    description=f"GET {ep} returns {resp.status_code} without Authorization header",
                    severity="CRITICAL",
                    category="SECURITY",
                    endpoint=f"GET {ep}",
                )
            assert resp.status_code == 401, f"{ep} returned {resp.status_code}"

    def test_malformed_auth_header(self, api_session, issue_tracker):
        """Malformed Authorization header should not crash server."""
        for bad_header in [
            "Bearer",
            "Bearer ",
            "Basic dGVzdDp0ZXN0",
            "InvalidScheme token123",
            "Bearer " + "a" * 10000,
        ]:
            resp = api_session.get(
                f"{BASE_URL}/accounts/me/",
                headers={"Authorization": bad_header},
            )
            if resp.status_code == 500:
                issue_tracker.add(
                    title=f"Server crash on malformed auth header",
                    description=f"Authorization: '{bad_header[:50]}...' causes 500",
                    severity="HIGH",
                    category="SECURITY",
                    endpoint="GET /accounts/me/",
                )
            assert resp.status_code != 500


@pytest.mark.security
class TestAPIConsistency:
    """Test API responses are consistent and well-formed."""

    def test_404_returns_json(self, api_session, issue_tracker):
        """404 responses should return JSON, not HTML."""
        resp = api_session.get(f"{BASE_URL}/nonexistent-endpoint/")
        content_type = resp.headers.get("Content-Type", "")
        if "text/html" in content_type and resp.status_code == 404:
            issue_tracker.add(
                title="404 returns HTML instead of JSON",
                description="API returns HTML error page for 404 instead of JSON response",
                severity="LOW",
                category="API",
                endpoint="GET /nonexistent/",
                expected="JSON error response",
                actual="HTML error page",
            )

    def test_method_not_allowed_returns_json(self, api_session, issue_tracker):
        """405 responses should return JSON."""
        resp = api_session.delete(f"{BASE_URL}/meals/")
        if resp.status_code == 405:
            content_type = resp.headers.get("Content-Type", "")
            if "text/html" in content_type:
                issue_tracker.add(
                    title="405 returns HTML instead of JSON",
                    description="API returns HTML for Method Not Allowed",
                    severity="LOW",
                    category="API",
                    endpoint="DELETE /meals/",
                )

    def test_all_endpoints_respond(self, api_session, issue_tracker):
        """Verify all major endpoints are responsive (not 500)."""
        public_endpoints = [
            ("GET", "/meals/"),
            ("GET", "/meals/featured/"),
            ("GET", "/meals/available-now/"),
            ("GET", "/accounts/cooks/"),
            ("GET", "/reviews/"),
            ("GET", "/coupons/"),
        ]
        for method, ep in public_endpoints:
            resp = api_session.request(method, f"{BASE_URL}{ep}")
            if resp.status_code == 500:
                issue_tracker.add(
                    title=f"Endpoint crashes: {method} {ep}",
                    description=f"{method} {ep} returns 500: {resp.text[:200]}",
                    severity="CRITICAL",
                    category="API",
                    endpoint=f"{method} {ep}",
                )
            assert resp.status_code != 500, f"{method} {ep} returned 500"
