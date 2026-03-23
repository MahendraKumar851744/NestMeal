
**Version:** 1
**Status:** Draft 
**Last Updated:** March 2026

---

## 1. Product Overview

NestMeal is a niche food browsing and ordering platform that connects home cooks (vendors) with local customers. Unlike large-scale aggregators, the platform focuses on homemade, small-batch meals. Customers can choose between two fulfillment modes:

- **Pickup** — customers collect orders directly from the cook's kitchen or a designated pickup point.
- **Delivery** — cooks deliver orders to the customer's address.

Customers browse meals, place orders, select a fulfillment method, pay online, and rate their experience.

---

## 2. User Roles

### 2.1 Customer

The end-user who browses, orders, and receives meals.

|Attribute|Details|
|---|---|
|`customer_id`|System-generated UUID|
|`full_name`|String, required|
|`email`|String, unique, required (used for login)|
|`phone`|String, required (used for OTP & order updates)|
|`password_hash`|String, stored securely (bcrypt/argon2)|
|`profile_picture_url`|String, optional|
|`default_address`|Object — used for distance calculation and delivery|
|`saved_addresses[]`|Array of address objects|
|`wallet_balance`|Decimal, default 0.00 — for refunds/credits|
|`preferred_fulfillment`|Enum — `pickup`, `delivery`, `no_preference` (default: `no_preference`)|
|`is_verified`|Boolean, phone OTP verified|
|`status`|Enum — `active`, `suspended`, `deleted`|
|`created_at`|Timestamp|
|`updated_at`|Timestamp|

### 2.2 Cook (Vendor)

The individual who prepares and lists meals on the platform.

|Attribute|Details|
|---|---|
|`cook_id`|UUID, system-generated|
|`full_name`|String, required|
|`display_name`|String, shown publicly — Kitchen Name|
|`email`|String, unique, required|
|`phone`|String, required|
|`password_hash`|String, stored securely|
|`profile_picture_url`|String, optional|
|`bio`|Text, max 500 chars — short description of cooking style|
|`kitchen_address`|Object — street, city, state, zip, lat, lng|
|`pickup_locations`|List of locations|
|`pickup_instructions`|Text|
|`delivery_enabled`|Boolean — cook opts into offering delivery (default: `false`)|
|`delivery_radius_km`|Decimal — max delivery distance from kitchen address|
|`delivery_fee_type`|Enum — `flat`, `per_km`, `free` (null if delivery not enabled)|
|`delivery_fee_value`|Decimal — flat fee or per-km rate|
|`delivery_min_order`|Decimal — minimum order value for delivery eligibility|
|`food_safety_certificate_url`|String, optional|
|`government_id`|String, required for verification|
|`bank_account`|Object — account_number, ifsc/routing, account_holder_name|
|`commission_rate`|Decimal, platform-defined (default 10%)|
|`avg_rating`|Decimal, computed|
|`total_reviews`|Integer, computed|
|`is_verified`|Boolean, admin-approved after document review|
|`is_active`|Boolean, cook can toggle availability|
|`status`|Enum — `pending_verification`, `active`, `suspended`, `deactivated`|
|`created_at`|Timestamp|
|`updated_at`|Timestamp|

### 2.3 Platform Admin

Internal user who manages the platform.

|Attribute|Details|
|---|---|
|`admin_id`|UUID|
|`full_name`|String|
|`email`|String, unique|
|`role`|Enum — `super_admin`, `support_agent`, `finance_admin`|
|`permissions[]`|Array — granular permission flags|
|`status`|Enum — `active`, `inactive`|

---

## 3. Core Entity: Meal (Item)

A meal is the primary listing on the platform — the item a cook prepares and a customer orders.

### 3.1 Meal Data Model

