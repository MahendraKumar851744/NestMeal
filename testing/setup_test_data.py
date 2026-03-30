#!/usr/bin/env python3
"""
NestMeal Test Data Setup
========================
Creates all test data needed for the full test suite from scratch.
Run this on a clean/flushed database before running tests.

Usage:
    cd Backend
    python ../testing/setup_test_data.py
"""

import os
import sys
import django
from decimal import Decimal
from datetime import date, timedelta, time

# Add backend to path
backend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Backend")
sys.path.insert(0, backend_dir)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "nestmeal.settings")
django.setup()

from accounts.models import User, CustomerProfile, CookProfile, Address, PickupLocation
from meals.models import Meal, MealExtra, PickupSlot, RecurringSlotTemplate
from orders.models import Order, OrderItem
from reviews.models import Review
from coupons.models import Coupon
from delivery.models import DeliveryZone, DeliverySlot
from notifications.models import Notification


def create_users():
    """Create test customers, cooks, and admin."""
    print("\n--- Users ---")

    # Customers
    customers = []
    customer_data = [
        ("testcustomer@nestmeal.com", "Test Customer", "+61400111000"),
        ("testcustomer2@nestmeal.com", "Test Customer 2", "+61400111999"),
        ("alice.melbourne@nestmeal.com", "Alice Johnson", "+61400200001"),
        ("bob.sydney@nestmeal.com", "Bob Smith", "+61400200002"),
        ("charlie.brisbane@nestmeal.com", "Charlie Brown", "+61400200003"),
    ]
    for email, name, phone in customer_data:
        u = User.objects.create_user(
            email=email, password="TestPass@123",
            full_name=name, phone=phone,
            role="customer", is_verified=True,
        )
        cp = CustomerProfile.objects.create(user=u)
        customers.append(u)
        print(f"  [+] Customer: {email}")

    # Cooks
    cooks = []
    cook_data = [
        {
            "email": "testcook@nestmeal.com",
            "full_name": "Test Cook",
            "phone": "+61400222000",
            "display_name": "Test Kitchen",
            "kitchen_street": "100 Test St",
            "kitchen_city": "Melbourne",
            "kitchen_state": "VIC",
            "kitchen_zip": "3000",
            "bio": "Home-style meals made with love",
            "delivery_enabled": True,
            "delivery_fee_type": "flat",
            "delivery_fee_value": Decimal("5.00"),
        },
        {
            "email": "priya.cook@nestmeal.com",
            "full_name": "Priya Sharma",
            "phone": "+61400222001",
            "display_name": "Priya's Kitchen",
            "kitchen_street": "42 Curry Lane",
            "kitchen_city": "Melbourne",
            "kitchen_state": "VIC",
            "kitchen_zip": "3001",
            "bio": "Authentic Indian home cooking - just like maa used to make",
            "delivery_enabled": True,
            "delivery_fee_type": "per_km",
            "delivery_fee_value": Decimal("2.00"),
        },
        {
            "email": "chen.cook@nestmeal.com",
            "full_name": "Chen Wei",
            "phone": "+61400222002",
            "display_name": "Chen's Dumplings",
            "kitchen_street": "88 Noodle Rd",
            "kitchen_city": "Sydney",
            "kitchen_state": "NSW",
            "kitchen_zip": "2000",
            "bio": "Handmade dumplings and dim sum",
            "delivery_enabled": False,
        },
        {
            "email": "maria.cook@nestmeal.com",
            "full_name": "Maria Santos",
            "phone": "+61400222003",
            "display_name": "Maria's Bakery",
            "kitchen_street": "15 Pastry Ave",
            "kitchen_city": "Brisbane",
            "kitchen_state": "QLD",
            "kitchen_zip": "4000",
            "bio": "Fresh baked goods daily",
            "delivery_enabled": True,
            "delivery_fee_type": "free",
            "delivery_fee_value": Decimal("0.00"),
        },
    ]
    for cd in cook_data:
        email = cd.pop("email")
        full_name = cd.pop("full_name")
        phone = cd.pop("phone")
        u = User.objects.create_user(
            email=email, password="TestPass@123",
            full_name=full_name, phone=phone,
            role="cook", is_verified=True,
        )
        cook = CookProfile.objects.create(
            user=u, status="active", is_active=True, **cd,
        )
        cooks.append(cook)
        print(f"  [+] Cook: {email} ({cd.get('display_name', '')})")

    # Admin
    admin = User.objects.create_superuser(
        email="admin@nestmeal.com", password="AdminPass@123",
        full_name="NestMeal Admin", phone="+61400000001",
    )
    print(f"  [+] Admin: admin@nestmeal.com")

    return customers, cooks, admin


