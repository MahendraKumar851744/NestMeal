import django_filters
from .models import Meal


class MealFilter(django_filters.FilterSet):
    # --- exact / choice filters --------------------------------------------
    category = django_filters.CharFilter(field_name='category', lookup_expr='exact')
    meal_type = django_filters.CharFilter(field_name='meal_type', lookup_expr='exact')
    cuisine_type = django_filters.CharFilter(field_name='cuisine_type', lookup_expr='iexact')
    spice_level = django_filters.CharFilter(field_name='spice_level', lookup_expr='exact')
    is_available = django_filters.BooleanFilter(field_name='is_available')
    is_featured = django_filters.BooleanFilter(field_name='is_featured')
    status = django_filters.CharFilter(field_name='status', lookup_expr='exact')

    # --- price range -------------------------------------------------------
    min_price = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name='price', lookup_expr='lte')

    # --- rating ------------------------------------------------------------
    min_rating = django_filters.NumberFilter(field_name='avg_rating', lookup_expr='gte')

    # --- JSON field contains filters ---------------------------------------
    dietary_tags = django_filters.CharFilter(method='filter_dietary_tags')
    fulfillment_modes = django_filters.CharFilter(method='filter_fulfillment_modes')
    available_days = django_filters.CharFilter(method='filter_available_days')

    # --- cook --------------------------------------------------------------
    cook = django_filters.UUIDFilter(field_name='cook__id')

    class Meta:
        model = Meal
        fields = [
            'category', 'meal_type', 'cuisine_type', 'spice_level',
            'is_available', 'is_featured', 'status',
            'min_price', 'max_price', 'min_rating',
            'dietary_tags', 'fulfillment_modes', 'available_days',
            'cook',
        ]

    # -- custom filter methods ------------------------------------------------

    def filter_dietary_tags(self, queryset, name, value):
        """
        Accept a comma-separated string (e.g. ``gluten_free,vegan``) and
        return meals whose ``dietary_tags`` JSON array contains **all** of
        the requested tags.
        """
        tags = [t.strip() for t in value.split(',') if t.strip()]
        for tag in tags:
            queryset = queryset.filter(dietary_tags__contains=[tag])
        return queryset

    def filter_fulfillment_modes(self, queryset, name, value):
        """Filter meals that support the given fulfillment mode(s)."""
        modes = [m.strip() for m in value.split(',') if m.strip()]
        for mode in modes:
            queryset = queryset.filter(fulfillment_modes__contains=[mode])
        return queryset

    def filter_available_days(self, queryset, name, value):
        """Filter meals available on the given day(s) (e.g. ``mon,tue``)."""
        days = [d.strip() for d in value.split(',') if d.strip()]
        for day in days:
            queryset = queryset.filter(available_days__contains=[day])
        return queryset