|Attribute|Details|
|---|---|
|`meal_id`|UUID, system-generated|
|`cook_id`|FK → Cook|
|`title`|String, max 100 chars (e.g., "Chicken Biryani Family Pack")|
|`description`|Text, max 1000 chars — preparation method, taste notes, story|
|`short_description`|String, max 150 chars — shown on browse cards|
|`images[]`|Array of image URLs, min 1, max 5|
|`price`|Decimal, in base currency (e.g., INR or USD)|
|`discount_percentage`|Decimal|
|`currency`|Enum — `INR`, `USD`, `EUR` etc.|
|`category`|Enum — `breakfast`, `lunch`, `dinner`, `snack`, `dessert`, `beverage`, `meal_kit`|
|`cuisine_type`|String — e.g., "South Indian", "Continental"|
|`meal_type`|Enum — `veg`, `non_veg`, `egg`|
|`dietary_tags[]`|Enum array — `vegan`, `gluten_free`, `keto`, `low_carb`, `sugar_free`, `nut_free`, `dairy_free`|
|`allergen_info[]`|Array — declared allergens (e.g., "contains peanuts", "may contain soy")|
|`spice_level`|Enum — `mild`, `medium`, `spicy`, `extra_spicy`|
|`serving_size`|String — e.g., "Serves 2", "500g", "4 pieces"|
|`calories_approx`|Integer, optional — approximate kcal per serving|
|`preparation_time_mins`|Integer — estimated prep time|
|`fulfillment_modes[]`|Enum array — `pickup`, `delivery`. Cook sets which modes are available for this meal.|
|`is_available`|Boolean — cook can toggle on/off|
|`available_days[]`|Enum array — `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`|
|`total_orders`|Integer, computed|
|`avg_rating`|Decimal, computed|
|`tags[]`|Free-text tags for search — e.g., "comfort food", "party pack"|
|`is_featured`|Boolean — admin-promoted|
|`status`|Enum — `draft`, `active`, `paused`, `archived`|
|`created_at`|Timestamp|
|`updated_at`|Timestamp|

### 3.2 Meal Visibility Rules

- Meal appears in browse only when `status = active`, `is_available = true`, and the parent cook's `status = active` and `is_active = true`.
- If current day is not in `available_days[]`, the meal is hidden or shown as "available on [days]".
- Delivery option is shown on the meal detail page only if the cook has `delivery_enabled = true` AND `delivery` is listed in the meal's `fulfillment_modes[]`.
- If the customer's address is outside the cook's `delivery_radius_km`, the delivery option is hidden for that customer.

---

## 4. Pickup Slots

Pickup slots replace the delivery model entirely. Cooks define when and where customers can collect orders.

### 4.1 Pickup Slot Data Model

|Attribute|Details|
|---|---|
|`slot_id`|UUID|
|`cook_id`|FK → Cook|
|`date`|Date — the specific day|
|`start_time`|Time — e.g., 12:00 PM|
|`end_time`|Time — e.g., 12:30 PM|
|`max_orders`|Integer — capacity for this slot|
|`booked_orders`|Integer, computed — current bookings against this slot|
|`is_available`|Boolean — auto-set to false when `booked_orders >= max_orders`|
|`location_override`|Object, optional — if pickup for this slot differs from default|
|`status`|Enum — `open`, `full`, `cancelled`|
|`created_at`|Timestamp|

### 4.2 Slot Configuration Rules

- Cooks can create recurring slot templates (e.g., "every weekday 12:00–12:30, max 10 orders") which auto-generate daily slots.
- Cooks can cancel a slot up to 2 hours before `start_time`; all booked customers get notified and refunded.
- Customers choose a slot during checkout (pickup orders only). If a slot fills between adding to cart and checkout, the customer is prompted to pick another.
- Slot availability is shown in real-time on the meal detail page.

### 4.3 Recurring Slot Template

|Attribute|Details|
|---|---|
|`template_id`|UUID|
|`cook_id`|FK → Cook|
|`days_of_week[]`|Enum array — `mon` through `sun`|
|`start_time`|Time|
|`end_time`|Time|
|`max_orders`|Integer|
|`effective_from`|Date|
|`effective_until`|Date, optional — null means indefinite|
|`is_active`|Boolean|

---

## 5. Delivery

### 5.1 Overview

Delivery is an opt-in fulfillment mode that cooks can enable alongside (or instead of) pickup. When enabled, customers within the cook's delivery radius can have orders brought to their address. NestMeal supports two delivery models:

- **Cook-handled delivery** — the cook or their staff delivers directly. No third-party logistics involved.
- **Platform-facilitated delivery** _(future)_ — NestMeal integrates with a courier partner to dispatch a rider. Flagged as `is_platform_delivery = true`.

> **Scope for v1:** Cook-handled delivery is in scope for this release. Platform-facilitated courier integration is out of scope and will be addressed in a future milestone.

### 5.2 Delivery Zone Data Model

Each cook who enables delivery defines one or more delivery zones. The simplest zone is a radius around their kitchen address.

