# NestMeal — Backend API Documentation

**Base URL:** `http://localhost:8000/api/`
**Authentication:** JWT Bearer Token (include `Authorization: Bearer <access_token>` header)
**Content-Type:** `application/json`

---

## Table of Contents

1. [Authentication & Users](#1-authentication--users)
2. [Customer Profiles](#2-customer-profiles)
3. [Cook Profiles](#3-cook-profiles)
4. [Addresses](#4-addresses)
5. [Meals](#5-meals)
6. [Pickup Slots](#6-pickup-slots)
7. [Recurring Slot Templates](#7-recurring-slot-templates)
8. [Delivery Zones](#8-delivery-zones)
9. [Delivery Slots](#9-delivery-slots)
10. [Delivery Fee Calculation](#10-delivery-fee-calculation)
11. [Orders](#11-orders)
12. [Payments](#12-payments)
13. [Cook Payouts](#13-cook-payouts)
14. [Reviews](#14-reviews)
15. [Coupons](#15-coupons)
16. [Notifications](#16-notifications)
17. [Data Models Reference](#17-data-models-reference)
18. [Enum Values Reference](#18-enum-values-reference)
19. [Test Accounts](#19-test-accounts)

---

## 1. Authentication & Users

### 1.1 Register

**`POST /api/accounts/register/`** — Public

Creates a new user account with role-specific profile. Returns JWT tokens for immediate login.

**Request Body (Customer):**
```json
{
  "email": "john@example.com",
  "full_name": "John Doe",
  "phone": "+919876543210",
  "role": "customer",
  "password": "securepass123",
  "password_confirm": "securepass123",
  "profile_picture_url": null
}
```

**Request Body (Cook):** *(requires additional kitchen fields)*
```json
{
  "email": "chef@example.com",
  "full_name": "Chef Kumar",
  "phone": "+919800100001",
  "role": "cook",
  "password": "securepass123",
  "password_confirm": "securepass123",
  "display_name": "Kumar's Kitchen",
  "kitchen_street": "12 MG Road",
  "kitchen_city": "Bangalore",
  "kitchen_state": "Karnataka",
  "kitchen_zip": "560001"
}
```

**Response `201 Created`:**
```json
{
  "user": {
    "id": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
    "email": "john@example.com",
    "full_name": "John Doe",
    "phone": "+919876543210",
    "role": "customer",
    "profile_picture_url": null,
    "is_verified": false,
    "is_active": true,
    "created_at": "2026-03-15T05:26:26.634768Z",
    "updated_at": "2026-03-15T05:26:26.634768Z",
    "customer_profile": {
      "id": "8a5115f6-fb81-4b4e-9391-506e57492cf2",
      "user": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
      "user_email": "john@example.com",
      "full_name": "John Doe",
      "wallet_balance": "0.00",
      "preferred_fulfillment": "no_preference",
      "status": "active"
    },
    "cook_profile": null,
    "admin_profile": null
  },
  "tokens": {
    "refresh": "eyJ...",
    "access": "eyJ..."
  }
}
```

---

### 1.2 Login

**`POST /api/accounts/login/`** — Public

**Request Body:**
```json
{
  "email": "priya.sharma@gmail.com",
  "password": "customer123"
}
```

**Response `200 OK`:**
```json
{
  "user": {
    "id": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
    "email": "priya.sharma@gmail.com",
    "full_name": "Priya Sharma",
    "phone": "+919876543210",
    "role": "customer",
    "profile_picture_url": null,
    "is_verified": true,
    "is_active": true,
    "created_at": "2026-03-15T05:26:26.634768Z",
    "updated_at": "2026-03-15T05:26:26.634768Z",
    "customer_profile": {
      "id": "8a5115f6-fb81-4b4e-9391-506e57492cf2",
      "user": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
      "user_email": "priya.sharma@gmail.com",
      "full_name": "Priya Sharma",
      "wallet_balance": "0.00",
      "preferred_fulfillment": "no_preference",
      "status": "active"
    },
    "cook_profile": null,
    "admin_profile": null
  },
  "tokens": {
    "refresh": "eyJ...",
    "access": "eyJ..."
  }
}
```

**Error `400`:**
```json
{
  "non_field_errors": ["Invalid email or password."]
}
```

---

### 1.3 Refresh Token

**`POST /api/accounts/token/refresh/`** — Public

**Request Body:**
```json
{
  "refresh": "eyJ..."
}
```

**Response `200 OK`:**
```json
{
  "access": "eyJ...",
  "refresh": "eyJ..."
}
```

---

### 1.4 Get Current User Profile

**`GET /api/accounts/me/`** — Authenticated

Returns the full user object with nested role-specific profile (same shape as login response's `user` field).

---

### 1.5 Update Current User Profile

**`PUT /api/accounts/me/`** — Authenticated

Only `full_name`, `phone`, and `profile_picture_url` can be updated.

**Request Body:**
```json
{
  "full_name": "Priya S. Sharma",
  "phone": "+919876543211",
  "profile_picture_url": "https://example.com/photo.jpg"
}
```

---

### 1.6 Change Password

**`POST /api/accounts/me/change-password/`** — Authenticated

**Request Body:**
```json
{
  "old_password": "customer123",
  "new_password": "newSecure456",
  "new_password_confirm": "newSecure456"
}
```

**Response `200 OK`:**
```json
{
  "detail": "Password updated successfully."
}
```

---

## 2. Customer Profiles

**`GET /api/accounts/customer-profiles/`** — Authenticated (Customer sees own, Admin sees all)
**`GET /api/accounts/customer-profiles/{id}/`** — Authenticated
**`PUT/PATCH /api/accounts/customer-profiles/{id}/`** — Authenticated

**Customer Profile Object:**
```json
{
  "id": "8a5115f6-fb81-4b4e-9391-506e57492cf2",
  "user": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
  "user_email": "priya.sharma@gmail.com",
  "full_name": "Priya Sharma",
  "wallet_balance": "0.00",
  "preferred_fulfillment": "no_preference",
  "status": "active"
}
```

**Updatable fields:** `preferred_fulfillment`, `status`
**Read-only fields:** `id`, `user`, `wallet_balance`, `user_email`, `full_name`

---

## 3. Cook Profiles

### 3.1 Public Cook Listing (Browse)

**`GET /api/accounts/cooks/`** — Public

Lists all verified, active cooks. Supports filtering and search.

**Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `kitchen_city` | string | Filter by city (exact match) |
| `search` | string | Search display_name, bio, kitchen_city |
| `ordering` | string | Sort by: `avg_rating`, `total_reviews`, `-avg_rating` (default) |
| `page` | int | Page number |

**Response `200 OK`:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
      "user": "f9f9cf28-cc51-4d91-b0b1-f3511c37b3e6",
      "user_email": "lakshmi.kitchen@gmail.com",
      "full_name": "Lakshmi Sundaram",
      "display_name": "Lakshmi's South Indian Kitchen",
      "bio": "Authentic Tamil Nadu recipes passed down three generations...",
      "kitchen_street": "12 BTM Layout 2nd Stage",
      "kitchen_city": "Bangalore",
      "kitchen_state": "Karnataka",
      "kitchen_zip": "560076",
      "kitchen_latitude": "12.9166000",
      "kitchen_longitude": "77.6101000",
      "pickup_instructions": "",
      "pickup_locations": [
        {
          "id": "...",
          "label": "Kitchen",
          "street": "12 BTM Layout 2nd Stage",
          "city": "Bangalore",
          "state": "Karnataka",
          "zip_code": "560076",
          "latitude": "12.9166000",
          "longitude": "77.6101000",
          "is_active": true
        }
      ],
      "delivery_enabled": true,
      "delivery_radius_km": "8.00",
      "delivery_fee_type": "flat",
      "delivery_fee_value": "30.00",
      "delivery_min_order": "200.00",
      "avg_rating": "3.83",
      "total_reviews": 6,
      "is_active": true,
      "status": "active",
      "created_at": "2026-03-15T05:26:26.778539Z",
      "updated_at": "2026-03-15T05:26:32.603003Z"
    }
  ]
}
```

### 3.2 Cook Profile CRUD (Authenticated)

**`GET /api/accounts/cook-profiles/`** — Cook (own profile) / Admin (all)
**`GET /api/accounts/cook-profiles/{id}/`**
**`PUT/PATCH /api/accounts/cook-profiles/{id}/`**

**Updatable fields:** `display_name`, `bio`, `kitchen_street`, `kitchen_city`, `kitchen_state`, `kitchen_zip`, `kitchen_latitude`, `kitchen_longitude`, `pickup_instructions`, `delivery_enabled`, `delivery_radius_km`, `delivery_fee_type`, `delivery_fee_value`, `delivery_min_order`, `food_safety_certificate_url`, `government_id`, `bank_account_number`, `bank_ifsc`, `bank_account_holder`, `is_active`, `status`

**Read-only fields:** `id`, `user`, `commission_rate`, `avg_rating`, `total_reviews`, `created_at`, `updated_at`

---

## 4. Addresses

**`GET /api/accounts/addresses/`** — Authenticated (own addresses)
**`POST /api/accounts/addresses/`** — Authenticated
**`GET /api/accounts/addresses/{id}/`**
**`PUT/PATCH /api/accounts/addresses/{id}/`**
**`DELETE /api/accounts/addresses/{id}/`**

**Address Object:**
```json
{
  "id": "uuid",
  "user": "uuid",
  "label": "Home",
  "street": "42 MG Road, Indiranagar",
  "city": "Bangalore",
  "state": "Karnataka",
  "zip_code": "560038",
  "latitude": "12.9716000",
  "longitude": "77.6411000",
  "is_default": true,
  "created_at": "2026-03-15T05:26:26.687781Z"
}
```

**Create/Update Body:**
```json
{
  "label": "Home",
  "street": "42 MG Road, Indiranagar",
  "city": "Bangalore",
  "state": "Karnataka",
  "zip_code": "560038",
  "latitude": "12.9716000",
  "longitude": "77.6411000",
  "is_default": true
}
```

> Setting `is_default: true` automatically unsets any previously default address.

---

## 5. Meals

### 5.1 List Meals (Browse)

**`GET /api/meals/`** — Public

Paginated, filterable, searchable meal listing. Only shows `status=active` meals.

**Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `category` | string | `breakfast`, `lunch`, `dinner`, `snack`, `dessert`, `beverage`, `meal_kit` |
| `meal_type` | string | `veg`, `non_veg`, `egg` |
| `cuisine_type` | string | Case-insensitive match (e.g., `South Indian`) |
| `spice_level` | string | `mild`, `medium`, `spicy`, `extra_spicy` |
| `min_price` | number | Minimum price |
| `max_price` | number | Maximum price |
| `min_rating` | number | Minimum avg_rating (e.g., `4`) |
| `dietary_tags` | string | Comma-separated: `vegan,gluten_free` |
| `fulfillment_modes` | string | `pickup`, `delivery`, or `pickup,delivery` |
| `available_days` | string | Comma-separated: `mon,tue` |
| `cook` | UUID | Filter by cook profile ID |
| `is_available` | boolean | `true` or `false` |
| `is_featured` | boolean | `true` or `false` |
| `search` | string | Searches: title, description, tags, cook display_name |
| `ordering` | string | `price`, `-price`, `avg_rating`, `-avg_rating`, `created_at`, `-created_at`, `total_orders`, `-total_orders` |
| `page` | int | Page number |
| `page_size` | int | Items per page (default 20) |

**Response `200 OK` — Meal List Item:**
```json
{
  "count": 19,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "058a2eab-60b1-415d-94a4-9bb3cbd21002",
      "title": "Masala Dosa with Sambar & Chutney",
      "short_description": "Crispy golden dosa with potato filling, served with sambar and coconut chutney",
      "price": "120.00",
      "discount_percentage": "0.00",
      "effective_price": "120.00",
      "category": "breakfast",
      "cuisine_type": "South Indian",
      "meal_type": "veg",
      "spice_level": "medium",
      "avg_rating": "5.00",
      "images": [
        {
          "id": "d7394b12-aa3c-4f5a-8cfb-909845367929",
          "meal": "058a2eab-60b1-415d-94a4-9bb3cbd21002",
          "image_url": "https://images.nestmeal.local/meals/058a2eab_1.jpg",
          "display_order": 0,
          "created_at": "2026-03-15T05:26:31.317452Z"
        }
      ],
      "cook_display_name": "Lakshmi's South Indian Kitchen",
      "fulfillment_modes": ["pickup", "delivery"]
    }
  ]
}
```

### 5.2 Meal Detail

**`GET /api/meals/{id}/`** — Public

Returns full meal details with embedded cook profile card.

**Response `200 OK`:**
```json
{
  "id": "58405f2e-1430-4657-b2d6-5b10b3441b36",
  "cook": {
    "id": "c17193e6-c27d-401b-aa5b-41c97040f75e",
    "display_name": "Rajesh's North Indian Thali",
    "bio": "Home-style North Indian thalis with dal, sabzi, roti, rice, and raita.",
    "avg_rating": "4.33",
    "total_reviews": 3,
    "kitchen_city": "Bangalore",
    "kitchen_state": "Karnataka",
    "delivery_enabled": true,
    "delivery_radius_km": "5.00",
    "is_active": true,
    "status": "active"
  },
  "title": "Mango Lassi (Large)",
  "description": "Thick creamy mango lassi made with fresh Alphonso pulp",
  "short_description": "Thick creamy mango lassi made with fresh Alphonso pulp",
  "price": "80.00",
  "discount_percentage": "0.00",
  "effective_price": "80.00",
  "currency": "INR",
  "category": "beverage",
  "cuisine_type": "North Indian",
  "meal_type": "veg",
  "dietary_tags": [],
  "allergen_info": [],
  "spice_level": "mild",
  "serving_size": "1 glass (400ml)",
  "calories_approx": 280,
  "preparation_time_mins": 5,
  "fulfillment_modes": ["pickup", "delivery"],
  "is_available": true,
  "available_days": ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
  "total_orders": 0,
  "avg_rating": "0.00",
  "tags": ["refreshing", "summer"],
  "is_featured": false,
  "status": "active",
  "images": [
    {
      "id": "36f16cd6-dd30-49db-9041-d834d1c9fabe",
      "meal": "58405f2e-1430-4657-b2d6-5b10b3441b36",
      "image_url": "https://images.nestmeal.local/meals/58405f2e_1.jpg",
      "display_order": 0,
      "created_at": "2026-03-15T05:26:31.485625Z"
    }
  ],
  "created_at": "2026-03-15T05:26:31.480629Z",
  "updated_at": "2026-03-15T05:26:32.585953Z"
}
```

### 5.3 Create Meal (Cook Only)

**`POST /api/meals/`** — Authenticated, Cook role

**Request Body:**
```json
{
  "title": "Paneer Tikka",
  "description": "Marinated paneer cubes grilled in tandoor...",
  "short_description": "Smoky tandoori paneer tikka with mint chutney",
  "price": "250.00",
  "discount_percentage": "0.00",
  "currency": "INR",
  "category": "snack",
  "cuisine_type": "North Indian",
  "meal_type": "veg",
  "dietary_tags": ["gluten_free"],
  "allergen_info": ["contains dairy"],
  "spice_level": "medium",
  "serving_size": "Serves 2 (8 pieces)",
  "calories_approx": 400,
  "preparation_time_mins": 25,
  "fulfillment_modes": ["pickup", "delivery"],
  "is_available": true,
  "available_days": ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
  "tags": ["appetizer", "party"],
  "status": "active"
}
```

> The `cook` field is auto-set from the authenticated user's cook profile.

### 5.4 Update Meal (Cook Only)

**`PUT/PATCH /api/meals/{id}/`** — Authenticated, Cook role (own meals only)

Same body as create. Cook ownership is validated.

### 5.5 Delete Meal (Soft Archive)

**`DELETE /api/meals/{id}/`** — Authenticated, Cook role (own meals only)

Sets `status=archived` and `is_available=false` (soft delete).

### 5.6 Featured Meals

**`GET /api/meals/featured/`** — Public

Returns meals where `is_featured=true`, `status=active`, `is_available=true`.

### 5.7 Available Now

**`GET /api/meals/available-now/`** — Public

Returns meals from cooks who have open pickup slots within the next 2 hours.

### 5.8 Meal Images

**`GET /api/meals/{meal_id}/images/`** — Cook only (own meals)
**`POST /api/meals/{meal_id}/images/`** — Cook only

**Request Body:**
```json
{
  "image_url": "https://example.com/meal-photo.jpg",
  "display_order": 1
}
```

**`PUT/DELETE /api/meals/{meal_id}/images/{image_id}/`** — Cook only

---

## 6. Pickup Slots

**`GET /api/pickup-slots/`** — Public
**`POST /api/pickup-slots/`** — Cook only
**`GET /api/pickup-slots/{id}/`** — Public
**`PUT/PATCH /api/pickup-slots/{id}/`** — Cook only (own slots)
**`DELETE /api/pickup-slots/{id}/`** — Cook only (own slots)

**Query Parameters (list):**
| Parameter | Type | Description |
|---|---|---|
| `cook` | UUID | Filter by cook profile ID |
| `date` | date | Filter by date (YYYY-MM-DD) |
| `status` | string | `open`, `full`, `cancelled` |
| `is_available` | boolean | `true` / `false` |
| `ordering` | string | `date`, `start_time` |

**Pickup Slot Object:**
```json
{
  "id": "7571dfd9-5128-45b2-ae6b-2a00756eb4c9",
  "cook": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
  "cook_display_name": "Lakshmi's South Indian Kitchen",
  "date": "2026-03-15",
  "start_time": "11:00:00",
  "end_time": "11:30:00",
  "max_orders": 10,
  "booked_orders": 0,
  "is_available": true,
  "location_label": "",
  "location_street": "",
  "location_latitude": null,
  "location_longitude": null,
  "status": "open",
  "created_at": "2026-03-15T05:26:31.554773Z"
}
```

**Create Body (Cook):**
```json
{
  "date": "2026-03-20",
  "start_time": "12:00:00",
  "end_time": "12:30:00",
  "max_orders": 10,
  "location_label": "Kitchen",
  "location_street": "12 BTM Layout"
}
```

> The `cook` field is auto-set from the authenticated cook user.

---

## 7. Recurring Slot Templates

**`GET /api/slot-templates/`** — Cook only (own templates)
**`POST /api/slot-templates/`** — Cook only
**`PUT/PATCH /api/slot-templates/{id}/`** — Cook only
**`DELETE /api/slot-templates/{id}/`** — Cook only

**Template Object:**
```json
{
  "id": "uuid",
  "cook": "uuid",
  "cook_display_name": "Lakshmi's South Indian Kitchen",
  "days_of_week": ["mon", "tue", "wed", "thu", "fri"],
  "start_time": "12:00:00",
  "end_time": "12:30:00",
  "max_orders": 10,
  "effective_from": "2026-03-15",
  "effective_until": null,
  "is_active": true,
  "slot_type": "pickup",
  "created_at": "2026-03-15T05:26:31.812Z"
}
```

---

## 8. Delivery Zones

**`GET /api/delivery-zones/`** — Cook only (own zones) / Admin (all)
**`POST /api/delivery-zones/`** — Cook only
**`GET /api/delivery-zones/{id}/`** — Cook only
**`PUT/PATCH /api/delivery-zones/{id}/`** — Cook only
**`DELETE /api/delivery-zones/{id}/`** — Cook only

**Delivery Zone Object:**
```json
{
  "id": "uuid",
  "cook": "uuid",
  "cook_name": "Lakshmi's South Indian Kitchen",
  "zone_type": "radius",
  "radius_km": "8.00",
  "polygon_coords": [],
  "delivery_fee_type": "flat",
  "delivery_fee_value": "30.00",
  "min_order_value": "200.00",
  "estimated_delivery_mins": 40,
  "is_active": true,
  "created_at": "2026-03-15T05:26:27.129Z"
}
```

**Create Body:**
```json
{
  "zone_type": "radius",
  "radius_km": "8.00",
  "delivery_fee_type": "flat",
  "delivery_fee_value": "30.00",
  "min_order_value": "200.00",
  "estimated_delivery_mins": 40
}
```

---

## 9. Delivery Slots

**`GET /api/delivery-slots/`** — Public (shows available/open only) / Cook (own slots)
**`POST /api/delivery-slots/`** — Cook only
**`GET /api/delivery-slots/{id}/`** — Public
**`PUT/PATCH /api/delivery-slots/{id}/`** — Cook only
**`DELETE /api/delivery-slots/{id}/`** — Cook only

**Query Parameters (list):**
| Parameter | Type | Description |
|---|---|---|
| `cook_id` | UUID | Filter by cook |
| `date` | date | Filter by date (YYYY-MM-DD) |

**Delivery Slot Object:**
```json
{
  "id": "7571dfd9-5128-45b2-ae6b-2a00756eb4c9",
  "cook": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
  "cook_name": "Lakshmi's South Indian Kitchen",
  "date": "2026-03-15",
  "start_time": "12:00:00",
  "end_time": "14:00:00",
  "max_orders": 5,
  "booked_orders": 0,
  "is_available": true,
  "status": "open",
  "created_at": "2026-03-15T05:26:31.764Z"
}
```

---

## 10. Delivery Fee Calculation

**`POST /api/delivery/calculate-fee/`** — Public

Calculates delivery fee and checks availability based on cook's kitchen location, delivery zones, and customer coordinates.

**Request Body:**
```json
{
  "cook_id": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
  "customer_lat": "12.9352",
  "customer_lng": "77.6245"
}
```

**Response `200 OK` — Available:**
```json
{
  "available": true,
  "distance_km": 2.59,
  "delivery_fee": 30.0,
  "estimated_delivery_mins": 40,
  "min_order_value": 200.0
}
```

**Response `200 OK` — Not Available (out of range):**
```json
{
  "available": false,
  "distance_km": 15.23,
  "message": "Delivery is not available for this distance.",
  "max_radius_km": 8.0
}
```

**Error `400` — Cook doesn't offer delivery:**
```json
{
  "cook_id": ["This cook does not offer delivery."]
}
```

---

## 11. Orders

### 11.1 Create Order

**`POST /api/orders/`** — Authenticated, Customer role

**Request Body (Pickup Order):**
```json
{
  "cook_id": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
  "fulfillment_type": "pickup",
  "items": [
    {
      "meal_id": "058a2eab-60b1-415d-94a4-9bb3cbd21002",
      "quantity": 2
    },
    {
      "meal_id": "17998546-2417-4428-812e-7f5651c3ee85",
      "quantity": 1
    }
  ],
  "pickup_slot_id": "7571dfd9-5128-45b2-ae6b-2a00756eb4c9",
  "coupon_code": "FLAT100",
  "special_instructions": "Extra sambar please"
}
```

**Request Body (Delivery Order):**
```json
{
  "cook_id": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
  "fulfillment_type": "delivery",
  "items": [
    {
      "meal_id": "058a2eab-60b1-415d-94a4-9bb3cbd21002",
      "quantity": 2
    }
  ],
  "delivery_slot_id": "uuid-of-delivery-slot",
  "delivery_address_street": "42 MG Road, Indiranagar",
  "delivery_address_city": "Bangalore",
  "delivery_address_state": "Karnataka",
  "delivery_address_zip": "560038",
  "delivery_address_lat": "12.9716",
  "delivery_address_lng": "77.6411",
  "coupon_code": "",
  "special_instructions": ""
}
```

**Pricing Calculation (automatic):**
- `item_total` = sum of (meal.effective_price x quantity) for each item
- `platform_fee` = item_total x 3%
- `tax_amount` = (item_total + platform_fee) x 5%
- `delivery_fee` = based on cook's delivery settings (0 for pickup)
- `discount_amount` = coupon discount (validated)
- `total_amount` = item_total + platform_fee + tax_amount + delivery_fee - discount_amount

**Response `201 Created`:** Full Order object (see 11.3)

**Validation Errors:**
```json
{
  "cook_id": ["Cook not found or not active."],
  "items": ["Meal <id> is not available from this cook."],
  "pickup_slot_id": ["Pickup slot not available."],
  "coupon_code": ["Minimum order value of 500.00 required."],
  "fulfillment_type": ["This cook does not offer delivery."]
}
```

### 11.2 List Orders

**`GET /api/orders/`** — Authenticated

- **Customer:** sees own orders
- **Cook:** sees orders assigned to them
- **Admin:** sees all orders

**Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `status` | string | Filter by order status |
| `fulfillment_type` | string | `pickup` or `delivery` |
| `date_from` | date | Start date (YYYY-MM-DD) |
| `date_to` | date | End date (YYYY-MM-DD) |

**Response `200 OK`:**
```json
[
  {
    "id": "cefed59f-c982-4ae4-a515-5bbc6ac3801a",
    "order_number": "HB-20260315-3204",
    "status": "completed",
    "total_amount": "173.04",
    "fulfillment_type": "pickup",
    "created_at": "2026-03-15T05:26:32.082303Z",
    "cook_display_name": "Wei's Wok - Indo-Chinese"
  }
]
```

### 11.3 Get Order Detail

**`GET /api/orders/{id}/`** — Authenticated (owner or admin)

**Response `200 OK`:**
```json
{
  "id": "cefed59f-c982-4ae4-a515-5bbc6ac3801a",
  "order_number": "HB-20260315-3204",
  "customer": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
  "customer_name": "Priya Sharma",
  "cook": "238062ee-1ec3-4d90-ab05-30a9e258df79",
  "cook_display_name": "Wei's Wok - Indo-Chinese",
  "fulfillment_type": "pickup",
  "pickup_slot": "ba7a06d0-b99f-471e-a124-5c6a4240f0a7",
  "pickup_code": "190268",
  "pickup_time_actual": null,
  "delivery_slot": null,
  "delivery_address_street": "",
  "delivery_address_city": "",
  "delivery_address_state": "",
  "delivery_address_zip": "",
  "delivery_address_lat": null,
  "delivery_address_lng": null,
  "delivery_fee": "0.00",
  "delivery_distance_km": null,
  "delivery_status": null,
  "rider_name": "",
  "rider_phone": "",
  "estimated_delivery_at": null,
  "delivered_at": null,
  "item_total": "160.00",
  "platform_fee": "4.80",
  "tax_amount": "8.24",
  "discount_amount": "0.00",
  "total_amount": "173.04",
  "coupon_code": "",
  "special_instructions": "",
  "status": "completed",
  "payment_status": "paid",
  "cancellation_reason": "",
  "cancelled_by": null,
  "created_at": "2026-03-15T05:26:32.082303Z",
  "updated_at": "2026-03-15T05:26:32.082303Z",
  "items": [
    {
      "id": "22d6bb85-1b27-4c29-a6e9-32fc09a3cdbe",
      "meal": "bed9f193-fa49-41e6-b0a7-72ad200e6cbc",
      "meal_title": "Veg Hakka Noodles",
      "quantity": 1,
      "unit_price": "160.00",
      "line_total": "160.00"
    }
  ]
}
```

### 11.4 Update Order Status (Cook/Admin)

**`POST /api/orders/{id}/update-status/`** — Authenticated, Cook (own orders) or Admin

**Request Body:**
```json
{
  "status": "accepted"
}
```

**Allowed Status Transitions:**
```
placed       → accepted, rejected, cancelled
accepted     → preparing, cancelled
preparing    → ready_for_pickup, out_for_delivery
ready_for_pickup → picked_up, completed
picked_up    → completed
out_for_delivery → delivered
delivered    → completed
```

**Error when invalid transition:**
```json
{
  "status": ["Cannot transition from 'placed' to 'delivered'. Allowed: ['accepted', 'rejected', 'cancelled']"]
}
```

### 11.5 Cancel Order

**`POST /api/orders/{id}/cancel/`** — Authenticated (Customer, Cook, or Admin)

Only allowed when `status` is `placed` or `accepted`.

**Request Body:**
```json
{
  "cancellation_reason": "Changed my mind about the order"
}
```

**Response:** Full Order object with `status: "cancelled"`, `cancelled_by`, and `cancellation_reason` populated.

### 11.6 Verify Pickup (Cook)

**`POST /api/orders/{id}/verify-pickup/`** — Authenticated, Cook (own orders)

Cook verifies the 6-digit pickup code presented by customer. Only works when `status=ready_for_pickup` and `fulfillment_type=pickup`.

**Request Body:**
```json
{
  "pickup_code": "190268"
}
```

**Success:** Order status changes to `picked_up`, `pickup_time_actual` is set.

**Error:**
```json
{
  "detail": "Invalid pickup code."
}
```

### 11.7 Cook Dashboard Stats

**`GET /api/orders/stats/`** — Authenticated, Cook role

**Response `200 OK`:**
```json
{
  "total_orders": 5,
  "completed_orders": 5,
  "cancelled_orders": 0,
  "total_revenue": "871.13",
  "today_orders": 5,
  "today_revenue": "871.13",
  "pending_orders": 0
}
```

---

## 12. Payments

### 12.1 Create Payment

**`POST /api/payments/`** — Authenticated, Customer

Creates a payment for an order. Currently simulates gateway success (status immediately set to `success`).

**Request Body:**
```json
{
  "order_id": "cefed59f-c982-4ae4-a515-5bbc6ac3801a",
  "method": "upi",
  "gateway": "razorpay"
}
```

`method` options: `upi`, `credit_card`, `debit_card`, `net_banking`, `wallet`

**Response `201 Created`:**
```json
{
  "id": "uuid",
  "order": "cefed59f-c982-4ae4-a515-5bbc6ac3801a",
  "order_number": "HB-20260315-3204",
  "customer": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
  "customer_name": "Priya Sharma",
  "amount": "173.04",
  "currency": "INR",
  "method": "upi",
  "gateway": "razorpay",
  "gateway_transaction_id": "txn_a1b2c3d4e5f6g7h8i9j0",
  "gateway_status": "captured",
  "status": "success",
  "refund_amount": null,
  "refund_reason": "",
  "refund_initiated_at": null,
  "paid_at": "2026-03-15T06:00:00.000Z",
  "created_at": "2026-03-15T06:00:00.000Z"
}
```

### 12.2 List Payments

**`GET /api/payments/`** — Authenticated (Customer: own, Admin: all)

Returns list of Payment objects.

---

## 13. Cook Payouts

**`GET /api/payouts/`** — Authenticated (Cook: own, Admin: all)
**`POST /api/payouts/`** — Admin only

**Payout Object:**
```json
{
  "id": "uuid",
  "cook": "uuid",
  "cook_name": "Lakshmi's South Indian Kitchen",
  "period_start": "2026-03-01",
  "period_end": "2026-03-07",
  "gross_amount": "5000.00",
  "delivery_fees_collected": "300.00",
  "commission_deducted": "500.00",
  "net_amount": "4800.00",
  "status": "pending",
  "bank_reference": "",
  "paid_at": null,
  "created_at": "2026-03-15T06:00:00Z"
}
```

---

## 14. Reviews

### 14.1 List Reviews

**`GET /api/reviews/`** — Public

**Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `cook_id` | UUID | Filter reviews by cook |
| `meal_id` | UUID | Filter reviews by meal |
| `min_rating` | int | Minimum rating (1-5) |

**Response `200 OK`:**
```json
{
  "count": 15,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "05ad141c-a6c5-4c5b-98af-b6625436d530",
      "order": "78ff521f-f03d-4b55-af9b-e13a04236020",
      "customer": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
      "customer_name": "Priya Sharma",
      "cook": "b7c0bc85-2a41-4ac9-9f38-a978b88645f4",
      "cook_name": "Lakshmi's South Indian Kitchen",
      "meal": "e40b237b-40fc-4935-a704-f1befce3a693",
      "meal_title": "Chettinad Chicken Curry",
      "rating": 4,
      "delivery_rating": null,
      "comment": "Great flavors, generous portions. Will order again!",
      "cook_reply": "",
      "cook_replied_at": null,
      "is_visible": true,
      "is_flagged": false,
      "images": [],
      "created_at": "2026-03-15T05:26:32.537Z",
      "updated_at": "2026-03-15T05:26:32.537Z"
    }
  ]
}
```

### 14.2 Create Review

**`POST /api/reviews/`** — Authenticated, Customer

**Request Body:**
```json
{
  "order_id": "78ff521f-f03d-4b55-af9b-e13a04236020",
  "rating": 5,
  "delivery_rating": 4,
  "comment": "Absolutely delicious! Tasted just like home cooking."
}
```

**Validations:**
- Order must have `status=completed`
- Must be within 7-day review window
- Only one review per order
- `delivery_rating` is optional (for delivery orders)
- Rating 1-2 auto-flags for admin review

**Side effects:** Recalculates `avg_rating` and `total_reviews` on both Cook and Meal.

### 14.3 Update Review

**`PATCH /api/reviews/{id}/`** — Authenticated, Customer (own review, within 48 hours)

**Request Body:**
```json
{
  "rating": 4,
  "comment": "Updated: still great food!"
}
```

### 14.4 Cook Reply to Review

**`PATCH /api/reviews/{id}/reply/`** — Authenticated, Cook (own reviews)

**Request Body:**
```json
{
  "cook_reply": "Thank you for your feedback! Glad you enjoyed the meal."
}
```

### 14.5 Review Images

**`GET /api/review-images/`** — Authenticated (own images)
**`POST /api/review-images/`** — Authenticated, Customer

**Request Body:**
```json
{
  "review": "05ad141c-a6c5-4c5b-98af-b6625436d530",
  "image_url": "https://example.com/food-photo.jpg"
}
```

Max 3 images per review.

---

## 15. Coupons

### 15.1 List Active Coupons

**`GET /api/coupons/`** — Public (shows active, valid coupons) / Admin (shows all)

**Coupon Object:**
```json
{
  "id": "2a8cd856-c971-4f66-9991-762825fd8b9a",
  "code": "WELCOME50",
  "description": "50% off on your first order (up to 150)",
  "discount_type": "percentage",
  "discount_value": "50.00",
  "applies_to_delivery_fee": false,
  "min_order_value": "200.00",
  "valid_from": "2026-02-13T05:26:32.621Z",
  "valid_until": "2026-05-14T05:26:32.621Z",
  "usage_limit_total": 1000,
  "usage_limit_per_user": 1,
  "used_count": 0,
  "applicable_to": "new_users",
  "applicable_fulfillment": "all",
  "applicable_ids": [],
  "is_active": true,
  "created_by": "admin",
  "created_at": "2026-03-15T05:26:32.622Z"
}
```

### 15.2 Validate Coupon

**`POST /api/coupons/validate/`** — Authenticated, Customer

Check if a coupon is valid before placing an order.

**Request Body:**
```json
{
  "code": "FLAT100",
  "order_value": "600.00",
  "fulfillment_type": "pickup"
}
```

**Response `200 OK` — Valid:**
```json
{
  "valid": true,
  "coupon_code": "FLAT100",
  "discount_type": "flat_amount",
  "discount_value": "100.00",
  "discount_amount": "100.00",
  "description": "Flat 100 off on orders above 500"
}
```

**Error `400` — Invalid:**
```json
{
  "code": ["Minimum order value of 500.00 required."]
}
```

**Validation checks:** Active, within date range, usage limits (total + per-user), fulfillment type match, minimum order value, new-user eligibility.

### 15.3 Create Coupon (Admin Only)

**`POST /api/coupons/`** — Authenticated, Admin

**Request Body:**
```json
{
  "code": "SUMMER25",
  "description": "25% off on summer meals",
  "discount_type": "percentage",
  "discount_value": "25.00",
  "applies_to_delivery_fee": false,
  "min_order_value": "200.00",
  "valid_from": "2026-04-01T00:00:00Z",
  "valid_until": "2026-06-30T23:59:59Z",
  "usage_limit_total": 500,
  "usage_limit_per_user": 3,
  "applicable_to": "all",
  "applicable_fulfillment": "all",
  "applicable_ids": [],
  "is_active": true,
  "created_by": "admin"
}
```

---

## 16. Notifications

### 16.1 List Notifications

**`GET /api/notifications/`** — Authenticated (own notifications)

**Response `200 OK`:**
```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "f8677b5d-3c16-479f-8fee-43f40d8fc8d9",
      "user": "aa4896ef-4c38-43e9-be8b-2b0764401b13",
      "title": "Welcome to NestMeal!",
      "message": "Discover amazing home-cooked meals from talented local cooks near you.",
      "channel": "push",
      "event_type": "welcome",
      "reference_id": null,
      "is_read": false,
      "created_at": "2026-03-15T05:26:32.650684Z"
    }
  ]
}
```

### 16.2 Mark Single as Read

**`PATCH /api/notifications/{id}/read/`** — Authenticated

### 16.3 Mark All as Read

**`PATCH /api/notifications/mark-all-read/`** — Authenticated

**Response `200 OK`:**
```json
{
  "marked_read": 3
}
```

### 16.4 Unread Count

**`GET /api/notifications/unread-count/`** — Authenticated

**Response `200 OK`:**
```json
{
  "unread_count": 1
}
```

---

## 17. Data Models Reference

### User
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `email` | string | Unique, used for login |
| `full_name` | string | Required |
| `phone` | string | Required |
| `role` | enum | `customer`, `cook`, `admin` |
| `profile_picture_url` | string/null | Optional URL |
| `is_verified` | boolean | Phone/email verified |
| `is_active` | boolean | Account active |
| `created_at` | datetime | |
| `updated_at` | datetime | |

### CustomerProfile
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `user` | FK → User | OneToOne |
| `wallet_balance` | decimal | Read-only, default 0.00 |
| `preferred_fulfillment` | enum | `pickup`, `delivery`, `no_preference` |
| `status` | enum | `active`, `suspended`, `deleted` |

### CookProfile
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `user` | FK → User | OneToOne |
| `display_name` | string | Kitchen name |
| `bio` | text (500) | |
| `kitchen_street/city/state/zip` | string | Kitchen address |
| `kitchen_latitude/longitude` | decimal(10,7) | |
| `pickup_instructions` | text | |
| `delivery_enabled` | boolean | Default false |
| `delivery_radius_km` | decimal | Default 5 |
| `delivery_fee_type` | enum/null | `flat`, `per_km`, `free` |
| `delivery_fee_value` | decimal | |
| `delivery_min_order` | decimal | |
| `commission_rate` | decimal | Platform-set, default 0.10 |
| `avg_rating` | decimal | Computed |
| `total_reviews` | int | Computed |
| `is_active` | boolean | Cook togglable |
| `status` | enum | `pending_verification`, `active`, `suspended`, `deactivated` |

### Address
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `user` | FK → User | |
| `label` | string | Home, Work, etc. |
| `street/city/state/zip_code` | string | |
| `latitude/longitude` | decimal(10,7) | |
| `is_default` | boolean | Only one per user |

### Meal
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `cook` | FK → CookProfile | |
| `title` | string (100) | |
| `description` | text (1000) | |
| `short_description` | string (150) | Shown on cards |
| `price` | decimal | Base price |
| `discount_percentage` | decimal | 0-100 |
| `effective_price` | computed | price × (1 - discount/100) |
| `currency` | enum | `INR`, `USD`, `EUR` |
| `category` | enum | See enums |
| `cuisine_type` | string | Free text |
| `meal_type` | enum | `veg`, `non_veg`, `egg` |
| `dietary_tags` | JSON array | e.g., `["vegan", "gluten_free"]` |
| `allergen_info` | JSON array | e.g., `["contains peanuts"]` |
| `spice_level` | enum | `mild`, `medium`, `spicy`, `extra_spicy` |
| `serving_size` | string | e.g., "Serves 2" |
| `calories_approx` | int/null | |
| `preparation_time_mins` | int | |
| `fulfillment_modes` | JSON array | `["pickup"]` or `["pickup", "delivery"]` |
| `is_available` | boolean | |
| `available_days` | JSON array | `["mon","tue","wed","thu","fri","sat","sun"]` |
| `total_orders` | int | Computed |
| `avg_rating` | decimal | Computed |
| `tags` | JSON array | Free text tags |
| `is_featured` | boolean | Admin-promoted |
| `status` | enum | `draft`, `active`, `paused`, `archived` |

### PickupSlot
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `cook` | FK → CookProfile | |
| `date` | date | |
| `start_time` | time | |
| `end_time` | time | |
| `max_orders` | int | |
| `booked_orders` | int | Auto-tracked |
| `is_available` | boolean | Auto-false when full |
| `status` | enum | `open`, `full`, `cancelled` |

### DeliveryZone
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `cook` | FK → CookProfile | |
| `zone_type` | enum | `radius`, `polygon` |
| `radius_km` | decimal | For radius zones |
| `polygon_coords` | JSON array | `[{lat, lng}, ...]` |
| `delivery_fee_type` | enum | `flat`, `per_km`, `free` |
| `delivery_fee_value` | decimal | |
| `min_order_value` | decimal | |
| `estimated_delivery_mins` | int | |

### DeliverySlot
Same structure as PickupSlot but for delivery windows (typically 1-2 hour windows).

### Order
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `order_number` | string | Auto-generated: `HB-YYYYMMDD-XXXX` |
| `customer` | FK → User | |
| `cook` | FK → CookProfile | |
| `fulfillment_type` | enum | `pickup`, `delivery` |
| `pickup_slot` | FK/null | For pickup orders |
| `pickup_code` | string (6) | Auto-generated for pickup |
| `delivery_slot` | FK/null | For delivery orders |
| `delivery_address_*` | strings | Snapshot at order time |
| `delivery_fee` | decimal | 0 for pickup |
| `delivery_distance_km` | decimal/null | |
| `delivery_status` | enum/null | For delivery orders |
| `item_total` | decimal | Sum of line items |
| `platform_fee` | decimal | 3% of item_total |
| `tax_amount` | decimal | 5% of (item_total + platform_fee) |
| `discount_amount` | decimal | Coupon discount |
| `total_amount` | decimal | Final charged amount |
| `status` | enum | See order status flow |
| `payment_status` | enum | `pending`, `paid`, `refunded`, `partially_refunded`, `failed` |

### OrderItem
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `order` | FK → Order | |
| `meal` | FK → Meal | |
| `meal_title` | string | Snapshot |
| `quantity` | int | |
| `unit_price` | decimal | Price at order time |
| `line_total` | decimal | quantity × unit_price |

### Payment
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `order` | FK → Order | OneToOne |
| `customer` | FK → User | |
| `amount` | decimal | |
| `method` | enum | `upi`, `credit_card`, `debit_card`, `net_banking`, `wallet` |
| `gateway` | string | e.g., `razorpay` |
| `gateway_transaction_id` | string | External reference |
| `status` | enum | `initiated`, `success`, `failed`, `refund_initiated`, `refunded` |

### Review
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `order` | FK → Order | OneToOne |
| `customer` | FK → User | |
| `cook` | FK → CookProfile | |
| `meal` | FK → Meal/null | Primary meal |
| `rating` | int | 1-5 |
| `delivery_rating` | int/null | 1-5, delivery only |
| `comment` | text (500) | |
| `cook_reply` | text (300) | |
| `is_flagged` | boolean | Auto-flagged if rating <= 2 |

### Coupon
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `code` | string | Unique, uppercase |
| `discount_type` | enum | `percentage`, `flat_amount` |
| `discount_value` | decimal | |
| `applies_to_delivery_fee` | boolean | |
| `min_order_value` | decimal | |
| `applicable_to` | enum | `all`, `specific_cooks`, `specific_meals`, `new_users` |
| `applicable_fulfillment` | enum | `all`, `pickup_only`, `delivery_only` |

### Notification
| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `user` | FK → User | |
| `title` | string | |
| `message` | text | |
| `channel` | enum | `push`, `email`, `sms` |
| `event_type` | string | e.g., `order_placed`, `review_prompt` |
| `reference_id` | UUID/null | Links to order, review, etc. |
| `is_read` | boolean | |

---

## 18. Enum Values Reference

### User Roles
`customer`, `cook`, `admin`

### Meal Categories
`breakfast`, `lunch`, `dinner`, `snack`, `dessert`, `beverage`, `meal_kit`

### Meal Types
`veg`, `non_veg`, `egg`

### Spice Levels
`mild`, `medium`, `spicy`, `extra_spicy`

### Dietary Tags
`vegan`, `gluten_free`, `keto`, `low_carb`, `sugar_free`, `nut_free`, `dairy_free`

### Meal Status
`draft`, `active`, `paused`, `archived`

### Fulfillment Types
`pickup`, `delivery`

### Days of Week
`mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`

### Slot Status
`open`, `full`, `cancelled`

### Order Status Flow

**Pickup:**
```
placed → accepted → preparing → ready_for_pickup → picked_up → completed
   │         │
   │         └→ rejected
   └→ cancelled
```

**Delivery:**
```
placed → accepted → preparing → ready_for_pickup → out_for_delivery → delivered → completed
   │         │
   │         └→ rejected
   └→ cancelled
```

### Payment Status
`pending`, `paid`, `refunded`, `partially_refunded`, `failed`

### Payment Methods
`upi`, `credit_card`, `debit_card`, `net_banking`, `wallet`

### Delivery Fee Types
`flat`, `per_km`, `free`

### Delivery Zone Types
`radius`, `polygon`

### Cook Status
`pending_verification`, `active`, `suspended`, `deactivated`

### Customer Status
`active`, `suspended`, `deleted`

### Coupon Discount Types
`percentage`, `flat_amount`

### Coupon Applicable To
`all`, `specific_cooks`, `specific_meals`, `new_users`

### Coupon Fulfillment
`all`, `pickup_only`, `delivery_only`

### Notification Channels
`push`, `email`, `sms`

### Notification Event Types
`welcome`, `order_placed`, `order_accepted`, `order_rejected`, `order_ready`, `out_for_delivery`, `order_delivered`, `pickup_reminder`, `missed_pickup`, `failed_delivery`, `review_prompt`, `cook_reply`, `slot_cancelled`, `payout_completed`, `verification_approved`, `refund_processed`

---

## 19. Test Accounts

### Admin
| Email | Password |
|---|---|
| admin@nestmeal.com | admin123456 |

### Customers (password: `customer123`)
| Email | Name | City |
|---|---|---|
| priya.sharma@gmail.com | Priya Sharma | Bangalore |
| rahul.verma@gmail.com | Rahul Verma | Bangalore |
| anita.desai@gmail.com | Anita Desai | Bangalore |
| vikram.patel@gmail.com | Vikram Patel | Bangalore |
| sneha.iyer@gmail.com | Sneha Iyer | Bangalore |

### Cooks (password: `cook123456`)
| Email | Kitchen Name | Cuisine | Delivery |
|---|---|---|---|
| lakshmi.kitchen@gmail.com | Lakshmi's South Indian Kitchen | South Indian | Yes (flat 30) |
| fatima.biryani@gmail.com | Fatima's Biryani House | Hyderabadi | Yes (10/km) |
| chen.wei@gmail.com | Wei's Wok - Indo-Chinese | Indo-Chinese | No |
| maria.bakes@gmail.com | Maria's Bake Studio | Continental | Yes (flat 50) |
| rajesh.thali@gmail.com | Rajesh's North Indian Thali | North Indian | Yes (free) |

### Active Coupons
| Code | Type | Value | Min Order | Notes |
|---|---|---|---|---|
| WELCOME50 | 50% off | 50% | 200 | New users only |
| FLAT100 | Flat | 100 | 500 | All users, 2 per user |
| FREEDELIVERY | Free delivery | 0 | 0 | Delivery orders only |
| WEEKEND20 | 20% off | 20% | 300 | All users, 3 per user |

### Seeded Data Summary
- 19 meals across 5 cuisines
- 75 pickup slots (next 5 days, 3 slots/day/cook)
- 40 delivery slots (next 5 days, 2 slots/day for delivery-enabled cooks)
- 15 completed orders with payments and reviews
- 4 active coupons

---

## API Error Format

All validation errors follow this format:
```json
{
  "field_name": ["Error message."],
  "non_field_errors": ["General error message."]
}
```

Authentication errors:
```json
{
  "detail": "Authentication credentials were not provided."
}
```

Permission errors:
```json
{
  "detail": "You do not have permission to perform this action."
}
```

Not found:
```json
{
  "detail": "Not found."
}
```

---

## Pagination Format

All list endpoints return paginated responses:
```json
{
  "count": 19,
  "next": "http://localhost:8000/api/meals/?page=2",
  "previous": null,
  "results": [...]
}
```

Default page size: 20. Override with `?page_size=10`.

**Exception:** `GET /api/orders/` returns a flat array (not paginated).
