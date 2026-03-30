"""
Test Suite: Meals, Meal Images, Meal Extras, Pickup Slots
=========================================================
Tests all meal-related CRUD, filtering, images, extras, and slots.
"""

import pytest
import requests
import time
import os

from conftest import BASE_URL


@pytest.mark.meals
@pytest.mark.smoke
class TestMealListing:
    """Test meal listing: GET /meals/"""

    url = f"{BASE_URL}/meals/"

    def test_list_meals_public(self, api_session, issue_tracker):
        """Meal listing should work without auth."""
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Meal listing fails",
                description=f"GET /meals/ returned {resp.status_code}",
                severity="CRITICAL",
                category="API",
                endpoint="GET /meals/",
                expected="200 with meals list",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data, (list, dict))

    def test_meals_pagination(self, api_session, issue_tracker):
        """Meals should be paginated (20 per page)."""
        resp = api_session.get(self.url, params={"page": 1})
        assert resp.status_code == 200
        data = resp.json()
        if isinstance(data, dict):
            assert "results" in data or "count" in data or isinstance(data.get("results"), list)

    def test_meals_filter_by_category(self, api_session, issue_tracker):
        """Filter meals by category."""
        for cat in ["breakfast", "lunch", "dinner", "snack", "dessert"]:
            resp = api_session.get(self.url, params={"category": cat})
            assert resp.status_code == 200

    def test_meals_filter_by_meal_type(self, api_session, issue_tracker):
        """Filter meals by veg/non-veg."""
        for mtype in ["veg", "non_veg", "egg"]:
            resp = api_session.get(self.url, params={"meal_type": mtype})
            assert resp.status_code == 200

    def test_meals_filter_by_spice_level(self, api_session, issue_tracker):
        """Filter meals by spice level."""
        for spice in ["mild", "medium", "spicy", "extra_spicy"]:
            resp = api_session.get(self.url, params={"spice_level": spice})
            assert resp.status_code == 200

    def test_meals_search(self, api_session, issue_tracker):
        """Search meals by title."""
        resp = api_session.get(self.url, params={"search": "biryani"})
        assert resp.status_code == 200

    def test_meals_ordering(self, api_session, issue_tracker):
        """Order meals by price, rating."""
        for order in ["price", "-price", "avg_rating", "-avg_rating"]:
            resp = api_session.get(self.url, params={"ordering": order})
            assert resp.status_code == 200

    def test_meals_filter_available_only(self, api_session, issue_tracker):
        """Filter for available meals only."""
        resp = api_session.get(self.url, params={"is_available": "true"})
        assert resp.status_code == 200
        data = resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])
        for meal in meals:
            if not meal.get("is_available", True):
                issue_tracker.add(
                    title="Unavailable meals returned when filtering is_available=true",
                    description=f"Meal '{meal.get('title')}' has is_available=False but was returned",
                    severity="HIGH",
                    category="LOGIC",
                    endpoint="GET /meals/?is_available=true",
                    related_tracker_issue="42",
                    expected="Only available meals",
                    actual="Unavailable meal in results",
                )

    def test_meals_have_required_fields(self, api_session, issue_tracker):
        """Each meal should have essential fields."""
        resp = api_session.get(self.url)
        assert resp.status_code == 200
        data = resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])
        required_fields = [
            "id", "title", "price", "category", "meal_type", "is_available",
        ]
        for meal in meals[:5]:
            for field in required_fields:
                if field not in meal:
                    issue_tracker.add(
                        title=f"Meal missing required field: {field}",
                        description=f"Meal '{meal.get('title', 'unknown')}' missing '{field}'",
                        severity="MEDIUM",
                        category="API",
                        endpoint="GET /meals/",
                    )

    def test_meal_effective_price_with_discount(self, api_session, issue_tracker):
        """Meals with discount should show effective_price less than price."""
        resp = api_session.get(self.url)
        assert resp.status_code == 200
        data = resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])
        for meal in meals:
            discount = float(meal.get("discount_percentage", 0))
            if discount > 0:
                price = float(meal.get("price", 0))
                effective = float(meal.get("effective_price", price))
                expected_effective = round(price * (1 - discount / 100), 2)
                if abs(effective - expected_effective) > 0.02:
                    issue_tracker.add(
                        title=f"Effective price calculation wrong for '{meal.get('title')}'",
                        description=f"Price={price}, Discount={discount}%, Expected={expected_effective}, Got={effective}",
                        severity="HIGH",
                        category="LOGIC",
                        endpoint="GET /meals/",
                    )