|Attribute|Details|
|---|---|
|`zone_id`|UUID|
|`cook_id`|FK → Cook|
|`zone_type`|Enum — `radius`, `polygon`|
|`radius_km`|Decimal — used when `zone_type = radius`|
|`polygon_coords[]`|Array of `{lat, lng}` — used when `zone_type = polygon`|
|`delivery_fee_type`|Enum — `flat`, `per_km`, `free`|
|`delivery_fee_value`|Decimal — flat fee or per-km rate (0 if free)|
|`min_order_value`|Decimal — minimum cart value for delivery in this zone|
|`estimated_delivery_mins`|Integer — estimated delivery time for this zone|
|`is_active`|Boolean|
|`created_at`|Timestamp|

### 5.3 Delivery Slot Data Model

Delivery orders are scheduled against delivery slots, giving cooks control over when they can fulfill deliveries.

|Attribute|Details|
|---|---|
|`delivery_slot_id`|UUID|
|`cook_id`|FK → Cook|
|`date`|Date|
|`start_time`|Time — e.g., 6:00 PM|
|`end_time`|Time — e.g., 8:00 PM|
|`max_orders`|Integer — delivery capacity for this window|
|`booked_orders`|Integer, computed|
|`is_available`|Boolean — auto-false when `booked_orders >= max_orders`|
|`status`|Enum — `open`, `full`, `cancelled`|
|`created_at`|Timestamp|

### 5.4 Delivery Order Fields

When a customer selects delivery at checkout, the order record carries additional delivery-specific fields (see Section 6 for the full order model):

|Attribute|Details|
|---|---|
|`fulfillment_type`|Enum — `pickup`, `delivery` (set at order creation)|
|`delivery_address`|Object — street, city, state, zip, lat, lng (snapshot at order time)|
|`delivery_fee`|Decimal — fee charged to customer|
|`delivery_slot_id`|FK → Delivery Slot (nullable for pickup orders)|
|`delivery_distance_km`|Decimal — calculated at checkout|
|`delivery_status`|Enum — see 5.5|
|`rider_name`|String, optional — for cook-handled delivery|
|`rider_phone`|String, optional|
|`tracking_url`|String, optional — for platform-facilitated delivery (future)|
|`estimated_delivery_at`|Timestamp — slot `end_time` used as initial estimate|
|`delivered_at`|Timestamp, optional — logged when delivery is confirmed|

### 5.5 Delivery Status Flow

```
placed → accepted → preparing → ready_for_pickup → out_for_delivery → delivered → completed
   │         │
   │         └→ rejected (by cook)
   └→ cancelled (by customer, if within cancellation window)
         └→ failed_delivery (customer unreachable, wrong address, etc.)
```

|Status|Description|
|---|---|
|`out_for_delivery`|Cook/rider has picked up the food and is en route to the customer|
|`delivered`|Cook/rider confirms delivery at the door; customer gets a notification|
|`completed`|Auto-set 1 hour after `delivered`; triggers review prompt|
|`failed_delivery`|Delivery attempt failed; cook logs reason; refund policy applies|

### 5.6 Delivery Fee Calculation

The delivery fee shown at checkout is computed as follows:

1. Find the applicable delivery zone for the customer's address (radius or polygon match).
2. If no zone matches, delivery is unavailable for that address.
3. If `delivery_fee_type = flat`: fee = `delivery_fee_value`.
4. If `delivery_fee_type = per_km`: fee = `delivery_distance_km × delivery_fee_value` (rounded to 2 decimal places).
5. If `delivery_fee_type = free`: fee = 0.
6. If `item_total < zone.min_order_value`: delivery option is blocked with a message indicating the minimum.

### 5.7 Cook Delivery Settings

Cooks manage delivery through a dedicated settings panel:

- Toggle `delivery_enabled` on/off globally for their kitchen.
- Define delivery zones (radius or polygon) with per-zone fees and minimums.
- Create delivery slot templates (recurring windows) similar to pickup slot templates.
- Set per-meal `fulfillment_modes[]` to offer pickup-only, delivery-only, or both per item.

### 5.8 Delivery Cancellation & Refund Policy

