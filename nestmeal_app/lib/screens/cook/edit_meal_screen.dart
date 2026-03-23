import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nestmeal_app/config/api_config.dart';
import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/meal_model.dart';
import 'package:nestmeal_app/providers/meal_provider.dart';

class EditMealScreen extends StatefulWidget {
  final MealModel meal;

  const EditMealScreen({super.key, required this.meal});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mealNameController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _servingSizeController;
  late final TextEditingController _cuisineTypeController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _tagsController;

  late String _selectedCategory;
  late String _selectedMealType;
  late String _selectedSpiceLevel;
  late String _selectedStatus;

  final List<String> _categories = [
    'breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'beverage', 'meal_kit',
  ];
  final List<String> _mealTypes = ['veg', 'non_veg', 'egg'];
  final List<String> _spiceLevels = ['mild', 'medium', 'spicy', 'extra_spicy'];
  final List<String> _statuses = ['draft', 'active', 'paused'];

  final List<String> _allDietaryTags = [
    'gluten_free', 'dairy_free', 'nut_free', 'vegan', 'keto',
    'low_carb', 'sugar_free', 'organic', 'halal', 'kosher',
  ];
  late Set<String> _selectedDietaryTags;

  final List<String> _allAllergens = [
    'milk', 'eggs', 'peanuts', 'tree_nuts', 'soy',
    'wheat', 'fish', 'shellfish', 'sesame', 'mustard',
  ];
  late Set<String> _selectedAllergens;

  final List<String> _allFulfillmentModes = ['pickup', 'delivery'];
  late Set<String> _selectedFulfillmentModes;

