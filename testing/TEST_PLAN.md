# NestMeal Comprehensive Test Plan

**Version:** 1.0
**Date:** 2026-03-29
**Application:** NestMeal - Home-cooked meal marketplace
**Stack:** Django REST API + Flutter Web/Mobile

---

## 1. Test Scope

### In Scope
- All 50+ REST API endpoints (9 Django apps)
- Authentication & authorization (JWT, OTP, role-based access)
- Business logic (pricing, order flows, status transitions, coupons)
- Security (IDOR, injection, auth bypass, input validation)
- Flutter Web UI (smoke tests, navigation, responsiveness)
- Data integrity (field validation, required fields, edge cases)

### Out of Scope
- Mobile native testing (iOS/Android) - requires physical devices
- Load/stress testing - requires dedicated infrastructure
- Payment gateway integration (Stripe) - currently mocked
- Push notifications (Firebase) - not yet integrated
- Real SMS OTP delivery - mocked with "1234"

---

## 2. Test Environment

| Component | Details |
|-----------|---------|
| Backend | Django 5.2 + DRF 3.15 @ http://127.0.0.1:8000 |
| Frontend | Flutter Web (HTML renderer) @ http://localhost:8080 |
| Database | SQLite with seed data (5 customers, 5 cooks, 19 meals, 15 orders) |
| Auth | JWT (2h access, 7d refresh), Mock OTP (accepts "1234") |
| Payments | Mocked Razorpay (simulates success) |

### Test Accounts (Seed Data)

| Role | Emails | Password |
|------|--------|----------|
| Customer | alice@test.com, bob@test.com, charlie@test.com, diana@test.com, emma@test.com | Test@1234 |
| Cook | priya@test.com, rahul@test.com, anita@test.com, vijay@test.com, lakshmi@test.com | Test@1234 |

---

## 3. Test Categories & Cases

### 3.1 Authentication (test_01_auth.py) - 25 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| AUTH-01 | Register customer with valid data | CRITICAL | - |
| AUTH-02 | Register cook with valid data | CRITICAL | - |
| AUTH-03 | Reject duplicate email registration | CRITICAL | - |
| AUTH-04 | Reject registration with missing fields | HIGH | - |
| AUTH-05 | Reject invalid email format | HIGH | - |
| AUTH-06 | Detect weak password acceptance | HIGH | - |
| AUTH-07 | Reject invalid role | CRITICAL | - |
| AUTH-08 | SQL injection in email field | CRITICAL | - |
| AUTH-09 | XSS payload in full_name | HIGH | - |
| AUTH-10 | Customer login success | CRITICAL | - |
| AUTH-11 | Cook login success | CRITICAL | - |
| AUTH-12 | Reject wrong password | HIGH | - |
| AUTH-13 | Reject non-existent user login | HIGH | - |
| AUTH-14 | Reject empty login body | MEDIUM | - |
| AUTH-15 | JWT format validation | HIGH | - |
| AUTH-16 | Token refresh success | HIGH | - |
| AUTH-17 | Reject invalid refresh token | HIGH | - |
| AUTH-18 | Get authenticated user profile | HIGH | - |
| AUTH-19 | Reject unauthenticated profile access | CRITICAL | - |
| AUTH-20 | Update profile name | MEDIUM | - |
| AUTH-21 | Prevent role escalation via profile update | CRITICAL | - |
| AUTH-22 | Send OTP | HIGH | #13 |
| AUTH-23 | Verify mock OTP "1234" | HIGH | #13 |
| AUTH-24 | Reject wrong OTP | MEDIUM | - |
| AUTH-25 | OTP rate limiting | MEDIUM | - |