@pytest.mark.meals
class TestFeaturedMeals:
    """Test featured meals: GET /meals/featured/"""

    url = f"{BASE_URL}/meals/featured/"

    def test_featured_meals(self, api_session, issue_tracker):
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Featured meals endpoint fails",
                description=f"GET /meals/featured/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /meals/featured/",
            )
        assert resp.status_code == 200

    def test_featured_meals_all_featured(self, api_session, issue_tracker):
        """All returned meals should be marked as featured."""
        resp = api_session.get(self.url)
        if resp.status_code == 200:
            data = resp.json()
            meals = data if isinstance(data, list) else data.get("results", [])
            for meal in meals:
                if not meal.get("is_featured", True):
                    issue_tracker.add(
                        title="Non-featured meal in featured endpoint",
                        description=f"Meal '{meal.get('title')}' is not featured",
                        severity="MEDIUM",
                        category="LOGIC",
                        endpoint="GET /meals/featured/",
                    )


@pytest.mark.meals
class TestAvailableNow:
    """Test available now: GET /meals/available-now/"""

    url = f"{BASE_URL}/meals/available-now/"

    def test_available_now(self, api_session, issue_tracker):
        resp = api_session.get(self.url)
        if resp.status_code != 200:
            issue_tracker.add(
                title="Available-now meals endpoint fails",
                description=f"GET /meals/available-now/ returned {resp.status_code}",
                severity="MEDIUM",
                category="API",
                endpoint="GET /meals/available-now/",
            )
        assert resp.status_code == 200


@pytest.mark.meals
class TestMealDetail:
    """Test single meal detail: GET /meals/<id>/"""

    def test_meal_detail(self, api_session, issue_tracker):
        """Get detail of a specific meal."""
        list_resp = api_session.get(f"{BASE_URL}/meals/")
        if list_resp.status_code == 200:
            data = list_resp.json()
            meals = data if isinstance(data, list) else data.get("results", [])
            if meals:
                meal_id = meals[0]["id"]
                resp = api_session.get(f"{BASE_URL}/meals/{meal_id}/")
                assert resp.status_code == 200
                detail = resp.json()
                assert detail["id"] == meal_id

    def test_meal_detail_invalid_id(self, api_session, issue_tracker):
        """Invalid meal ID should return 404."""
        resp = api_session.get(f"{BASE_URL}/meals/00000000-0000-0000-0000-000000000000/")
        assert resp.status_code == 404


@pytest.mark.meals
@pytest.mark.critical
class TestMealCRUD:
    """Test meal create/update/delete (cook-only)."""

    url = f"{BASE_URL}/meals/"

    def test_create_meal_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook should be able to create a meal."""
        payload = {
            "title": f"Test Meal {int(time.time())}",
            "description": "A test meal created by automated tests",
            "price": "12.50",
            "category": "lunch",
            "cuisine_type": "Indian",
            "meal_type": "veg",
            "spice_level": "medium",
            "serving_size": "1 plate",
            "preparation_time_mins": 30,
            "fulfillment_modes": ["pickup"],
            "is_available": True,
            "available_days": ["mon", "tue", "wed", "thu", "fri"],
            "status": "active",
        }
        resp = api_session.post(self.url, headers=cook_headers, json=payload)
        if resp.status_code not in [200, 201]:
            issue_tracker.add(
                title="Cook cannot create meal",
                description=f"POST /meals/ returned {resp.status_code}: {resp.text[:300]}",
                severity="CRITICAL",
                category="API",
                endpoint="POST /meals/",
                expected="201 Created",
                actual=f"{resp.status_code}: {resp.text[:200]}",
            )
        assert resp.status_code in [200, 201]
        return resp.json() if resp.status_code in [200, 201] else None

    def test_create_meal_as_customer_forbidden(self, api_session, customer_headers, issue_tracker):
        """Customer should NOT be able to create meals."""
        payload = {
            "title": "Customer Meal Attempt",
            "price": "10.00",
            "category": "lunch",
            "meal_type": "veg",
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Customer can create meals (should be cook-only)",
                description="POST /meals/ succeeds for customer role",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /meals/",
                expected="403 Forbidden",
                actual=f"{resp.status_code}",
            )
        assert resp.status_code == 403

    def test_create_meal_unauthenticated(self, api_session, issue_tracker):
        """Unauthenticated user should not create meals."""
        resp = api_session.post(self.url, json={"title": "Unauth Meal"})
        assert resp.status_code == 401

    def test_update_meal_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook should be able to update their own meal."""
        # Get cook's meals
        resp = api_session.get(self.url, headers=cook_headers)
        if resp.status_code == 200:
            data = resp.json()
            meals = data if isinstance(data, list) else data.get("results", [])
            if meals:
                meal_id = meals[0]["id"]
                update_resp = api_session.patch(
                    f"{self.url}{meal_id}/",
                    headers=cook_headers,
                    json={"title": f"Updated Meal {int(time.time())}"},
                )
                if update_resp.status_code not in [200, 204]:
                    issue_tracker.add(
                        title="Cook cannot update meal",
                        description=f"PATCH /meals/{meal_id}/ returned {update_resp.status_code}",
                        severity="HIGH",
                        category="API",
                        endpoint=f"PATCH /meals/<id>/",
                    )
                assert update_resp.status_code in [200, 204]