def create_addresses(customers):
    """Create addresses for customers."""
    print("\n--- Addresses ---")
    addresses = [
        ("Home", "10 Lonsdale St", "Melbourne", "VIC", "3000", -37.8116, 144.9628, True),
        ("Work", "200 Collins St", "Melbourne", "VIC", "3000", -37.8143, 144.9687, False),
        ("Home", "50 George St", "Sydney", "NSW", "2000", -33.8688, 151.2093, True),
        ("Home", "5 Queen St", "Brisbane", "QLD", "4000", -27.4705, 153.0260, True),
    ]
    for i, (label, street, city, state, zipcode, lat, lng, default) in enumerate(addresses):
        cust = customers[min(i, len(customers) - 1)]
        Address.objects.create(
            user=cust, label=label, street=street, city=city,
            state=state, zip_code=zipcode, latitude=lat, longitude=lng,
            is_default=default,
        )
    print(f"  [+] Created {len(addresses)} addresses")


def create_pickup_locations(cooks):
    """Create pickup locations for cooks."""
    print("\n--- Pickup Locations ---")
    for cook in cooks:
        PickupLocation.objects.create(
            cook=cook, label="Main Kitchen",
            street=cook.kitchen_street, city=cook.kitchen_city,
            state=cook.kitchen_state, zip_code=cook.kitchen_zip,
            is_active=True,
        )
    print(f"  [+] Created {len(cooks)} pickup locations")


