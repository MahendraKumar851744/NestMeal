"""
Test Suite: Authentication & User Management
=============================================
Tests registration, login, JWT tokens, OTP, profile, password change.
"""

import pytest
import requests
import time

from conftest import (
    BASE_URL, TEST_CUSTOMERS, TEST_COOKS, TEST_NEW_USER, MOCK_OTP,
)


@pytest.mark.auth
@pytest.mark.smoke
class TestRegistration:
    """Test user registration endpoint: POST /accounts/register/"""

    url = f"{BASE_URL}/accounts/register/"

    def test_register_customer_success(self, api_session, issue_tracker):
        """Register a new customer with valid data."""
        payload = {
            "email": f"newcust_{int(time.time())}@test.com",
            "password": "SecurePass@123",
            "password_confirm": "SecurePass@123",
            "full_name": "New Customer",
            "phone": "+61400111222",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code != 201:
            issue_tracker.add(
                title="Customer registration fails",
                description=f"POST /accounts/register/ returned {resp.status_code}: {resp.text}",
                severity="CRITICAL",
                category="API",
                endpoint="POST /accounts/register/",
                expected="201 Created with user + tokens",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code == 201, f"Expected 201, got {resp.status_code}"
        data = resp.json()
        assert "tokens" in data
        assert "access" in data["tokens"]
        assert "refresh" in data["tokens"]
        assert data["user"]["role"] == "customer"

    def test_register_cook_success(self, api_session, issue_tracker):
        """Register a new cook with valid data."""
        payload = {
            "email": f"newcook_{int(time.time())}@test.com",
            "password": "SecurePass@123",
            "password_confirm": "SecurePass@123",
            "full_name": "New Cook",
            "phone": "+61400333444",
            "role": "cook",
            "display_name": "New Test Kitchen",
            "kitchen_street": "50 Test Ave",
            "kitchen_city": "Sydney",
            "kitchen_state": "NSW",
            "kitchen_zip": "2000",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code != 201:
            issue_tracker.add(
                title="Cook registration fails",
                description=f"POST /accounts/register/ returned {resp.status_code}: {resp.text}",
                severity="CRITICAL",
                category="API",
                endpoint="POST /accounts/register/",
                expected="201 Created",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code == 201
        data = resp.json()
        assert data["user"]["role"] == "cook"

    def test_register_duplicate_email(self, api_session, issue_tracker):
        """Registration with existing email should fail."""
        payload = {
            "email": TEST_CUSTOMERS[0]["email"],
            "password": "AnyPass@123",
            "full_name": "Duplicate",
            "phone": "+61400000001",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code == 201:
            issue_tracker.add(
                title="Duplicate email registration allowed",
                description="Registration succeeds with an already-registered email",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /accounts/register/",
                expected="400 with email uniqueness error",
                actual="201 Created (duplicate allowed)",
            )
        assert resp.status_code == 400

    def test_register_missing_fields(self, api_session, issue_tracker):
        """Registration with missing required fields should fail."""
        payload = {"email": "incomplete@test.com"}
        resp = api_session.post(self.url, json=payload)
        assert resp.status_code == 400

    def test_register_invalid_email(self, api_session, issue_tracker):
        """Registration with invalid email format should fail."""
        payload = {
            "email": "not-an-email",
            "password": "SecurePass@123",
            "full_name": "Bad Email",
            "phone": "+61400000001",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        assert resp.status_code == 400

    def test_register_weak_password(self, api_session, issue_tracker):
        """Registration with a very weak password."""
        payload = {
            "email": f"weakpw_{int(time.time())}@test.com",
            "password": "123",
            "password_confirm": "123",
            "full_name": "Weak PW User",
            "phone": "+61400000001",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code == 201:
            issue_tracker.add(
                title="Weak password accepted during registration",
                description="Password '123' was accepted. No password strength validation.",
                severity="HIGH",
                category="SECURITY",
                endpoint="POST /accounts/register/",
                expected="400 with password validation error",
                actual="201 Created with weak password",
            )
        # Note: we report but don't assert, as the app may not enforce password rules

    def test_register_invalid_role(self, api_session, issue_tracker):
        """Registration with invalid role should fail."""
        payload = {
            "email": f"badrole_{int(time.time())}@test.com",
            "password": "SecurePass@123",
            "password_confirm": "SecurePass@123",
            "full_name": "Bad Role",
            "phone": "+61400000001",
            "role": "superadmin",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code == 201:
            issue_tracker.add(
                title="Invalid role 'superadmin' accepted",
                description="Registration allows arbitrary roles",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /accounts/register/",
                expected="400 with invalid role error",
                actual="201 Created",
            )
        assert resp.status_code == 400

    def test_register_sql_injection_in_email(self, api_session, issue_tracker):
        """Test SQL injection attempt in email field."""
        payload = {
            "email": "test@test.com'; DROP TABLE users;--",
            "password": "SecurePass@123",
            "password_confirm": "SecurePass@123",
            "full_name": "SQL Inject",
            "phone": "+61400000001",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        # Should fail validation, not crash
        assert resp.status_code in [400, 422], f"SQL injection may be vulnerable: {resp.status_code}"

    def test_register_xss_in_name(self, api_session, issue_tracker):
        """Test XSS attempt in full_name field."""
        payload = {
            "email": f"xss_{int(time.time())}@test.com",
            "password": "SecurePass@123",
            "password_confirm": "SecurePass@123",
            "full_name": '<script>alert("xss")</script>',
            "phone": "+61400000001",
            "role": "customer",
        }
        resp = api_session.post(self.url, json=payload)
        if resp.status_code == 201:
            data = resp.json()
            if "<script>" in data.get("user", {}).get("full_name", ""):
                issue_tracker.add(
                    title="XSS payload stored in full_name",
                    description="Script tags stored without sanitization in user name",
                    severity="HIGH",
                    category="SECURITY",
                    endpoint="POST /accounts/register/",
                    expected="Sanitized or rejected",
                    actual="Script tags stored as-is",
                )


@pytest.mark.auth
@pytest.mark.smoke
class TestLogin:
    """Test login endpoint: POST /accounts/login/"""

    url = f"{BASE_URL}/accounts/login/"

    def test_customer_login_success(self, api_session, issue_tracker):
        """Login with valid customer credentials."""
        for cred in TEST_CUSTOMERS:
            resp = api_session.post(self.url, json=cred)
            if resp.status_code == 200:
                data = resp.json()
                assert "tokens" in data
                assert "user" in data
                assert data["user"]["role"] == "customer"
                return
        issue_tracker.add(
            title="No seed customer can login",
            description=f"Tried {len(TEST_CUSTOMERS)} customers, all failed",
            severity="CRITICAL",
            category="API",
            endpoint="POST /accounts/login/",
            expected="200 with tokens",
            actual="All login attempts failed",
        )
        pytest.fail("No seed customer could login")

    def test_cook_login_success(self, api_session, issue_tracker):
        """Login with valid cook credentials."""
        for cred in TEST_COOKS:
            resp = api_session.post(self.url, json=cred)
            if resp.status_code == 200:
                data = resp.json()
                assert data["user"]["role"] == "cook"
                return
        issue_tracker.add(
            title="No seed cook can login",
            description=f"Tried {len(TEST_COOKS)} cooks, all failed",
            severity="CRITICAL",
            category="API",
            endpoint="POST /accounts/login/",
            expected="200 with tokens",
            actual="All login attempts failed",
        )
        pytest.fail("No seed cook could login")

    def test_login_wrong_password(self, api_session, issue_tracker):
        """Login with incorrect password should fail."""
        resp = api_session.post(self.url, json={
            "email": TEST_CUSTOMERS[0]["email"],
            "password": "WrongPassword@999",
        })
        assert resp.status_code in [400, 401]

    def test_login_nonexistent_user(self, api_session, issue_tracker):
        """Login with non-existent email should fail."""
        resp = api_session.post(self.url, json={
            "email": "nonexistent@nobody.com",
            "password": "AnyPass@123",
        })
        assert resp.status_code in [400, 401]

    def test_login_empty_body(self, api_session, issue_tracker):
        """Login with empty body should return 400."""
        resp = api_session.post(self.url, json={})
        assert resp.status_code == 400

    def test_login_returns_jwt_format(self, api_session, issue_tracker):
        """JWT tokens should have 3 parts (header.payload.signature)."""
        resp = api_session.post(self.url, json=TEST_CUSTOMERS[0])
        if resp.status_code == 200:
            tokens = resp.json()["tokens"]
            access = tokens["access"]
            parts = access.split(".")
            if len(parts) != 3:
                issue_tracker.add(
                    title="Access token not valid JWT format",
                    description=f"Token has {len(parts)} parts instead of 3",
                    severity="HIGH",
                    category="SECURITY",
                    endpoint="POST /accounts/login/",
                    expected="JWT with 3 dot-separated parts",
                    actual=f"Token with {len(parts)} parts",
                )
            assert len(parts) == 3


@pytest.mark.auth
class TestTokenRefresh:
    """Test JWT token refresh: POST /accounts/token/refresh/"""

    url = f"{BASE_URL}/accounts/token/refresh/"

    def test_refresh_token_success(self, api_session, customer_auth, issue_tracker):
        """Refresh token should return a new access token."""
        resp = api_session.post(self.url, json={
            "refresh": customer_auth["refresh"]
        })
        if resp.status_code != 200:
            issue_tracker.add(
                title="Token refresh fails",
                description=f"POST /token/refresh/ returned {resp.status_code}",
                severity="HIGH",
                category="API",
                endpoint="POST /accounts/token/refresh/",
                expected="200 with new access token",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code == 200
        data = resp.json()
        assert "access" in data

    def test_refresh_with_invalid_token(self, api_session, issue_tracker):
        """Refresh with invalid token should fail."""
        resp = api_session.post(self.url, json={"refresh": "invalid.token.here"})
        assert resp.status_code == 401

    def test_refresh_with_empty_body(self, api_session, issue_tracker):
        """Refresh with no token should return 400."""
        resp = api_session.post(self.url, json={})
        assert resp.status_code == 400


@pytest.mark.auth
class TestUserProfile:
    """Test user profile: GET/PUT /accounts/me/"""

    url = f"{BASE_URL}/accounts/me/"

    def test_get_profile_authenticated(self, api_session, customer_auth, issue_tracker):
        """Get profile of authenticated user."""
        resp = api_session.get(self.url, headers=customer_auth["headers"])
        if resp.status_code != 200:
            issue_tracker.add(
                title="GET /me/ fails for authenticated user",
                description=f"Status {resp.status_code}: {resp.text[:200]}",
                severity="HIGH",
                category="API",
                endpoint="GET /accounts/me/",
                expected="200 with user profile",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code == 200
        data = resp.json()
        assert "email" in data
        assert "full_name" in data
        assert "role" in data

    def test_get_profile_unauthenticated(self, api_session, issue_tracker):
        """Get profile without auth should fail."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            issue_tracker.add(
                title="Profile accessible without authentication",
                description="GET /me/ returns 200 without JWT token",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="GET /accounts/me/",
                expected="401 Unauthorized",
                actual="200 OK - profile data exposed",
            )
        assert resp.status_code == 401

    def test_update_profile_name(self, api_session, customer_auth, issue_tracker):
        """Update user's full_name."""
        resp = api_session.put(
            self.url,
            headers=customer_auth["headers"],
            json={"full_name": "Updated Name"},
        )
        if resp.status_code not in [200, 204]:
            issue_tracker.add(
                title="Profile update fails",
                description=f"PUT /me/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="PUT /accounts/me/",
                expected="200",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code in [200, 204]

    def test_update_profile_cannot_change_role(self, api_session, customer_auth, issue_tracker):
        """User should not be able to change their role via profile update."""
        resp = api_session.put(
            self.url,
            headers=customer_auth["headers"],
            json={"role": "admin"},
        )
        # Even if 200, role should not have changed
        if resp.status_code == 200:
            check = api_session.get(self.url, headers=customer_auth["headers"])
            if check.status_code == 200 and check.json().get("role") == "admin":
                issue_tracker.add(
                    title="User can escalate to admin via profile update",
                    description="PUT /me/ with role=admin changes user role to admin",
                    severity="CRITICAL",
                    category="SECURITY",
                    endpoint="PUT /accounts/me/",
                    expected="Role field ignored or rejected",
                    actual="Role changed to admin",
                )
                pytest.fail("CRITICAL: Role escalation possible")


@pytest.mark.auth
class TestChangePassword:
    """Test password change: POST /accounts/me/change-password/"""

    url = f"{BASE_URL}/accounts/me/change-password/"

    def test_change_password_unauthenticated(self, api_session, issue_tracker):
        """Should require authentication."""
        resp = api_session.post(self.url, json={
            "old_password": "Test@1234",
            "new_password": "NewPass@5678",
        })
        assert resp.status_code == 401


@pytest.mark.auth
class TestOTP:
    """Test OTP endpoints: POST /accounts/otp/send|verify|resend/"""

    def test_send_otp(self, api_session, issue_tracker):
        """Send OTP to a phone number."""
        resp = api_session.post(f"{BASE_URL}/accounts/otp/send/", json={
            "phone": "+61400999888",
        })
        if resp.status_code not in [200, 429]:
            issue_tracker.add(
                title="OTP send fails",
                description=f"POST /otp/send/ returned {resp.status_code}: {resp.text[:200]}",
                severity="HIGH",
                category="API",
                endpoint="POST /accounts/otp/send/",
                expected="200 OK",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code in [200, 429]  # 429 if rate limited

    def test_verify_mock_otp(self, api_session, issue_tracker):
        """Verify with mock OTP code '1234'."""
        resp = api_session.post(f"{BASE_URL}/accounts/otp/verify/", json={
            "phone": "+61400999888",
            "otp": MOCK_OTP,
        })
        if resp.status_code != 200:
            issue_tracker.add(
                title="Mock OTP verification fails",
                description=f"POST /otp/verify/ with '1234' returned {resp.status_code}",
                severity="HIGH",
                category="API",
                endpoint="POST /accounts/otp/verify/",
                expected="200 with verified=true",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code == 200

    def test_verify_wrong_otp(self, api_session, issue_tracker):
        """Verify with wrong OTP should fail."""
        resp = api_session.post(f"{BASE_URL}/accounts/otp/verify/", json={
            "phone": "+61400999888",
            "otp": "9999",
        })
        assert resp.status_code == 400

    def test_otp_rate_limiting(self, api_session, issue_tracker):
        """Sending OTP twice quickly should be rate-limited."""
        phone = "+61400777666"
        api_session.post(f"{BASE_URL}/accounts/otp/send/", json={"phone": phone})
        resp2 = api_session.post(f"{BASE_URL}/accounts/otp/send/", json={"phone": phone})
        if resp2.status_code == 200:
            issue_tracker.add(
                title="OTP rate limiting not working",
                description="Two OTP requests in quick succession both succeed",
                severity="MEDIUM",
                category="SECURITY",
                endpoint="POST /accounts/otp/send/",
                expected="429 Too Many Requests on second call",
                actual="200 OK",
            )
        assert resp2.status_code == 429


@pytest.mark.auth
class TestAddresses:
    """Test address CRUD: /accounts/addresses/"""

    url = f"{BASE_URL}/accounts/addresses/"

    def test_list_addresses(self, api_session, customer_headers, issue_tracker):
        """List user addresses."""
        resp = api_session.get(self.url, headers=customer_headers)
        assert resp.status_code == 200

    def test_create_address(self, api_session, customer_headers, issue_tracker):
        """Create a new address."""
        payload = {
            "label": "Test Address",
            "street": "123 Test St",
            "city": "Melbourne",
            "state": "VIC",
            "zip_code": "3000",
            "latitude": -37.8136276,
            "longitude": 144.9630576,
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code not in [201, 200]:
            issue_tracker.add(
                title="Address creation fails",
                description=f"POST /addresses/ returned {resp.status_code}: {resp.text[:200]}",
                severity="MEDIUM",
                category="API",
                endpoint="POST /accounts/addresses/",
                expected="201 Created",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code in [200, 201]

    def test_addresses_unauthenticated(self, api_session, issue_tracker):
        """Addresses should not be accessible without auth."""
        resp = api_session.get(self.url)
        assert resp.status_code == 401


@pytest.mark.auth
class TestCooksPublic:
    """Test public cook listing: GET /accounts/cooks/"""

    url = f"{BASE_URL}/accounts/cooks/"

    def test_list_cooks_public(self, api_session, issue_tracker):
        """Public cook listing should work without auth."""
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Public cook listing fails",
                description=f"GET /accounts/cooks/ returned {resp.status_code}",
                severity="HIGH",
                category="API",
                endpoint="GET /accounts/cooks/",
                expected="200 with list of cooks",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code == 200
        data = resp.json()
        # Should be a list or paginated response
        assert isinstance(data, (list, dict))

    def test_list_cooks_search(self, api_session, issue_tracker):
        """Search cooks by name."""
        resp = api_session.get(self.url, params={"search": "priya"})
        assert resp.status_code == 200

    def test_cook_detail_public(self, api_session, issue_tracker):
        """Get a single cook's public profile."""
        # First get the list to find a cook ID
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            data = resp.json()
            cooks = data if isinstance(data, list) else data.get("results", [])
            if cooks:
                cook_id = cooks[0]["id"]
                detail_resp = api_session.get(f"{BASE_URL}/accounts/cooks/{cook_id}/")
                assert detail_resp.status_code == 200


@pytest.mark.auth
class TestFollow:
    """Test follow/unfollow: POST /accounts/cooks/<id>/follow/"""

    def test_follow_requires_auth(self, api_session, issue_tracker):
        """Follow endpoint requires customer authentication."""
        # Use a fake UUID
        resp = api_session.post(
            f"{BASE_URL}/accounts/cooks/00000000-0000-0000-0000-000000000000/follow/"
        )
        assert resp.status_code == 401

    def test_follow_cook(self, api_session, customer_headers, issue_tracker):
        """Customer can follow a cook."""
        # Get a cook ID first
        cooks_resp = api_session.get(f"{BASE_URL}/accounts/cooks/")
        if cooks_resp.status_code == 200:
            data = cooks_resp.json()
            cooks = data if isinstance(data, list) else data.get("results", [])
            if cooks:
                cook_id = cooks[0]["id"]
                resp = api_session.post(
                    f"{BASE_URL}/accounts/cooks/{cook_id}/follow/",
                    headers=customer_headers,
                )
                assert resp.status_code in [200, 201]

    def test_list_following(self, api_session, customer_headers, issue_tracker):
        """Customer can list followed cooks."""
        resp = api_session.get(
            f"{BASE_URL}/accounts/me/following/",
            headers=customer_headers,
        )
        assert resp.status_code == 200
