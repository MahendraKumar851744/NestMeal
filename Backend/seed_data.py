"""
Seed script for NestMeal — populates the database with realistic test data.
Run: python manage.py shell < seed_data.py
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nestmeal.settings')
django.setup()

from datetime import date, time, timedelta, datetime
from decimal import Decimal
from django.utils import timezone
from accounts.models import User, CustomerProfile, CookProfile, Address, PickupLocation, AdminProfile
from meals.models import Meal, MealImage, PickupSlot, RecurringSlotTemplate
from delivery.models import DeliveryZone, DeliverySlot
from orders.models import Order, OrderItem
from payments.models import Payment, CookPayout
from reviews.models import Review
from coupons.models import Coupon
from notifications.models import Notification

print("Seeding database...")

# ─── ADMIN ───
admin_user = User.objects.create_superuser(
    email='admin@nestmeal.com',
    password='admin123456',
    full_name='NestMeal Admin',
    phone='+919999000001',
)
AdminProfile.objects.create(
    user=admin_user,
    admin_role='super_admin',
    permissions=['manage_users', 'manage_orders', 'manage_payouts', 'manage_coupons', 'manage_reviews'],
)
print("  Admin created: admin@nestmeal.com / admin123456")

# ─── CUSTOMERS ───
customers_data = [
    {'email': 'priya.sharma@gmail.com', 'full_name': 'Priya Sharma', 'phone': '+919876543210',
     'address': {'street': '42 MG Road, Indiranagar', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560038', 'lat': '12.9716', 'lng': '77.6411'}},
    {'email': 'rahul.verma@gmail.com', 'full_name': 'Rahul Verma', 'phone': '+919876543211',
     'address': {'street': '15 Koramangala 4th Block', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560034', 'lat': '12.9352', 'lng': '77.6245'}},
    {'email': 'anita.desai@gmail.com', 'full_name': 'Anita Desai', 'phone': '+919876543212',
     'address': {'street': '88 HSR Layout Sector 2', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560102', 'lat': '12.9116', 'lng': '77.6389'}},
    {'email': 'vikram.patel@gmail.com', 'full_name': 'Vikram Patel', 'phone': '+919876543213',
     'address': {'street': '23 Whitefield Main Road', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560066', 'lat': '12.9698', 'lng': '77.7500'}},
    {'email': 'sneha.iyer@gmail.com', 'full_name': 'Sneha Iyer', 'phone': '+919876543214',
     'address': {'street': '7 JP Nagar 2nd Phase', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560078', 'lat': '12.9070', 'lng': '77.5856'}},
]

customer_users = []
for cd in customers_data:
    u = User.objects.create_user(
        email=cd['email'], password='customer123',
        full_name=cd['full_name'], phone=cd['phone'],
        role='customer', is_verified=True,
    )
    CustomerProfile.objects.create(user=u, status='active')
    a = cd['address']
    Address.objects.create(
        user=u, label='Home', street=a['street'], city=a['city'],
        state=a['state'], zip_code=a['zip'],
        latitude=Decimal(a['lat']), longitude=Decimal(a['lng']), is_default=True,
    )
    customer_users.append(u)
print(f"  {len(customer_users)} customers created (password: customer123)")

# ─── COOKS ───
cooks_data = [
    {
        'email': 'lakshmi.kitchen@gmail.com', 'full_name': 'Lakshmi Sundaram', 'phone': '+919800100001',
        'display_name': "Lakshmi's South Indian Kitchen", 'bio': 'Authentic Tamil Nadu recipes passed down three generations. Every meal is made with love and fresh ingredients from the local market.',
        'kitchen': {'street': '12 BTM Layout 2nd Stage', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560076', 'lat': '12.9166', 'lng': '77.6101'},
        'delivery_enabled': True, 'delivery_fee_type': 'flat', 'delivery_fee_value': 30, 'delivery_radius_km': 8, 'delivery_min_order': 200,
    },
    {
        'email': 'fatima.biryani@gmail.com', 'full_name': 'Fatima Begum', 'phone': '+919800100002',
        'display_name': "Fatima's Biryani House", 'bio': 'Hyderabadi dum biryani specialist. Slow-cooked with hand-ground spices. Weekend specials include haleem and kebab platters.',
        'kitchen': {'street': '45 Jayanagar 4th Block', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560041', 'lat': '12.9250', 'lng': '77.5938'},
        'delivery_enabled': True, 'delivery_fee_type': 'per_km', 'delivery_fee_value': 10, 'delivery_radius_km': 10, 'delivery_min_order': 300,
    },
    {
        'email': 'chen.wei@gmail.com', 'full_name': 'Chen Wei', 'phone': '+919800100003',
        'display_name': "Wei's Wok — Indo-Chinese", 'bio': 'Street-style Indo-Chinese with a gourmet twist. Manchurian, fried rice, and noodles made fresh to order.',
        'kitchen': {'street': '78 Indiranagar 12th Main', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560038', 'lat': '12.9784', 'lng': '77.6408'},
        'delivery_enabled': False,
    },
    {
        'email': 'maria.bakes@gmail.com', 'full_name': 'Maria D\'Souza', 'phone': '+919800100004',
        'display_name': "Maria's Bake Studio", 'bio': 'Artisan breads, cakes, and pastries baked fresh daily. Specializing in sourdough, cinnamon rolls, and custom celebration cakes.',
        'kitchen': {'street': '33 Koramangala 5th Block', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560095', 'lat': '12.9346', 'lng': '77.6192'},
        'delivery_enabled': True, 'delivery_fee_type': 'flat', 'delivery_fee_value': 50, 'delivery_radius_km': 6, 'delivery_min_order': 250,
    },
    {
        'email': 'rajesh.thali@gmail.com', 'full_name': 'Rajesh Kumar', 'phone': '+919800100005',
        'display_name': "Rajesh's North Indian Thali", 'bio': 'Home-style North Indian thalis with dal, sabzi, roti, rice, and raita. Just like mom used to make. Pure veg kitchen.',
        'kitchen': {'street': '56 Electronic City Phase 1', 'city': 'Bangalore', 'state': 'Karnataka', 'zip': '560100', 'lat': '12.8456', 'lng': '77.6603'},
        'delivery_enabled': True, 'delivery_fee_type': 'free', 'delivery_fee_value': 0, 'delivery_radius_km': 5, 'delivery_min_order': 150,
    },
]

cook_profiles = []
for cd in cooks_data:
    u = User.objects.create_user(
        email=cd['email'], password='cook123456',
        full_name=cd['full_name'], phone=cd['phone'],
        role='cook', is_verified=True,
    )
    k = cd['kitchen']
    cp = CookProfile.objects.create(
        user=u,
        display_name=cd['display_name'],
        bio=cd['bio'],
        kitchen_street=k['street'], kitchen_city=k['city'],
        kitchen_state=k['state'], kitchen_zip=k['zip'],
        kitchen_latitude=Decimal(k['lat']), kitchen_longitude=Decimal(k['lng']),
        delivery_enabled=cd.get('delivery_enabled', False),
        delivery_fee_type=cd.get('delivery_fee_type'),
        delivery_fee_value=Decimal(str(cd.get('delivery_fee_value', 0))),
        delivery_radius_km=Decimal(str(cd.get('delivery_radius_km', 5))),
        delivery_min_order=Decimal(str(cd.get('delivery_min_order', 0))),
        government_id='AADHAAR-XXXX-' + cd['phone'][-4:],
        bank_account_number='XXXXXXXXX' + cd['phone'][-4:],
        bank_ifsc='SBIN0001234',
        bank_account_holder=cd['full_name'],
        status='active',
        is_active=True,
        avg_rating=Decimal('4.50'),
        total_reviews=0,
    )
    # Pickup location = kitchen
    PickupLocation.objects.create(
        cook=cp, label='Kitchen',
        street=k['street'], city=k['city'], state=k['state'], zip_code=k['zip'],
        latitude=Decimal(k['lat']), longitude=Decimal(k['lng']),
    )
    cook_profiles.append(cp)
print(f"  {len(cook_profiles)} cooks created (password: cook123456)")

# ─── DELIVERY ZONES ───
for cp in cook_profiles:
    if cp.delivery_enabled:
        DeliveryZone.objects.create(
            cook=cp, zone_type='radius',
            radius_km=cp.delivery_radius_km,
            delivery_fee_type=cp.delivery_fee_type or 'flat',
            delivery_fee_value=cp.delivery_fee_value,
            min_order_value=cp.delivery_min_order,
            estimated_delivery_mins=40,
        )
print("  Delivery zones created")

# ─── MEALS ───
today = date.today()
all_days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
weekdays = ['mon', 'tue', 'wed', 'thu', 'fri']

meals_data = [
    # Lakshmi's South Indian Kitchen
    {'cook': 0, 'title': 'Masala Dosa with Sambar & Chutney', 'short_description': 'Crispy golden dosa with potato filling, served with sambar and coconut chutney',
     'description': 'Our signature masala dosa is made with fermented rice and urad dal batter, filled with spiced potato masala, and served with piping hot sambar and fresh coconut chutney. Fermented overnight for the perfect crisp.',
     'price': 120, 'category': 'breakfast', 'cuisine_type': 'South Indian', 'meal_type': 'veg', 'spice_level': 'medium',
     'serving_size': 'Serves 1 (2 dosas)', 'calories': 450, 'prep_time': 20,
     'dietary_tags': ['vegan', 'gluten_free'], 'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['comfort food', 'traditional']},

    {'cook': 0, 'title': 'Idli Vada Combo', 'short_description': 'Soft steamed idlis with crispy medu vada, sambar, and chutneys',
     'price': 90, 'category': 'breakfast', 'cuisine_type': 'South Indian', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': 'Serves 1 (3 idlis + 2 vada)', 'calories': 380, 'prep_time': 15,
     'dietary_tags': ['vegan'], 'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['healthy', 'light']},

    {'cook': 0, 'title': 'Chettinad Chicken Curry', 'short_description': 'Fiery Chettinad-style chicken cooked with freshly ground spices',
     'price': 280, 'category': 'lunch', 'cuisine_type': 'South Indian', 'meal_type': 'non_veg', 'spice_level': 'extra_spicy',
     'serving_size': 'Serves 2', 'calories': 650, 'prep_time': 45,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': weekdays, 'tags': ['spicy', 'protein-rich']},

    {'cook': 0, 'title': 'Filter Coffee (Tumbler Set)', 'short_description': 'Authentic South Indian filter coffee brewed with chicory blend',
     'price': 40, 'category': 'beverage', 'cuisine_type': 'South Indian', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': '1 tumbler (200ml)', 'calories': 120, 'prep_time': 5,
     'dietary_tags': [], 'fulfillment_modes': ['pickup'], 'available_days': all_days, 'tags': ['coffee', 'hot drink']},

    # Fatima's Biryani House
    {'cook': 1, 'title': 'Hyderabadi Chicken Dum Biryani', 'short_description': 'Slow-cooked dum biryani with tender chicken, saffron rice, and hand-ground spices',
     'description': 'Our signature biryani is prepared using the traditional dum cooking method. Basmati rice layered with marinated chicken, sealed with dough, and slow-cooked for 2 hours. Served with raita and mirchi ka salan.',
     'price': 350, 'category': 'lunch', 'cuisine_type': 'Hyderabadi', 'meal_type': 'non_veg', 'spice_level': 'spicy',
     'serving_size': 'Serves 2-3', 'calories': 800, 'prep_time': 60,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['bestseller', 'party pack'], 'discount': 10},

    {'cook': 1, 'title': 'Mutton Haleem', 'short_description': 'Rich, slow-cooked haleem with tender mutton, wheat, and lentils',
     'price': 250, 'category': 'dinner', 'cuisine_type': 'Hyderabadi', 'meal_type': 'non_veg', 'spice_level': 'medium',
     'serving_size': 'Serves 1 (500ml)', 'calories': 550, 'prep_time': 90,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': ['fri', 'sat', 'sun'], 'tags': ['weekend special', 'protein-rich']},

    {'cook': 1, 'title': 'Seekh Kebab Platter', 'short_description': 'Juicy minced lamb seekh kebabs with mint chutney and rumali roti',
     'price': 320, 'category': 'dinner', 'cuisine_type': 'Mughlai', 'meal_type': 'non_veg', 'spice_level': 'medium',
     'serving_size': 'Serves 2 (8 pieces)', 'calories': 700, 'prep_time': 35,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['appetizer', 'party']},

    {'cook': 1, 'title': 'Veg Biryani', 'short_description': 'Aromatic vegetable biryani with paneer, beans, and saffron',
     'price': 220, 'category': 'lunch', 'cuisine_type': 'Hyderabadi', 'meal_type': 'veg', 'spice_level': 'medium',
     'serving_size': 'Serves 2', 'calories': 600, 'prep_time': 50,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['vegetarian', 'aromatic']},

    # Wei's Wok
    {'cook': 2, 'title': 'Chicken Manchurian Dry', 'short_description': 'Crispy battered chicken tossed in spicy manchurian sauce with spring onions',
     'price': 220, 'category': 'dinner', 'cuisine_type': 'Indo-Chinese', 'meal_type': 'non_veg', 'spice_level': 'spicy',
     'serving_size': 'Serves 2', 'calories': 500, 'prep_time': 25,
     'fulfillment_modes': ['pickup'], 'available_days': all_days, 'tags': ['street food', 'crunchy']},

    {'cook': 2, 'title': 'Veg Hakka Noodles', 'short_description': 'Stir-fried noodles with mixed vegetables and soy sauce',
     'price': 160, 'category': 'dinner', 'cuisine_type': 'Indo-Chinese', 'meal_type': 'veg', 'spice_level': 'medium',
     'serving_size': 'Serves 1', 'calories': 400, 'prep_time': 15,
     'fulfillment_modes': ['pickup'], 'available_days': all_days, 'tags': ['quick bite']},

    {'cook': 2, 'title': 'Schezwan Fried Rice with Gobi Manchurian', 'short_description': 'Spicy schezwan fried rice served with crispy cauliflower manchurian',
     'price': 200, 'category': 'lunch', 'cuisine_type': 'Indo-Chinese', 'meal_type': 'veg', 'spice_level': 'extra_spicy',
     'serving_size': 'Serves 1', 'calories': 550, 'prep_time': 20,
     'fulfillment_modes': ['pickup'], 'available_days': weekdays, 'tags': ['combo', 'spicy']},

    # Maria's Bake Studio
    {'cook': 3, 'title': 'Sourdough Loaf', 'short_description': 'Artisan sourdough bread with a crispy crust and tangy crumb, 48-hour ferment',
     'price': 250, 'category': 'snack', 'cuisine_type': 'Continental', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': '1 loaf (~500g)', 'calories': 1200, 'prep_time': 120,
     'dietary_tags': ['dairy_free'], 'fulfillment_modes': ['pickup', 'delivery'], 'available_days': ['wed', 'sat'], 'tags': ['artisan', 'fresh bread']},

    {'cook': 3, 'title': 'Cinnamon Rolls (Box of 6)', 'short_description': 'Soft, gooey cinnamon rolls with cream cheese frosting',
     'price': 350, 'category': 'dessert', 'cuisine_type': 'Continental', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': '6 pieces', 'calories': 1800, 'prep_time': 90,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['sweet', 'brunch', 'gift'], 'discount': 5},

    {'cook': 3, 'title': 'Chocolate Truffle Cake', 'short_description': 'Rich Belgian chocolate truffle cake with ganache layers',
     'price': 800, 'category': 'dessert', 'cuisine_type': 'Continental', 'meal_type': 'egg', 'spice_level': 'mild',
     'serving_size': 'Serves 6-8 (1 kg)', 'calories': 3500, 'prep_time': 180,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['celebration', 'premium']},

    {'cook': 3, 'title': 'Banana Walnut Muffins (4 pack)', 'short_description': 'Moist banana muffins studded with crunchy walnuts',
     'price': 180, 'category': 'snack', 'cuisine_type': 'Continental', 'meal_type': 'egg', 'spice_level': 'mild',
     'serving_size': '4 muffins', 'calories': 800, 'prep_time': 40,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['tea-time', 'kids']},

    # Rajesh's North Indian Thali
    {'cook': 4, 'title': 'Maharaja Thali', 'short_description': 'Complete North Indian thali with dal, 2 sabzis, roti, rice, raita, pickle, and sweet',
     'price': 180, 'category': 'lunch', 'cuisine_type': 'North Indian', 'meal_type': 'veg', 'spice_level': 'medium',
     'serving_size': 'Serves 1', 'calories': 750, 'prep_time': 30,
     'dietary_tags': [], 'fulfillment_modes': ['pickup', 'delivery'], 'available_days': weekdays, 'tags': ['complete meal', 'value for money', 'bestseller']},

    {'cook': 4, 'title': 'Paneer Butter Masala with Naan', 'short_description': 'Creamy paneer in rich tomato-butter gravy with freshly baked naan',
     'price': 220, 'category': 'dinner', 'cuisine_type': 'North Indian', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': 'Serves 2', 'calories': 600, 'prep_time': 35,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['creamy', 'popular']},

    {'cook': 4, 'title': 'Chole Bhature', 'short_description': 'Spiced chickpea curry with puffy fried bread, onion, and pickle',
     'price': 130, 'category': 'breakfast', 'cuisine_type': 'North Indian', 'meal_type': 'veg', 'spice_level': 'spicy',
     'serving_size': 'Serves 1 (2 bhature)', 'calories': 650, 'prep_time': 25,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': ['sat', 'sun'], 'tags': ['weekend brunch', 'classic']},

    {'cook': 4, 'title': 'Mango Lassi (Large)', 'short_description': 'Thick creamy mango lassi made with fresh Alphonso pulp',
     'price': 80, 'category': 'beverage', 'cuisine_type': 'North Indian', 'meal_type': 'veg', 'spice_level': 'mild',
     'serving_size': '1 glass (400ml)', 'calories': 280, 'prep_time': 5,
     'fulfillment_modes': ['pickup', 'delivery'], 'available_days': all_days, 'tags': ['refreshing', 'summer']},
]

meal_objects = []
for md in meals_data:
    m = Meal.objects.create(
        cook=cook_profiles[md['cook']],
        title=md['title'],
        short_description=md['short_description'],
        description=md.get('description', md['short_description']),
        price=Decimal(str(md['price'])),
        discount_percentage=Decimal(str(md.get('discount', 0))),
        category=md['category'],
        cuisine_type=md['cuisine_type'],
        meal_type=md['meal_type'],
        spice_level=md['spice_level'],
        serving_size=md.get('serving_size', ''),
        calories_approx=md.get('calories'),
        preparation_time_mins=md.get('prep_time', 30),
        dietary_tags=md.get('dietary_tags', []),
        fulfillment_modes=md['fulfillment_modes'],
        available_days=md['available_days'],
        tags=md.get('tags', []),
        is_available=True,
        status='active',
    )
    MealImage.objects.create(
        meal=m,
        image_url=f'https://images.nestmeal.local/meals/{m.id}_1.jpg',
        display_order=0,
    )
    meal_objects.append(m)
print(f"  {len(meal_objects)} meals created")

# ─── PICKUP SLOTS (next 5 days) ───
slot_count = 0
for cp in cook_profiles:
    for day_offset in range(5):
        d = today + timedelta(days=day_offset)
        for start_h in [11, 13, 18]:
            PickupSlot.objects.create(
                cook=cp, date=d,
                start_time=time(start_h, 0),
                end_time=time(start_h, 30),
                max_orders=10,
            )
            slot_count += 1
print(f"  {slot_count} pickup slots created")

# ─── DELIVERY SLOTS ───
dslot_count = 0
for cp in cook_profiles:
    if cp.delivery_enabled:
        for day_offset in range(5):
            d = today + timedelta(days=day_offset)
            for start_h, end_h in [(12, 14), (18, 20)]:
                DeliverySlot.objects.create(
                    cook=cp, date=d,
                    start_time=time(start_h, 0),
                    end_time=time(end_h, 0),
                    max_orders=5,
                )
                dslot_count += 1
print(f"  {dslot_count} delivery slots created")

# ─── RECURRING SLOT TEMPLATES ───
for cp in cook_profiles:
    RecurringSlotTemplate.objects.create(
        cook=cp, days_of_week=weekdays,
        start_time=time(12, 0), end_time=time(12, 30),
        max_orders=10, effective_from=today,
        slot_type='pickup',
    )
    if cp.delivery_enabled:
        RecurringSlotTemplate.objects.create(
            cook=cp, days_of_week=weekdays,
            start_time=time(18, 0), end_time=time(20, 0),
            max_orders=5, effective_from=today,
            slot_type='delivery',
        )
print("  Recurring templates created")

# ─── ORDERS (past completed orders for realistic data) ───
import random
random.seed(42)

order_count = 0
for i, customer in enumerate(customer_users):
    # Each customer makes 2-3 orders from different cooks
    selected_cooks = random.sample(range(len(cook_profiles)), min(3, len(cook_profiles)))
    for cook_idx in selected_cooks:
        cp = cook_profiles[cook_idx]
        cook_meals = [m for m in meal_objects if m.cook_id == cp.id]
        if not cook_meals:
            continue
        selected_meal = random.choice(cook_meals)
        qty = random.choice([1, 2])
        unit_price = selected_meal.effective_price
        item_total = unit_price * qty
        platform_fee = round(item_total * Decimal('0.03'), 2)
        tax = round((item_total + platform_fee) * Decimal('0.05'), 2)
        fulfillment = random.choice(selected_meal.fulfillment_modes)
        delivery_fee = Decimal('0')
        if fulfillment == 'delivery' and cp.delivery_enabled:
            if cp.delivery_fee_type == 'flat':
                delivery_fee = cp.delivery_fee_value
            elif cp.delivery_fee_type == 'free':
                delivery_fee = Decimal('0')
            else:
                delivery_fee = Decimal('30')
        elif fulfillment == 'delivery' and not cp.delivery_enabled:
            fulfillment = 'pickup'

        total = item_total + platform_fee + tax + delivery_fee
        order_date = today - timedelta(days=random.randint(1, 14))

        pickup_slot = None
        delivery_slot = None
        if fulfillment == 'pickup':
            pickup_slot = PickupSlot.objects.filter(cook=cp, date__gte=order_date).first()
        else:
            delivery_slot = DeliverySlot.objects.filter(cook=cp, date__gte=order_date).first()

        order = Order(
            customer=customer, cook=cp,
            fulfillment_type=fulfillment,
            pickup_slot=pickup_slot,
            delivery_slot=delivery_slot,
            item_total=item_total,
            platform_fee=platform_fee,
            tax_amount=tax,
            delivery_fee=delivery_fee,
            total_amount=total,
            status='completed',
            payment_status='paid',
        )
        if fulfillment == 'delivery':
            addr = customer.addresses.first()
            if addr:
                order.delivery_address_street = addr.street
                order.delivery_address_city = addr.city
                order.delivery_address_state = addr.state
                order.delivery_address_zip = addr.zip_code
                order.delivery_address_lat = addr.latitude
                order.delivery_address_lng = addr.longitude
                order.delivery_status = 'completed'
                order.delivery_distance_km = Decimal(str(round(random.uniform(1.5, 7.0), 2)))
                order.delivered_at = timezone.now() - timedelta(days=random.randint(1, 10))
        order.save()

        OrderItem.objects.create(
            order=order, meal=selected_meal,
            meal_title=selected_meal.title,
            quantity=qty, unit_price=unit_price,
        )

        # Payment record
        Payment.objects.create(
            order=order, customer=customer,
            amount=total, method=random.choice(['upi', 'credit_card', 'debit_card']),
            gateway='razorpay',
            gateway_transaction_id=f'pay_{order.order_number}_{random.randint(10000,99999)}',
            gateway_status='captured',
            status='success',
            paid_at=timezone.now() - timedelta(days=random.randint(1, 14)),
        )
        order_count += 1
print(f"  {order_count} orders created")

# ─── REVIEWS ───
review_count = 0
completed_orders = Order.objects.filter(status='completed')
ratings_pool = [5, 5, 5, 4, 4, 4, 4, 3, 3, 2]
comments_pool = [
    "Absolutely delicious! Tasted just like home cooking.",
    "Great flavors, generous portions. Will order again!",
    "Food was fresh and well-packaged. Very happy.",
    "Good quality, slightly late but worth the wait.",
    "Amazing taste! My family loved it.",
    "Perfectly spiced. One of the best meals I've had.",
    "Decent food, nothing extraordinary but satisfying.",
    "The packaging could be better but taste was excellent.",
    "Loved every bite! Already planning my next order.",
    "Very average. Expected more based on the ratings.",
]

for order in completed_orders:
    rating = random.choice(ratings_pool)
    Review.objects.create(
        order=order,
        customer=order.customer,
        cook=order.cook,
        meal=order.items.first().meal if order.items.exists() else None,
        rating=rating,
        delivery_rating=random.choice([4, 5]) if order.fulfillment_type == 'delivery' else None,
        comment=random.choice(comments_pool),
    )
    review_count += 1
print(f"  {review_count} reviews created")

# Recalculate cook avg ratings
from django.db.models import Avg, Count
for cp in cook_profiles:
    stats = cp.reviews.aggregate(avg=Avg('rating'), cnt=Count('id'))
    cp.avg_rating = Decimal(str(round(stats['avg'] or 0, 2)))
    cp.total_reviews = stats['cnt'] or 0
    cp.save()

# Recalculate meal avg ratings
for m in meal_objects:
    stats = m.reviews.aggregate(avg=Avg('rating'), cnt=Count('id'))
    m.avg_rating = Decimal(str(round(stats['avg'] or 0, 2)))
    m.total_orders = stats['cnt'] or 0
    m.save()
print("  Ratings recalculated")

# ─── COUPONS ───
Coupon.objects.create(
    code='WELCOME50',
    description='50% off on your first order (up to ₹150)',
    discount_type='percentage', discount_value=50,
    min_order_value=200,
    valid_from=timezone.now() - timedelta(days=30),
    valid_until=timezone.now() + timedelta(days=60),
    usage_limit_total=1000, usage_limit_per_user=1,
    applicable_to='new_users', is_active=True,
)
Coupon.objects.create(
    code='FLAT100',
    description='Flat ₹100 off on orders above ₹500',
    discount_type='flat_amount', discount_value=100,
    min_order_value=500,
    valid_from=timezone.now() - timedelta(days=7),
    valid_until=timezone.now() + timedelta(days=30),
    usage_limit_total=500, usage_limit_per_user=2,
    applicable_to='all', is_active=True,
)
Coupon.objects.create(
    code='FREEDELIVERY',
    description='Free delivery on any order',
    discount_type='flat_amount', discount_value=0,
    applies_to_delivery_fee=True,
    min_order_value=0,
    valid_from=timezone.now(), valid_until=timezone.now() + timedelta(days=14),
    usage_limit_total=200, usage_limit_per_user=1,
    applicable_to='all', applicable_fulfillment='delivery_only', is_active=True,
)
Coupon.objects.create(
    code='WEEKEND20',
    description='20% off on weekend orders',
    discount_type='percentage', discount_value=20,
    min_order_value=300,
    valid_from=timezone.now(), valid_until=timezone.now() + timedelta(days=90),
    usage_limit_total=300, usage_limit_per_user=3,
    applicable_to='all', is_active=True,
)
print("  4 coupons created")

# ─── NOTIFICATIONS (sample) ───
for customer in customer_users[:3]:
    Notification.objects.create(
        user=customer,
        title='Welcome to NestMeal!',
        message='Discover amazing home-cooked meals from talented local cooks near you.',
        channel='push', event_type='welcome',
    )
for order in completed_orders[:5]:
    Notification.objects.create(
        user=order.customer,
        title='How was your meal?',
        message=f'Rate your order {order.order_number} and help other food lovers!',
        channel='push', event_type='review_prompt',
        reference_id=order.id,
    )
print("  Notifications created")

print("\n=== SEED COMPLETE ===")
print(f"  Admin:     admin@nestmeal.com / admin123456")
print(f"  Customers: {', '.join(c.email for c in customer_users)} / customer123")
print(f"  Cooks:     {', '.join(cp.user.email for cp in cook_profiles)} / cook123456")
print(f"  Meals:     {len(meal_objects)}")
print(f"  Orders:    {order_count}")
print(f"  Reviews:   {review_count}")
print(f"  Coupons:   WELCOME50, FLAT100, FREEDELIVERY, WEEKEND20")