def create_meals(cooks):
    """Create diverse meals for each cook."""
    print("\n--- Meals ---")
    meals_data = {
        0: [  # Test Kitchen
            {"title": "Chicken Biryani", "price": 18.50, "category": "lunch", "meal_type": "non_veg", "spice_level": "spicy", "cuisine_type": "Indian", "description": "Fragrant basmati rice with tender chicken", "discount_percentage": 10, "is_featured": True},
            {"title": "Paneer Butter Masala", "price": 15.00, "category": "dinner", "meal_type": "veg", "spice_level": "medium", "cuisine_type": "Indian", "description": "Creamy tomato curry with soft paneer cubes"},
            {"title": "Masala Dosa", "price": 10.00, "category": "breakfast", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "South Indian", "description": "Crispy dosa with potato filling"},
            {"title": "Mango Lassi", "price": 5.00, "category": "beverage", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "Indian", "description": "Sweet mango yogurt drink"},
            {"title": "Gulab Jamun", "price": 6.50, "category": "dessert", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "Indian", "description": "Sweet milk dumplings in rose syrup"},
        ],
        1: [  # Priya's Kitchen
            {"title": "Chole Bhature", "price": 12.00, "category": "lunch", "meal_type": "veg", "spice_level": "spicy", "cuisine_type": "Punjabi", "description": "Spicy chickpea curry with fried bread"},
            {"title": "Dal Makhani", "price": 13.50, "category": "dinner", "meal_type": "veg", "spice_level": "medium", "cuisine_type": "Punjabi", "description": "Slow-cooked black lentils in butter cream"},
            {"title": "Aloo Paratha", "price": 8.00, "category": "breakfast", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "North Indian", "description": "Stuffed potato flatbread with butter"},
            {"title": "Rajma Chawal", "price": 11.00, "category": "lunch", "meal_type": "veg", "spice_level": "medium", "cuisine_type": "Punjabi", "description": "Kidney bean curry with steamed rice", "discount_percentage": 15},
        ],
        2: [  # Chen's Dumplings
            {"title": "Pork Dumplings (12pc)", "price": 14.00, "category": "lunch", "meal_type": "non_veg", "spice_level": "mild", "cuisine_type": "Chinese", "description": "Handmade pork and cabbage dumplings"},
            {"title": "Vegetable Spring Rolls (6pc)", "price": 9.00, "category": "snack", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "Chinese", "description": "Crispy fried spring rolls"},
            {"title": "Kung Pao Chicken", "price": 16.00, "category": "dinner", "meal_type": "non_veg", "spice_level": "extra_spicy", "cuisine_type": "Sichuan", "description": "Spicy stir-fried chicken with peanuts", "is_featured": True},
        ],
        3: [  # Maria's Bakery
            {"title": "Sourdough Loaf", "price": 8.50, "category": "snack", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "Artisan", "description": "Fresh baked sourdough bread"},
            {"title": "Chocolate Croissant (2pc)", "price": 7.00, "category": "breakfast", "meal_type": "veg", "spice_level": "mild", "cuisine_type": "French", "description": "Flaky butter croissants with dark chocolate", "is_featured": True},
            {"title": "Banana Bread", "price": 6.00, "category": "dessert", "meal_type": "egg", "spice_level": "mild", "cuisine_type": "Homestyle", "description": "Moist banana bread with walnuts"},
        ],
    }

    all_meals = []
    for cook_idx, cook_meals in meals_data.items():
        cook = cooks[cook_idx]
        for md in cook_meals:
            meal = Meal.objects.create(
                cook=cook,
                fulfillment_modes=["pickup", "delivery"] if cook.delivery_enabled else ["pickup"],
                is_available=True,
                available_days=["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
                status="active",
                serving_size="1 serving",
                preparation_time_mins=30,
                currency="AUD",
                **md,
            )
            all_meals.append(meal)
    print(f"  [+] Created {len(all_meals)} meals across {len(cooks)} cooks")

    # Add extras to some meals
    extras_count = 0
    for meal in all_meals[:6]:
        MealExtra.objects.create(meal=meal, name="Extra Rice", price=Decimal("3.00"), is_available=True)
        MealExtra.objects.create(meal=meal, name="Extra Sauce", price=Decimal("1.50"), is_available=True)
        extras_count += 2
    print(f"  [+] Created {extras_count} meal extras")

    return all_meals


def create_slots(cooks):
    """Create pickup and delivery slots for next 14 days."""
    print("\n--- Slots ---")
    pickup_count = 0
    delivery_count = 0

    for cook in cooks:
        for i in range(1, 15):
            slot_date = date.today() + timedelta(days=i)

            # Pickup: lunch window
            PickupSlot.objects.create(
                cook=cook, date=slot_date,
                start_time=time(12, 0), end_time=time(14, 0),
                max_orders=10, is_available=True, status="open",
                location_label="Main Kitchen", location_street=cook.kitchen_street,
            )
            pickup_count += 1

            # Pickup: dinner window
            PickupSlot.objects.create(
                cook=cook, date=slot_date,
                start_time=time(18, 0), end_time=time(20, 0),
                max_orders=8, is_available=True, status="open",
                location_label="Main Kitchen", location_street=cook.kitchen_street,
            )
            pickup_count += 1

            # Delivery slots for delivery-enabled cooks
            if cook.delivery_enabled:
                DeliverySlot.objects.create(
                    cook=cook, date=slot_date,
                    start_time=time(12, 0), end_time=time(14, 0),
                    max_orders=5, is_available=True, status="open",
                )
                delivery_count += 1

    print(f"  [+] Created {pickup_count} pickup slots")
    print(f"  [+] Created {delivery_count} delivery slots")

    # Recurring templates
    for cook in cooks[:2]:
        RecurringSlotTemplate.objects.create(
            cook=cook, days_of_week=["mon", "wed", "fri"],
            start_time=time(12, 0), end_time=time(14, 0),
            max_orders=10, effective_from=date.today(),
            slot_type="pickup", is_active=True,
        )
    print(f"  [+] Created 2 recurring slot templates")


def create_coupons():
    """Create test coupons."""
    print("\n--- Coupons ---")
    from django.utils import timezone
    now = timezone.now()

    Coupon.objects.create(
        code="WELCOME10", discount_type="percentage", discount_value=Decimal("10.00"),
        min_order_value=Decimal("15.00"), usage_limit_total=100, usage_limit_per_user=1,
        valid_from=now, valid_until=now + timedelta(days=90), is_active=True,
        applicable_fulfillment="all",
    )
    Coupon.objects.create(
        code="FLAT5", discount_type="flat", discount_value=Decimal("5.00"),
        min_order_value=Decimal("20.00"), usage_limit_total=50, usage_limit_per_user=2,
        valid_from=now, valid_until=now + timedelta(days=30), is_active=True,
        applicable_fulfillment="all",
    )
    Coupon.objects.create(
        code="PICKUP15", discount_type="percentage", discount_value=Decimal("15.00"),
        min_order_value=Decimal("10.00"), usage_limit_total=30, usage_limit_per_user=1,
        valid_from=now, valid_until=now + timedelta(days=60), is_active=True,
        applicable_fulfillment="pickup_only",
    )
    Coupon.objects.create(
        code="EXPIRED99", discount_type="percentage", discount_value=Decimal("99.00"),
        min_order_value=Decimal("0.00"), usage_limit_total=100, usage_limit_per_user=1,
        valid_from=now - timedelta(days=30), valid_until=now - timedelta(days=1), is_active=True,
        applicable_fulfillment="all",
    )
    print(f"  [+] Created 4 coupons (WELCOME10, FLAT5, PICKUP15, EXPIRED99)")


def create_delivery_zones(cooks):
    """Create delivery zones for delivery-enabled cooks."""
    print("\n--- Delivery Zones ---")
    count = 0
    for cook in cooks:
        if cook.delivery_enabled:
            DeliveryZone.objects.create(
                cook=cook, zone_type="radius", radius_km=Decimal("10.00"),
                delivery_fee_type=cook.delivery_fee_type or "flat",
                delivery_fee_value=cook.delivery_fee_value or Decimal("5.00"),
                min_order_value=Decimal("15.00"),
                estimated_delivery_mins=45,
                is_active=True,
            )
            count += 1
    print(f"  [+] Created {count} delivery zones")


def create_orders(customers, cooks, meals):
    """Create sample orders with different statuses."""
    print("\n--- Orders ---")

    # Get available slots
    from django.utils import timezone
    slots = list(PickupSlot.objects.filter(
        is_available=True, status="open", date__gt=date.today(),
    ).order_by("date")[:20])

    if not slots:
        print("  [!] No available slots, skipping order creation")
        return []

    orders = []
    statuses = ["placed", "placed", "placed", "accepted", "preparing", "completed", "completed"]

    for i, status in enumerate(statuses):
        cust = customers[i % len(customers)]
        meal = meals[i % len(meals)]
        cook = meal.cook
        slot = None
        for s in slots:
            if str(s.cook_id) == str(cook.id):
                slot = s
                break
        if not slot:
            continue

        item_total = Decimal(str(meal.effective_price))
        platform_fee = (item_total * Decimal("0.03")).quantize(Decimal("0.01"))
        tax = ((item_total + platform_fee) * Decimal("0.05")).quantize(Decimal("0.01"))
        total = item_total + platform_fee + tax

        order = Order.objects.create(
            customer=cust, cook=cook, fulfillment_type="pickup",
            pickup_slot=slot,
            item_total=item_total, platform_fee=platform_fee,
            tax_amount=tax, total_amount=total,
            status=status, payment_status="paid" if status in ("completed", "accepted", "preparing") else "pending",
        )
        OrderItem.objects.create(
            order=order, meal=meal, meal_title=meal.title,
            quantity=1, unit_price=meal.effective_price, line_total=meal.effective_price,
        )
        orders.append(order)

        # Mark slot booked
        slot.booked_orders += 1
        slot.save()

    print(f"  [+] Created {len(orders)} orders")
    return orders


def create_reviews(customers, orders):
    """Create reviews for completed orders."""
    print("\n--- Reviews ---")
    count = 0
    completed = [o for o in orders if o.status == "completed"]
    comments = [
        ("Amazing food! Tasted just like home.", 5),
        ("Good portions, would order again.", 4),
        ("Decent food, delivery was late.", 3),
    ]
    for i, order in enumerate(completed):
        if i >= len(comments):
            break
        comment, rating = comments[i]
        Review.objects.create(
            order=order, customer=order.customer, cook=order.cook,
            rating=rating, comment=comment,
        )
        count += 1
        # Update cook avg_rating
        cook = order.cook
        cook.total_reviews += 1
        cook.avg_rating = (cook.avg_rating * (cook.total_reviews - 1) + rating) / cook.total_reviews
        cook.save(update_fields=["avg_rating", "total_reviews"])

    print(f"  [+] Created {count} reviews")


def create_notifications(customers):
    """Create sample notifications."""
    print("\n--- Notifications ---")
    for cust in customers[:3]:
        Notification.objects.create(
            user=cust, title="Welcome to NestMeal!",
            message="Discover delicious homemade meals near you.",
            event_type="welcome", channel="push",
        )
    print(f"  [+] Created 3 notifications")


if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("  NestMeal Clean Test Data Setup")
    print("=" * 50)

    customers, cooks, admin = create_users()
    create_addresses(customers)
    create_pickup_locations(cooks)
    meals = create_meals(cooks)
    create_slots(cooks)
    create_coupons()
    create_delivery_zones(cooks)
    orders = create_orders(customers, cooks, meals)
    create_reviews(customers, orders)
    create_notifications(customers)

    print("\n" + "=" * 50)
    print("  Setup Complete!")
    print(f"  Users:    {User.objects.count()}")
    print(f"  Meals:    {Meal.objects.count()}")
    print(f"  Orders:   {Order.objects.count()}")
    print(f"  Slots:    {PickupSlot.objects.count()}")
    print(f"  Coupons:  {Coupon.objects.count()}")
    print(f"  Reviews:  {Review.objects.count()}")
    print("=" * 50 + "\n")