@pytest.mark.meals
@pytest.mark.critical
class TestMealImages:
    """Test meal image upload: POST /meals/<id>/images/ (Issue #32, #33)"""

    def test_upload_meal_image(self, api_session, cook_headers, issue_tracker):
        """Cook should be able to upload a meal image."""
        # Get a meal first
        meals_resp = api_session.get(f"{BASE_URL}/meals/", headers=cook_headers)
        if meals_resp.status_code != 200:
            pytest.skip("Cannot get meals")

        data = meals_resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])
        if not meals:
            pytest.skip("No meals available")

        meal_id = meals[0]["id"]

        # Create a small test image (1x1 pixel PNG)
        from PIL import Image
        import io
        img = Image.new("RGB", (100, 100), color="red")
        img_bytes = io.BytesIO()
        img.save(img_bytes, format="PNG")
        img_bytes.seek(0)

        # Upload using multipart
        headers = {"Authorization": cook_headers["Authorization"]}
        files = {"image": ("test_meal.png", img_bytes, "image/png")}
        form_data = {"display_order": "0"}

        resp = requests.post(
            f"{BASE_URL}/meals/{meal_id}/images/",
            headers=headers,
            files=files,
            data=form_data,
        )
        if resp.status_code not in [200, 201]:
            issue_tracker.add(
                title="Cook cannot upload meal image",
                description=f"POST /meals/<id>/images/ returned {resp.status_code}: {resp.text[:300]}",
                severity="CRITICAL",
                category="API",
                endpoint=f"POST /meals/{meal_id}/images/",
                related_tracker_issue="32",
                expected="201 Created with image URL",
                actual=f"{resp.status_code}: {resp.text[:200]}",
                steps_to_reproduce=[
                    "Login as cook",
                    "POST /meals/<meal_id>/images/ with multipart image",
                    "Check response",
                ],
            )
        assert resp.status_code in [200, 201]

    def test_list_meal_images(self, api_session, cook_headers, issue_tracker):
        """List images for a meal (requires auth)."""
        meals_resp = api_session.get(f"{BASE_URL}/meals/")
        if meals_resp.status_code == 200:
            data = meals_resp.json()
            meals = data if isinstance(data, list) else data.get("results", [])
            if meals:
                meal_id = meals[0]["id"]
                resp = api_session.get(
                    f"{BASE_URL}/meals/{meal_id}/images/",
                    headers=cook_headers,
                )
                if resp.status_code != 200:
                    issue_tracker.add(
                        title="Meal images listing fails",
                        description=f"GET /meals/<id>/images/ returned {resp.status_code}",
                        severity="HIGH",
                        category="API",
                        endpoint=f"GET /meals/<id>/images/",
                        related_tracker_issue="33",
                    )
                assert resp.status_code == 200