### 3.2 Meals (test_02_meals.py) - 22 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| MEAL-01 | List meals publicly | CRITICAL | - |
| MEAL-02 | Meals pagination | MEDIUM | - |
| MEAL-03 | Filter by category (breakfast/lunch/dinner/snack/dessert) | HIGH | #55 |
| MEAL-04 | Filter by meal type (veg/non-veg/egg) | HIGH | - |
| MEAL-05 | Filter by spice level | MEDIUM | - |
| MEAL-06 | Search meals by title | HIGH | - |
| MEAL-07 | Order meals by price/rating | MEDIUM | - |
| MEAL-08 | Filter available meals only | HIGH | #42 |
| MEAL-09 | Verify required fields in meal response | MEDIUM | - |
| MEAL-10 | Effective price calculation with discount | HIGH | - |
| MEAL-11 | Featured meals endpoint | MEDIUM | - |
| MEAL-12 | Featured meals are actually featured | MEDIUM | - |
| MEAL-13 | Available-now endpoint | MEDIUM | - |
| MEAL-14 | Meal detail by ID | HIGH | - |
| MEAL-15 | 404 for invalid meal ID | MEDIUM | - |
| MEAL-16 | Cook creates meal | CRITICAL | - |
| MEAL-17 | Customer cannot create meal | CRITICAL | - |
| MEAL-18 | Unauthenticated cannot create meal | HIGH | - |
| MEAL-19 | Cook updates meal | HIGH | - |
| MEAL-20 | Cook uploads meal image | CRITICAL | #32, #33 |
| MEAL-21 | Cook adds meal extras | HIGH | #57 |
| MEAL-22 | Cook creates pickup slots | HIGH | #41 |

### 3.3 Orders (test_03_orders.py) - 18 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| ORD-01 | Customer lists orders | HIGH | - |
| ORD-02 | Orders require auth | CRITICAL | - |
| ORD-03 | Cook lists received orders | HIGH | - |
| ORD-04 | Order list has required fields | MEDIUM | - |
| ORD-05 | Filter orders by status | MEDIUM | - |
| ORD-06 | Create pickup order | CRITICAL | - |
| ORD-07 | Order without slot fails | HIGH | - |
| ORD-08 | Unauthenticated order fails | CRITICAL | - |
| ORD-09 | Cook cannot place orders | HIGH | - |
| ORD-10 | Zero quantity rejected | HIGH | - |
| ORD-11 | Negative quantity rejected | CRITICAL | - |
| ORD-12 | Order detail with items | HIGH | - |
| ORD-13 | Cook accepts order | HIGH | #50 |
| ORD-14 | Invalid status transition rejected | CRITICAL | #50 |
| ORD-15 | Customer cannot update status | CRITICAL | - |
| ORD-16 | Cancel order with reason | CRITICAL | #38 |
| ORD-17 | Cancel without reason fails | HIGH | #38 |
| ORD-18 | Pickup verification endpoint | HIGH | #51 |

### 3.4 Payments (test_04_payments.py) - 8 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| PAY-01 | List payments | HIGH | - |
| PAY-02 | Payments require auth | CRITICAL | - |
| PAY-03 | Payment required fields | MEDIUM | - |
| PAY-04 | Wallet top-up endpoint exists | HIGH | #14 |
| PAY-05 | Reject negative wallet top-up | CRITICAL | - |
| PAY-06 | Reject zero wallet top-up | MEDIUM | - |
| PAY-07 | Cook lists payouts | MEDIUM | - |
| PAY-08 | Payouts require auth | HIGH | - |

### 3.5 Reviews & Coupons (test_05_reviews_coupons.py) - 10 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| REV-01 | List reviews publicly | MEDIUM | - |
| REV-02 | Review required fields | LOW | - |
| REV-03 | Review creation requires auth | HIGH | - |
| REV-04 | Cook cannot create reviews | HIGH | - |
| REV-05 | Rating validation (1-5) | MEDIUM | - |
| CPN-01 | List coupons publicly | MEDIUM | - |
| CPN-02 | Coupon required fields | LOW | - |
| CPN-03 | Customer cannot create coupons | CRITICAL | - |
| CPN-04 | Cook cannot create coupons | CRITICAL | - |
| CPN-05 | Expired coupon validation | MEDIUM | - |

### 3.6 Delivery, Stories, Notifications (test_06_delivery_stories_notifications.py) - 12 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| DEL-01 | List delivery zones | MEDIUM | - |
| DEL-02 | Cook creates delivery zone | MEDIUM | - |
| DEL-03 | Customer cannot create zones | HIGH | - |
| DEL-04 | List delivery slots | MEDIUM | - |
| DEL-05 | Past slots not available | HIGH | #20 |
| DEL-06 | Calculate delivery fee | MEDIUM | - |
| STR-01 | Story feed | MEDIUM | - |
| STR-02 | Cook views own stories | MEDIUM | - |
| STR-03 | Customer cannot create stories | HIGH | - |
| STR-04 | Cook stories by ID | MEDIUM | - |
| NOT-01 | List notifications | MEDIUM | - |
| NOT-02 | Notifications require auth | HIGH | - |

