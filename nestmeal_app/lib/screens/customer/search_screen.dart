import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../providers/meal_provider.dart';
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialMealType;
  final String? initialSort;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.initialMealType,
    this.initialSort,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedCategory;
  String? _selectedCuisine;
  String? _selectedMealType;
  String? _selectedSpiceLevel;
  RangeValues _priceRange = const RangeValues(0, 500);
  bool _showFilters = false;

  static const _categories = [
    'all',
    'main_course',
    'side_dish',
    'dessert',
    'snack',
    'beverage',
    'breakfast',
  ];

  static const _categoryLabels = {
    'all': 'All',
    'main_course': 'Main Course',
    'side_dish': 'Side Dish',
    'dessert': 'Dessert',
    'snack': 'Snack',
    'beverage': 'Beverage',
    'breakfast': 'Breakfast',
  };

  static const _cuisines = [
    'south_indian',
    'north_indian',
    'chinese',
    'continental',
    'italian',
    'mexican',
    'thai',
    'japanese',
    'mediterranean',
    'american',
    'other',
  ];

  static const _cuisineLabels = {
    'south_indian': 'South Indian',
    'north_indian': 'North Indian',
    'chinese': 'Chinese',
    'continental': 'Continental',
    'italian': 'Italian',
    'mexican': 'Mexican',
    'thai': 'Thai',
    'japanese': 'Japanese',
    'mediterranean': 'Mediterranean',
    'american': 'American',
    'other': 'Other',
  };

  static const _mealTypes = ['veg', 'non_veg', 'vegan', 'eggetarian'];
  static const _mealTypeLabels = {
    'veg': 'Veg',
    'non_veg': 'Non-Veg',
    'vegan': 'Vegan',
    'eggetarian': 'Eggetarian',
  };

  static const _spiceLevels = ['mild', 'medium', 'spicy', 'extra_spicy'];
  static const _spiceLevelLabels = {
    'mild': 'Mild',
    'medium': 'Medium',
    'spicy': 'Spicy',
    'extra_spicy': 'Extra Spicy',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    if (widget.initialMealType != null) {
      _selectedMealType = widget.initialMealType;
    }
    // If any initial filter is set, perform search after build
    if (widget.initialQuery != null ||
        widget.initialCategory != null ||
        widget.initialMealType != null ||
        widget.initialSort != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    context.read<MealProvider>().fetchMeals(
          search: query.isNotEmpty ? query : null,
          category: _selectedCategory != null && _selectedCategory != 'all'
              ? _selectedCategory
              : null,
          cuisineType: _selectedCuisine,
          mealType: _selectedMealType,
          spiceLevel: _selectedSpiceLevel,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < 500 ? _priceRange.end : null,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCuisine = null;
      _selectedMealType = null;
      _selectedSpiceLevel = null;
      _priceRange = const RangeValues(0, 500);
    });
    _performSearch();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedCuisine != null ||
      _selectedMealType != null ||
      _selectedSpiceLevel != null ||
      _priceRange.start > 0 ||
      _priceRange.end < 500;

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Search meals, cooks, cuisines...',
              hintStyle: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.greyText,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: AppTheme.primaryOrange,
              smallSize: 8,
              child: Icon(
                _showFilters
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              ),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          if (_showFilters) _buildFiltersPanel(),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat ||
                    (cat == 'all' && _selectedCategory == null);
                return ChoiceChip(
                  label: Text(_categoryLabels[cat]!),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat == 'all' ? null : cat;
                    });
                    _performSearch();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryOrange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : AppTheme.lightGrey,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Active filters chips
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (_selectedCuisine != null)
                          _buildFilterChip(
                            _cuisineLabels[_selectedCuisine] ?? _selectedCuisine!,
                            () {
                              setState(() => _selectedCuisine = null);
                              _performSearch();
                            },
                          ),
                        if (_selectedMealType != null)
                          _buildFilterChip(
                            _mealTypeLabels[_selectedMealType] ?? _selectedMealType!,
                            () {
                              setState(() => _selectedMealType = null);
                              _performSearch();
                            },
                          ),
                        if (_selectedSpiceLevel != null)
                          _buildFilterChip(
                            _spiceLevelLabels[_selectedSpiceLevel] ?? _selectedSpiceLevel!,
                            () {
                              setState(() => _selectedSpiceLevel = null);
                              _performSearch();
                            },
                          ),
                        if (_priceRange.start > 0 || _priceRange.end < 500)
                          _buildFilterChip(
                            'A\$${_priceRange.start.toInt()} - A\$${_priceRange.end.toInt()}',
                            () {
                              setState(() => _priceRange = const RangeValues(0, 500));
                              _performSearch();
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: mealProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : mealProvider.meals.isEmpty
                    ? _buildEmptyState()
                    : _buildResults(mealProvider.meals),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cuisine type
          const Text(
            'Cuisine',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisines.map((c) {
              final isSelected = _selectedCuisine == c;
              return ChoiceChip(
                label: Text(_cuisineLabels[c]!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCuisine = isSelected ? null : c;
                  });
                  _performSearch();
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkText,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryOrange : AppTheme.lightGrey,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Meal type
          const Text(
            'Meal Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mealTypes.map((t) {
              final isSelected = _selectedMealType == t;
              return ChoiceChip(
                label: Text(_mealTypeLabels[t]!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedMealType = isSelected ? null : t;
                  });
                  _performSearch();
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkText,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryOrange : AppTheme.lightGrey,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Spice level
          const Text(
            'Spice Level',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _spiceLevels.map((s) {
              final isSelected = _selectedSpiceLevel == s;
              return ChoiceChip(
                label: Text(_spiceLevelLabels[s]!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedSpiceLevel = isSelected ? null : s;
                  });
                  _performSearch();
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkText,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryOrange : AppTheme.lightGrey,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Price range
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'A\$${_priceRange.start.toInt()}',
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
              Text(
                'A\$${_priceRange.end.toInt()}',
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppTheme.primaryOrange,
            inactiveColor: AppTheme.lightGrey,
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
            onChangeEnd: (_) => _performSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.primaryOrange),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      deleteIconColor: AppTheme.primaryOrange,
      backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _searchController.text.isNotEmpty || _hasActiveFilters;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.search,
              size: 80,
              color: AppTheme.greyText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No meals found' : 'Search for meals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.greyText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try different keywords or adjust your filters'
                  : 'Find your favourite home-cooked meals,\ncuisines, and cooks',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.greyText,
                  ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _clearFilters();
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealResultCard(MealModel meal) {
    final hasDiscount = meal.effectivePrice < meal.price;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Container(
              width: 110,
              height: 110,
              color: AppTheme.lightGrey,
              child: meal.images.isNotEmpty
                  ? Image.network(
                      meal.images.first.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        size: 32,
                        color: AppTheme.greyText,
                      ),
                    )
                  : const Icon(
                      Icons.restaurant,
                      size: 32,
                      color: AppTheme.greyText,
                    ),
            ),
          ),
          // Meal info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.cookDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        meal.avgRating > 0
                            ? meal.avgRating.toStringAsFixed(1)
                            : 'New',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          meal.cuisineType.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          'A\$${meal.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'A\$${meal.effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const Spacer(),
                      ...meal.fulfillmentModes.map((mode) {
                        final isPickup = mode == 'pickup';
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPickup
                                ? AppTheme.primaryOrange
                                : AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPickup ? 'Pickup' : 'Delivery',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<MealModel> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${meals.length} result${meals.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final meal = meals[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealDetailScreen(mealId: meal.id),
                      ),
                    );
                  },
                  child: _buildMealResultCard(meal),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
