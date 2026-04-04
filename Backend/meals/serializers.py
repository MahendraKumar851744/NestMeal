from rest_framework import serializers
from .models import Meal, MealExtra, MealImage, PickupSlot, RecurringSlotTemplate

# ---------------------------------------------------------------------------
# MealImage
# ---------------------------------------------------------------------------

class MealImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = MealImage
        fields = ['id', 'meal', 'image', 'image_url', 'display_order', 'created_at']
        read_only_fields = ['id', 'meal', 'created_at', 'image_url']
        extra_kwargs = {'image': {'write_only': True}}

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        elif obj.image:
            return obj.image.url
        return None


# ---------------------------------------------------------------------------
# MealExtra
# ---------------------------------------------------------------------------

class MealExtraSerializer(serializers.ModelSerializer):
    class Meta:
        model = MealExtra
        fields = [
            'id', 
            'meal', 
            'name', 
            'item_type',    # <-- ADDED
            'price', 
            'currency',     # <-- ADDED
            'is_available', 
            'display_order', 
            'created_at'
        ]
        read_only_fields = ['id', 'meal', 'created_at']


# ---------------------------------------------------------------------------
# Cook info (lightweight, embedded in meal serializers)
# ---------------------------------------------------------------------------

class CookMiniSerializer(serializers.Serializer):
    """Read-only cook summary embedded inside meal representations."""
    id = serializers.UUIDField(source='cook.id')
    display_name = serializers.CharField(source='cook.display_name')
    avg_rating = serializers.DecimalField(
        source='cook.avg_rating', max_digits=3, decimal_places=2,
    )
    is_active = serializers.BooleanField(source='cook.is_active')


class CookProfileCardSerializer(serializers.Serializer):
    """Richer cook card for the meal detail view."""
    id = serializers.UUIDField()
    display_name = serializers.CharField()
    bio = serializers.CharField()
    avg_rating = serializers.DecimalField(max_digits=3, decimal_places=2)
    total_reviews = serializers.IntegerField()
    kitchen_city = serializers.CharField()
    kitchen_state = serializers.CharField()
    delivery_enabled = serializers.BooleanField()
    delivery_radius_km = serializers.DecimalField(max_digits=5, decimal_places=2)
    is_active = serializers.BooleanField()
    status = serializers.CharField()


# ---------------------------------------------------------------------------
# Meal — full CRUD
# ---------------------------------------------------------------------------

class MealSerializer(serializers.ModelSerializer):
    images = MealImageSerializer(many=True, read_only=True)
    extras = MealExtraSerializer(many=True, read_only=True)
    effective_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True,
    )
    is_past_cutoff = serializers.BooleanField(read_only=True)
    cook_display_name = serializers.CharField(
        source='cook.display_name', read_only=True,
    )

    class Meta:
        model = Meal
        fields = [
            'id', 'cook', 'cook_display_name',
            'title', 'description',
            'price', 'discount_percentage', 'effective_price', 'currency',
            'category', 'cuisine_type', 'meal_type',
            'dietary_tags', 'allergen_info',
            'spice_level', 'serving_size', 'calories_approx',
            'preparation_time_mins', 'fulfillment_modes',
            'is_available', 'available_days', 'order_cutoff_time', 'is_past_cutoff',
            'total_orders', 'avg_rating', 'tags',
            'is_featured', 'status',
            'images', 'extras',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'total_orders', 'avg_rating',
            'created_at', 'updated_at',
        ]


# ---------------------------------------------------------------------------
# Meal — lightweight list
# ---------------------------------------------------------------------------

class MealListSerializer(serializers.ModelSerializer):
    images = MealImageSerializer(many=True, read_only=True)
    effective_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True,
    )
    is_past_cutoff = serializers.BooleanField(read_only=True)
    cook_id = serializers.UUIDField(source='cook.id', read_only=True)
    cook_display_name = serializers.CharField(
        source='cook.display_name', read_only=True,
    )

    class Meta:
        model = Meal
        fields = [
            'id', 'cook_id', 'title',
            'price', 'discount_percentage', 'effective_price',
            'category', 'cuisine_type', 'meal_type', 'spice_level',
            'avg_rating', 'images',
            'cook_display_name', 'fulfillment_modes',
            'is_available', 'available_days', 'status', 'tags',
            'is_featured',
            'order_cutoff_time', 'is_past_cutoff',
            'created_at',
        ]


# ---------------------------------------------------------------------------
# Meal — full detail with cook profile card
# ---------------------------------------------------------------------------