  final List<String> _allDays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];
  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late Set<String> _selectedDays;

  late bool _isAvailable;

  final List<File> _newImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingDetail = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty/default values first
    _mealNameController = TextEditingController();
    _shortDescriptionController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _discountController = TextEditingController();
    _servingSizeController = TextEditingController();
    _cuisineTypeController = TextEditingController();
    _caloriesController = TextEditingController();
    _prepTimeController = TextEditingController();
    _tagsController = TextEditingController();

    _selectedCategory = 'lunch';
    _selectedMealType = 'veg';
    _selectedSpiceLevel = 'medium';
    _selectedStatus = 'active';
    _selectedDietaryTags = {};
    _selectedAllergens = {};
    _selectedFulfillmentModes = {'pickup'};
    _selectedDays = {};
    _isAvailable = true;

    // Fetch the full meal detail from the API
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFullMealDetail());
  }

  Future<void> _fetchFullMealDetail() async {
    try {
      final mealProvider = context.read<MealProvider>();
      await mealProvider.fetchMealDetail(widget.meal.id);
      final detail = mealProvider.selectedMeal;
      if (detail != null && mounted) {
        _populateForm(detail);
      } else if (mounted) {
        // Fallback: use the list-level data we already have
        _populateForm(widget.meal);
      }
    } catch (e) {
      if (mounted) {
        // Fallback: use whatever data we have from the list
        _populateForm(widget.meal);
        setState(() => _loadError = 'Could not load full details. Some fields may be incomplete.');
      }
    }
  }

  void _populateForm(MealModel m) {
    setState(() {
      _mealNameController.text = m.title;
      _shortDescriptionController.text = m.shortDescription;
      _descriptionController.text = m.description;
      _priceController.text = m.price > 0 ? m.price.toStringAsFixed(2) : '';
      _discountController.text = m.discountPercentage > 0 ? m.discountPercentage.toStringAsFixed(1) : '';
      _servingSizeController.text = m.servingSize;
      _cuisineTypeController.text = m.cuisineType;
      _caloriesController.text = m.caloriesApprox != null ? m.caloriesApprox.toString() : '';
      _prepTimeController.text = m.preparationTimeMins > 0 ? m.preparationTimeMins.toString() : '';
      _tagsController.text = m.tags.join(', ');

      _selectedCategory = _categories.contains(m.category) ? m.category : 'lunch';
      _selectedMealType = _mealTypes.contains(m.mealType) ? m.mealType : 'veg';
      _selectedSpiceLevel = _spiceLevels.contains(m.spiceLevel) ? m.spiceLevel : 'medium';
      _selectedStatus = _statuses.contains(m.status) ? m.status : 'active';
      _selectedDietaryTags = Set<String>.from(m.dietaryTags);
      _selectedAllergens = Set<String>.from(m.allergenInfo);
      _selectedFulfillmentModes = m.fulfillmentModes.isNotEmpty
          ? Set<String>.from(m.fulfillmentModes)
          : {'pickup'};
      _selectedDays = Set<String>.from(m.availableDays);
      _isAvailable = m.isAvailable;

      _isLoadingDetail = false;
    });
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _servingSizeController.dispose();
    _cuisineTypeController.dispose();
    _caloriesController.dispose();
    _prepTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _newImages.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFulfillmentModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one fulfillment mode')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one available day')),
      );
      return;
    }

    final mealProvider = context.read<MealProvider>();

    final data = <String, dynamic>{
      'title': _mealNameController.text.trim(),
      'short_description': _shortDescriptionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'discount_percentage': double.tryParse(_discountController.text.trim()) ?? 0,
      'serving_size': _servingSizeController.text.trim(),
      'category': _selectedCategory,
      'meal_type': _selectedMealType,
      'spice_level': _selectedSpiceLevel,
      'cuisine_type': _cuisineTypeController.text.trim(),
      'dietary_tags': _selectedDietaryTags.toList(),
      'allergen_info': _selectedAllergens.toList(),
      'fulfillment_modes': _selectedFulfillmentModes.toList(),
      'available_days': _selectedDays.toList(),
      'is_available': _isAvailable,
      'status': _selectedStatus,
      'preparation_time_mins': int.tryParse(_prepTimeController.text.trim()) ?? 30,
      'tags': _tagsController.text.trim().isNotEmpty
          ? _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
          : <String>[],
    };

    final caloriesText = _caloriesController.text.trim();
    if (caloriesText.isNotEmpty) {
      data['calories_approx'] = int.tryParse(caloriesText);
    }

    try {
      await mealProvider.updateMeal(widget.meal.id, data);

      // Upload new images
      if (_newImages.isNotEmpty) {
        for (final imageFile in _newImages) {
          try {
            await mealProvider.uploadMealImage(widget.meal.id, imageFile.path);
          } catch (_) {
            // Continue uploading remaining images even if one fails
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meal updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${widget.meal.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final mealProvider = context.read<MealProvider>();

    try {
      await mealProvider.deleteMeal(widget.meal.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meal deleted'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  String _formatTagLabel(String tag) {
    return tag
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          'Edit Meal',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
            tooltip: 'Delete Meal',
          ),
        ],
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Existing & New Images
                    _buildSectionLabel('Meal Photos'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing images from server
                          ...widget.meal.images.map((img) {
                            final url = img.imageUrl.startsWith('http')
                                ? img.imageUrl
                                : '${ApiConfig.baseUrl}${img.imageUrl}';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 120,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Newly picked images
                          ..._newImages.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(entry.value, height: 120, width: 120, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeNewImage(entry.key),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Add more button
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.lightGrey),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.greyText),
                                  const SizedBox(height: 4),
                                  Text('Add Photo', style: TextStyle(fontSize: 11, color: AppTheme.greyText)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Load error banner
                    if (_loadError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_loadError!, style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Availability toggle & Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Available', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              _isAvailable ? 'Meal is visible to customers' : 'Meal is hidden',
                              style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                            ),
                            value: _isAvailable,
                            activeColor: AppTheme.successGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _isAvailable = val),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            items: _statuses.map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(_formatTagLabel(item)),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meal Name
                    TextFormField(
                      controller: _mealNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Meal Name',
                        hintText: 'e.g., Butter Chicken Rice Bowl',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter the meal name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Short Description
                    TextFormField(
                      controller: _shortDescriptionController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Short Description',
                        hintText: 'Brief summary shown in meal cards',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Full Description',
                        hintText: 'Detailed description of your meal...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter a description';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price, Discount, Serving Size
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (A\$)',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              hintText: '0',
                              suffixText: '%',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _servingSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Serving Size',
                              hintText: 'e.g., 1 plate',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prep Time (min)',
                              hintText: '30',
                              suffixText: 'min',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calories
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories (approx)',
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.local_fire_department_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(_formatTagLabel(item)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 16),

                    // Meal Type
                    DropdownButtonFormField<String>(
                      value: _selectedMealType,
                      decoration: const InputDecoration(labelText: 'Meal Type'),
                      items: _mealTypes.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(_formatTagLabel(item)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedMealType = val!),
                    ),
                    const SizedBox(height: 16),

                    // Spice Level
                    DropdownButtonFormField<String>(
                      value: _selectedSpiceLevel,
                      decoration: const InputDecoration(labelText: 'Spice Level'),
                      items: _spiceLevels.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(_formatTagLabel(item)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedSpiceLevel = val!),
                    ),
                    const SizedBox(height: 16),

                    // Cuisine Type
                    TextFormField(
                      controller: _cuisineTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine Type',
                        hintText: 'e.g., Indian, Italian, Chinese',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'e.g., homestyle, comfort food, spicy (comma separated)',
                        helperText: 'Separate tags with commas',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dietary Tags
                    _buildSectionLabel('Dietary Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDietaryTags.map((tag) {
                        final selected = _selectedDietaryTags.contains(tag);
                        return FilterChip(
                          label: Text(_formatTagLabel(tag)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedDietaryTags.add(tag);
                              } else {
                                _selectedDietaryTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryOrange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.darkText,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Allergen Info
                    _buildSectionLabel('Allergen Info'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allAllergens.map((allergen) {
                        final selected = _selectedAllergens.contains(allergen);
                        return FilterChip(
                          label: Text(_formatTagLabel(allergen)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAllergens.add(allergen);
                              } else {
                                _selectedAllergens.remove(allergen);
                              }
                            });
                          },
                          selectedColor: Colors.red.shade400,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.darkText,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Fulfillment Modes
                    _buildSectionLabel('Fulfillment Modes'),
                    const SizedBox(height: 8),
                    Row(
                      children: _allFulfillmentModes.map((mode) {
                        final selected = _selectedFulfillmentModes.contains(mode);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(mode == 'pickup' ? 'Pickup' : 'Delivery'),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedFulfillmentModes.add(mode);
                                } else {
                                  _selectedFulfillmentModes.remove(mode);
                                }
                              });
                            },
                            selectedColor: AppTheme.primaryOrange,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppTheme.darkText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Available Days
                    _buildSectionLabel('Available Days'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_allDays.length, (i) {
                        final day = _allDays[i];
                        final selected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(_dayLabels[i]),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryOrange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppTheme.darkText,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: mealProvider.isLoading ? null : _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: mealProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Meal', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkText,
      ),
    );
  }
}