|Timing|Refund|
|---|---|
|More than 2 hours before delivery slot|100% refund (items + delivery fee)|
|1–2 hours before delivery slot|50% item refund; delivery fee non-refundable|
|Less than 1 hour before delivery slot|No refund|
|Cook rejects or cancels|100% refund (items + delivery fee)|
|Failed delivery (cook fault)|100% refund (items + delivery fee)|
|Failed delivery (customer unreachable)|No refund; delivery fee retained|

---

## 6. Order

### 6.1 Order Data Model

|Attribute|Details|
|---|---|
|`order_id`|UUID|
|`order_number`|String, human-readable (e.g., "HB-20260311-0042")|
|`customer_id`|FK → Customer|
|`cook_id`|FK → Cook|
|`fulfillment_type`|Enum — `pickup`, `delivery`|
|`slot_id`|FK → Pickup Slot (nullable for delivery orders)|
|`delivery_slot_id`|FK → Delivery Slot (nullable for pickup orders)|
|`delivery_address`|Object, optional — snapshot of delivery address at order time|
|`delivery_fee`|Decimal, optional — 0 for pickup|
|`delivery_status`|Enum — see Section 5.5 (nullable for pickup orders)|
|`items[]`|Array of order line items (see 6.2)|
|`item_total`|Decimal — sum of line items before fees|
|`platform_fee`|Decimal — service charge to customer|
|`tax_amount`|Decimal — applicable taxes|
|`discount_amount`|Decimal — promo/coupon deduction|
|`total_amount`|Decimal — `item_total + platform_fee + delivery_fee + tax - discount`|
|`coupon_code`|String, optional|
|`special_instructions`|Text, max 300 chars — customer notes to cook|
|`status`|Enum — see 6.3|
|`payment_id`|FK → Payment|
|`payment_status`|Enum — `pending`, `paid`, `refunded`, `partially_refunded`, `failed`|
|`pickup_code`|String, 6-digit — for pickup orders; used at handoff|
|`pickup_time_actual`|Timestamp, optional — logged when cook marks as picked up|
|`delivered_at`|Timestamp, optional — logged when delivery confirmed|
|`cancellation_reason`|Text, optional|
|`cancelled_by`|Enum — `customer`, `cook`, `system`, optional|
|`created_at`|Timestamp|
|`updated_at`|Timestamp|

### 6.2 Order Line Item

|Attribute|Details|
|---|---|
|`line_item_id`|UUID|
|`order_id`|FK → Order|
|`meal_id`|FK → Meal|
|`meal_title`|String — snapshot at order time|
|`quantity`|Integer|
|`unit_price`|Decimal — price at time of order|
|`line_total`|Decimal — quantity × unit_price|

### 6.3 Order Status Flow

**Pickup:**

```
placed → accepted → preparing → ready_for_pickup → picked_up → completed
   │         │
   │         └→ rejected (by cook)
   └→ cancelled (by customer, if within cancellation window)
```

**Delivery:**

```
placed → accepted → preparing → ready_for_pickup → out_for_delivery → delivered → completed
   │         │
   │         └→ rejected (by cook)
   └→ cancelled (by customer, if within cancellation window)
```

|Status|Description|
|---|---|
|`placed`|Payment successful, order sent to cook|
|`accepted`|Cook confirms they will prepare the order|
|`preparing`|Cook has started preparation|
|`ready_for_pickup`|Food is ready; customer notified (with pickup code for pickup orders)|
|`picked_up`|Cook verifies `pickup_code` and marks handoff complete _(pickup only)_|
|`out_for_delivery`|Cook/rider is en route to customer _(delivery only)_|
|`delivered`|Cook/rider confirms delivery at the door _(delivery only)_|
|`completed`|Auto-set 1 hour after pickup/delivery; triggers review prompt|
|`rejected`|Cook declines; customer is fully refunded|
|`cancelled`|Customer cancels; refund depends on cancellation policy|

### 6.4 Cancellation Policy

|Timing|Refund|
|---|---|
|More than 2 hours before slot start|100% refund (items + delivery fee if applicable)|
|1–2 hours before slot start|50% refund on items; delivery fee non-refundable|
|Less than 1 hour before slot start|No refund|
|Cook rejects or cancels|100% refund always|
|Failed delivery (cook fault)|100% refund including delivery fee|

---

## 7. Payment

### 7.1 Payment Data Model