class MealDetailSerializer(serializers.ModelSerializer):
    images = MealImageSerializer(many=True, read_only=True)
    extras = MealExtraSerializer(many=True, read_only=True)
    effective_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True,
    )
    is_past_cutoff = serializers.BooleanField(read_only=True)
    cook = CookProfileCardSerializer(read_only=True)

    class Meta:
        model = Meal
        fields = [
            'id', 'cook',
            'title', 'description',
            'price', 'discount_percentage', 'effective_price', 'currency',
            'category', 'cuisine_type', 'meal_type',
            'dietary_tags', 'allergen_info',
            'spice_level', 'serving_size', 'calories_approx',
            'preparation_time_mins', 'fulfillment_modes',
            'is_available', 'available_days', 'order_cutoff_time', 'is_past_cutoff',
            'total_orders', 'avg_rating', 'tags',
            'is_featured', 'status',
            'images', 'extras',
            'created_at', 'updated_at',
        ]


# ---------------------------------------------------------------------------
# Meal — create / update (cook-facing)
# ---------------------------------------------------------------------------

class MealCreateUpdateSerializer(serializers.ModelSerializer):
    """
    Used by cooks to create or update their own meals.
    The ``cook`` field is set automatically from the authenticated user's
    CookProfile and is not accepted from the request body.
    """

    class Meta:
        model = Meal
        fields = [
            'id',
            'title', 'description',
            'price', 'discount_percentage', 'currency',
            'category', 'cuisine_type', 'meal_type',
            'dietary_tags', 'allergen_info',
            'spice_level', 'serving_size', 'calories_approx',
            'preparation_time_mins', 'fulfillment_modes',
            'is_available', 'available_days', 'order_cutoff_time', 'tags',
            'is_featured', 'status',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    # --- helpers ------------------------------------------------------------

    def _get_cook_profile(self):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError('Authentication required.')
        if request.user.role != 'cook':
            raise serializers.ValidationError('Only cooks can manage meals.')
        try:
            return request.user.cook_profile
        except Exception:
            raise serializers.ValidationError(
                'Cook profile not found for this user.',
            )

    # --- validation ---------------------------------------------------------

    def validate(self, attrs):
        # On update, ensure the cook owns the meal.
        if self.instance is not None:
            cook_profile = self._get_cook_profile()
            if self.instance.cook_id != cook_profile.id:
                raise serializers.ValidationError(
                    'You can only edit your own meals.',
                )
                
        # <-- ADDED: Ensure the cook owns the assigned pickup locations
        if 'pickup_locations' in attrs:
            for loc in attrs['pickup_locations']:
                if loc.cook_id != cook_profile.id:
                    raise serializers.ValidationError(
                        {'pickup_locations': 'You can only assign your own pickup locations.'}
                    )
                    
        return attrs

    # --- create / update ----------------------------------------------------

    def create(self, validated_data):
        cook_profile = self._get_cook_profile()
        validated_data['cook'] = cook_profile
        return super().create(validated_data)

    def update(self, instance, validated_data):
        # cook cannot be changed
        validated_data.pop('cook', None)
        return super().update(instance, validated_data)


# ---------------------------------------------------------------------------
# PickupSlot
# ---------------------------------------------------------------------------

class PickupSlotSerializer(serializers.ModelSerializer):
    cook_display_name = serializers.CharField(
        source='cook.display_name', read_only=True,
    )

    class Meta:
        model = PickupSlot
        fields = [
            'id', 'cook', 'cook_display_name',
            'date', 'start_time', 'end_time',
            'max_orders', 'booked_orders', 'is_available',
            'location_label', 'location_street',
            'location_latitude', 'location_longitude',
            'status', 'created_at',
        ]
        read_only_fields = ['id', 'cook', 'booked_orders', 'created_at']

    def validate(self, attrs):
        # Ensure start_time < end_time
        start = attrs.get('start_time', getattr(self.instance, 'start_time', None))
        end = attrs.get('end_time', getattr(self.instance, 'end_time', None))
        if start and end and start >= end:
            raise serializers.ValidationError(
                {'end_time': 'End time must be after start time.'},
            )
        return attrs


# ---------------------------------------------------------------------------
# RecurringSlotTemplate
# ---------------------------------------------------------------------------

class RecurringSlotTemplateSerializer(serializers.ModelSerializer):
    cook_display_name = serializers.CharField(
        source='cook.display_name', read_only=True,
    )

    class Meta:
        model = RecurringSlotTemplate
        fields = [
            'id', 'cook', 'cook_display_name',
            'days_of_week', 'start_time', 'end_time',
            'max_orders', 'effective_from', 'effective_until',
            'is_active', 'slot_type', 'created_at',
        ]
        read_only_fields = ['id', 'cook', 'created_at']

    def validate(self, attrs):
        start = attrs.get('start_time', getattr(self.instance, 'start_time', None))
        end = attrs.get('end_time', getattr(self.instance, 'end_time', None))
        if start and end and start >= end:
            raise serializers.ValidationError(
                {'end_time': 'End time must be after start time.'},
            )
        return attrs