### 3.7 Security (test_07_security.py) - 13 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| SEC-01 | IDOR: cross-customer order access | CRITICAL | - |
| SEC-02 | Customer cannot access cook profiles | HIGH | - |
| SEC-03 | Cook cannot access customer profiles | HIGH | - |
| SEC-04 | Oversized payload handling | HIGH | - |
| SEC-05 | Unicode character handling | MEDIUM | - |
| SEC-06 | Null values in required fields | MEDIUM | - |
| SEC-07 | CORS headers present | LOW | - |
| SEC-08 | Server version not exposed | LOW | - |
| SEC-09 | Expired token rejected | HIGH | - |
| SEC-10 | Protected endpoints require auth | CRITICAL | - |
| SEC-11 | Malformed auth header handling | HIGH | - |
| SEC-12 | 404 returns JSON | LOW | - |
| SEC-13 | All public endpoints respond | CRITICAL | - |

### 3.8 UI Smoke Tests (test_01_web_smoke.py) - 10 tests

| ID | Test Case | Priority | Tracker Issue |
|----|-----------|----------|---------------|
| UI-01 | App loads without errors | CRITICAL | - |
| UI-02 | No severe console errors | HIGH | - |
| UI-03 | Mobile viewport rendering | MEDIUM | - |
| UI-04 | Login screen elements visible | HIGH | - |
| UI-05 | Input fields present (HTML mode) | MEDIUM | - |
| UI-06 | Direct URL navigation | MEDIUM | - |
| UI-07 | Page load time < 10s | MEDIUM | - |
| UI-08 | Memory usage check | LOW | - |
| UI-09 | Page title | LOW | - |
| UI-10 | Accessibility: lang attribute | LOW | - |

---

## 4. Mapping to Known Issue Tracker

| Tracker # | Issue | Test Coverage |
|-----------|-------|---------------|
| #12 | Cook order acceptance window | ORD-06 (checks acceptance_deadline) |
| #14 | Wallet: no top-up option | PAY-04, PAY-05, PAY-06 |
| #20 | Delivery dates outdated | DEL-05 |
| #32 | Cook cannot upload meal image | MEAL-20 |
| #33 | Meal images not showing | MEAL-20 |
| #38 | Cannot cancel order | ORD-16, ORD-17 |
| #41 | Cook pickup slots | MEAL-22 |
| #42 | Hidden meals still display | MEAL-08 |
| #50 | Order status flows | ORD-13, ORD-14 |
| #51 | Pickup verification OTP | ORD-18 |
| #53 | Stripe payment integration | PAY-01 (basic only, Stripe not tested) |
| #55 | Category visibility | MEAL-03 |
| #56 | Cutoff time feature | MEAL-10 (effective price only) |
| #57 | Meal extras pricing | MEAL-21 |

---

## 5. How to Run Tests

```bash
cd testing/

# Install dependencies
pip install -r requirements.txt

# Start backend first
cd ../Backend && python manage.py runserver &

# Run all tests
python run_tests.py

# Run only API tests
python run_tests.py --api

# Run only UI tests (requires Flutter web running)
# flutter run -d chrome --web-renderer html (in another terminal)
python run_tests.py --ui

# Run smoke tests only
python run_tests.py --smoke

# Run critical issue tests only
python run_tests.py --critical

# Run specific test file
pytest api_tests/test_01_auth.py -v

# Run tests matching a pattern
pytest -k "test_login" -v
```

---

## 6. Reports

After running tests:
- **HTML Test Report:** `testing/reports/test_report_<timestamp>.html`
- **Issues Found:** `testing/reports/issues_found.md` (auto-generated)

---

## 7. Test Totals

| Category | Test Count |
|----------|-----------|
| Authentication | 25 |
| Meals | 22 |
| Orders | 18 |
| Payments | 8 |
| Reviews & Coupons | 10 |
| Delivery/Stories/Notifications | 12 |
| Security | 13 |
| UI Smoke | 10 |
| **Total** | **118** |