|Attribute|Details|
|---|---|
|`payment_id`|UUID|
|`order_id`|FK → Order|
|`customer_id`|FK → Customer|
|`amount`|Decimal — total charged (includes delivery fee for delivery orders)|
|`currency`|String|
|`method`|Enum — `upi`, `credit_card`, `debit_card`, `net_banking`, `wallet`|
|`gateway`|String — e.g., "razorpay", "stripe"|
|`gateway_transaction_id`|String — external reference|
|`gateway_status`|String — raw status from gateway|
|`status`|Enum — `initiated`, `success`, `failed`, `refund_initiated`, `refunded`|
|`refund_amount`|Decimal, optional|
|`refund_reason`|String, optional|
|`refund_initiated_at`|Timestamp, optional|
|`paid_at`|Timestamp|
|`created_at`|Timestamp|

### 7.2 Cook Payout

Delivery fees collected from customers are passed through to the cook in full — platform commission applies only to `item_total`, not the delivery fee.

|Attribute|Details|
|---|---|
|`payout_id`|UUID|
|`cook_id`|FK → Cook|
|`period_start`|Date|
|`period_end`|Date|
|`gross_amount`|Decimal — total order `item_total` values in period|
|`delivery_fees_collected`|Decimal — total delivery fees in period (passed through in full)|
|`commission_deducted`|Decimal — platform commission on `item_total` only|
|`net_amount`|Decimal — `gross_amount + delivery_fees_collected - commission_deducted`|
|`status`|Enum — `pending`, `processing`, `completed`, `failed`|
|`bank_reference`|String|
|`paid_at`|Timestamp|

### 7.3 Payment Flow

1. Customer proceeds to checkout → selects fulfillment type (pickup or delivery) → selects payment method.
2. For delivery: delivery address is validated against cook's delivery zones; fee and ETA shown before payment.
3. Platform initiates payment via gateway (Razorpay/Stripe).
4. On success → order status moves to `placed`; `pickup_code` generated (pickup) or delivery slot confirmed (delivery).
5. On failure → customer is prompted to retry; no order is created.
6. Cook payouts processed weekly: item commission deducted, delivery fees passed through in full.

---

## 8. Ratings & Reviews

### 8.1 Review Data Model

|Attribute|Details|
|---|---|
|`review_id`|UUID|
|`order_id`|FK → Order (one review per order)|
|`customer_id`|FK → Customer|
|`cook_id`|FK → Cook|
|`meal_id`|FK → Meal (primary meal reviewed, if order had multiple items)|
|`rating`|Integer, 1–5|
|`delivery_rating`|Integer, 1–5, optional — speed, packaging, handoff; only for delivery orders|
|`comment`|Text, max 500 chars, optional|
|`images[]`|Array of image URLs, max 3 — customer-uploaded food photos|
|`cook_reply`|Text, max 300 chars, optional|
|`cook_replied_at`|Timestamp, optional|
|`is_visible`|Boolean — admin can hide abusive reviews|
|`is_flagged`|Boolean — flagged for moderation|
|`created_at`|Timestamp|
|`updated_at`|Timestamp|

### 8.2 Rating Rules

- A customer can only review an order with status `completed`.
- Review window: 7 days after `completed` timestamp.
- One review per order. Can be edited within 48 hours of submission.
- Delivery orders prompt a separate `delivery_rating` (speed, packaging, handoff experience).
- Cook can reply once per review.
- Aggregate `avg_rating` on both Meal and Cook profiles is recalculated on every new review.
- Reviews with rating ≤ 2 auto-flag for admin review (quality monitoring).

---

## 9. Browse & Discovery Features

### 9.1 Home Feed

- **Nearby Cooks** — sorted by distance from customer's default/current address.
- **Top Rated** — cooks/meals with highest avg_rating and minimum 10 reviews.
- **New on NestMeal** — cooks registered in the last 30 days.
- **Available Now** — meals with an open pickup or delivery slot within the next 2 hours.
- **Delivers to You** _(new)_ — meals where the customer's saved address falls within the cook's delivery zone.
- **Category Quick Filters** — breakfast, lunch, dinner, snack, dessert, beverage.
- **Personalized Recommendations** — based on dietary preferences, past orders, and cuisine affinity.

### 9.2 Search & Filters