@pytest.mark.meals
class TestMealExtras:
    """Test meal extras CRUD: /meals/<id>/extras/"""

    def test_list_meal_extras(self, api_session, cook_headers, issue_tracker):
        """List extras for a meal (requires auth)."""
        meals_resp = api_session.get(f"{BASE_URL}/meals/")
        if meals_resp.status_code == 200:
            data = meals_resp.json()
            meals = data if isinstance(data, list) else data.get("results", [])
            if meals:
                meal_id = meals[0]["id"]
                resp = api_session.get(
                    f"{BASE_URL}/meals/{meal_id}/extras/",
                    headers=cook_headers,
                )
                assert resp.status_code == 200

    def test_create_meal_extra_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook should be able to add extras to their meal."""
        meals_resp = api_session.get(f"{BASE_URL}/meals/", headers=cook_headers)
        if meals_resp.status_code != 200:
            pytest.skip("Cannot get meals")

        data = meals_resp.json()
        meals = data if isinstance(data, list) else data.get("results", [])
        if not meals:
            pytest.skip("No meals available")

        meal_id = meals[0]["id"]
        payload = {
            "name": f"Extra Item {int(time.time())}",
            "price": "2.50",
            "is_available": True,
        }
        resp = api_session.post(
            f"{BASE_URL}/meals/{meal_id}/extras/",
            headers=cook_headers,
            json=payload,
        )
        if resp.status_code not in [200, 201]:
            issue_tracker.add(
                title="Cook cannot add meal extras",
                description=f"POST /meals/<id>/extras/ returned {resp.status_code}: {resp.text[:200]}",
                severity="HIGH",
                category="API",
                endpoint=f"POST /meals/<id>/extras/",
                related_tracker_issue="57",
            )
        assert resp.status_code in [200, 201]


@pytest.mark.meals
class TestPickupSlots:
    """Test pickup slot CRUD: /pickup-slots/"""

    url = f"{BASE_URL}/pickup-slots/"

    def test_list_pickup_slots(self, api_session, issue_tracker):
        """List pickup slots."""
        resp = api_session.get(self.url)
        # May require auth or be public
        assert resp.status_code in [200, 401]

    def test_create_pickup_slot_as_cook(self, api_session, cook_headers, issue_tracker):
        """Cook should be able to create pickup slots."""
        from datetime import date, timedelta
        future_date = (date.today() + timedelta(days=3)).isoformat()
        payload = {
            "date": future_date,
            "start_time": "12:00:00",
            "end_time": "14:00:00",
            "max_orders": 10,
        }
        resp = api_session.post(self.url, headers=cook_headers, json=payload)
        if resp.status_code not in [200, 201]:
            issue_tracker.add(
                title="Cook cannot create pickup slots",
                description=f"POST /pickup-slots/ returned {resp.status_code}: {resp.text[:200]}",
                severity="HIGH",
                category="API",
                endpoint="POST /pickup-slots/",
                related_tracker_issue="41",
            )
        assert resp.status_code in [200, 201]

    def test_create_slot_as_customer_forbidden(self, api_session, customer_headers, issue_tracker):
        """Customer should not create pickup slots."""
        payload = {
            "date": "2026-04-15",
            "start_time": "12:00:00",
            "end_time": "14:00:00",
            "max_orders": 10,
        }
        resp = api_session.post(self.url, headers=customer_headers, json=payload)
        if resp.status_code in [200, 201]:
            issue_tracker.add(
                title="Customer can create pickup slots (cook-only)",
                description="POST /pickup-slots/ succeeds for customer role",
                severity="CRITICAL",
                category="SECURITY",
                endpoint="POST /pickup-slots/",
            )
        assert resp.status_code == 403


@pytest.mark.meals
class TestSlotTemplates:
    """Test recurring slot templates: /slot-templates/"""

    url = f"{BASE_URL}/slot-templates/"

    def test_list_slot_templates(self, api_session, cook_headers, issue_tracker):
        """Cook can list their slot templates."""
        resp = api_session.get(self.url, headers=cook_headers)
        assert resp.status_code == 200

    def test_create_slot_template(self, api_session, cook_headers, issue_tracker):
        """Cook can create a recurring slot template."""
        from datetime import date
        payload = {
            "days_of_week": ["mon", "wed", "fri"],
            "start_time": "11:00:00",
            "end_time": "13:00:00",
            "max_orders": 15,
            "effective_from": date.today().isoformat(),
            "slot_type": "pickup",
        }
        resp = api_session.post(self.url, headers=cook_headers, json=payload)
        assert resp.status_code in [200, 201]