|Filter|Type|Options|
|---|---|---|
|Keyword|Free text|Searches meal title, description, tags, cook name|
|Cuisine|Multi-select|south_indian, north_indian, chinese, italian, etc.|
|Meal Type|Multi-select|veg, non_veg, egg|
|Dietary|Multi-select|vegan, gluten_free, keto, etc.|
|Category|Single-select|breakfast, lunch, dinner, snack, dessert, beverage|
|Spice Level|Single-select|mild, medium, spicy, extra_spicy|
|Price Range|Range slider|Min–Max (excludes delivery fee)|
|Rating|Min threshold|3+, 4+, 4.5+|
|Distance|Range|Within 1km, 3km, 5km, 10km|
|Fulfillment|Multi-select|`pickup`, `delivery` — filters to meals offering that mode|
|Delivers to Me|Toggle|Show only meals that deliver to customer's saved address|
|Available Today|Toggle|Show only meals with open slots today|
|Sort By|Single-select|distance, rating, price_low_high, price_high_low, popularity|

### 9.3 Meal Detail Page

Displays: all meal attributes, cook profile card (name, photo, rating, bio), available pickup slots for next 3 days, delivery availability badge (if delivery is enabled and customer is in range), delivery fee and ETA estimate, reviews section, "Add to Cart" with fulfillment mode selector (Pickup / Delivery toggle), allergen warnings (highlighted if matching customer's `allergen_flags`).

### 9.4 Cook Profile Page

Displays: cook info, all active meals listed, aggregate stats (total orders fulfilled, avg rating, member since), reviews across all meals, pickup location on a map, delivery zone map overlay (if delivery is enabled).

---

## 10. Notifications

|Event|Channel|Recipient|
|---|---|---|
|Order placed|Push|Cook|
|Order accepted|Push|Customer|
|Order rejected|Push|Customer|
|Order ready for pickup|Push|Customer (pickup only)|
|Out for delivery|Push|Customer (delivery only)|
|Order delivered|Push|Customer (delivery only)|
|Pickup reminder (30 min before slot)|Push|Customer (pickup only)|
|Missed pickup (no show)|Push|Customer + Cook|
|Failed delivery attempt|Push|Customer + Cook|
|Review prompt (1 hour after pickup/delivery)|Push|Customer|
|Cook reply to review|Push|Customer|
|Slot cancelled by cook|Push|All affected customers|
|Payout completed|Email|Cook|
|Account verification approved|Email|Cook|
|Refund processed|Push|Customer|

---

## 11. Coupon / Promotion System

### 11.1 Coupon Data Model

|Attribute|Details|
|---|---|
|`coupon_id`|UUID|
|`code`|String, unique, uppercase (e.g., "FIRST50")|
|`description`|String|
|`discount_type`|Enum — `percentage`, `flat_amount`|
|`discount_value`|Decimal — e.g., 50 for 50% or 100 for flat ₹100|
|`applies_to_delivery_fee`|Boolean — if true, discount also applies to the delivery fee|
|`min_order_value`|Decimal — minimum cart value to apply|
|`valid_from`|Timestamp|
|`valid_until`|Timestamp|
|`usage_limit_total`|Integer — total redemptions allowed|
|`usage_limit_per_user`|Integer — per customer|
|`used_count`|Integer, computed|
|`applicable_to`|Enum — `all`, `specific_cooks`, `specific_meals`, `new_users`|
|`applicable_fulfillment`|Enum — `all`, `pickup_only`, `delivery_only` (default: `all`)|
|`applicable_ids[]`|Array of cook_ids or meal_ids|
|`is_active`|Boolean|
|`created_by`|Enum — `admin`, `cook`|

---

## 12. Platform Configuration & Business Rules

### 12.1 Commission & Fees

- **Platform commission on cook:** Configurable, default 10% of order `item_total`. Does not apply to delivery fees.
- **Platform fee to customer:** Configurable, can be flat or percentage-based. Applied regardless of fulfillment type.
- **Delivery fee:** Set by cook per zone. Shown separately at checkout. Not subject to platform commission.
- **Tax handling:** Tax calculated on (`item_total + platform_fee`). Delivery fee tax treatment is region-configurable.

### 12.2 Delivery Configuration Defaults

|Setting|Default|
|---|---|
|`delivery_enabled` for new cooks|`false` (opt-in)|
|Default `delivery_radius_km`|5 km|
|Max `delivery_radius_km`|Platform-configurable (suggested cap: 20 km)|
|Delivery slot duration|Configurable per cook (suggested: 1–2 hour windows)|
|Failed delivery hold period|24 hours before refund is auto-initiated|