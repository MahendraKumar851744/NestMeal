import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/api_config.dart';
import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/meal_provider.dart';


// --- NEW ADDED CODE START ---
class _AddOnItem {
  final String name;
  final double price;
  final String itemType;
  final String currency;

  _AddOnItem({
    required this.name,
    required this.price,
    required this.itemType,
    required this.currency,
  });
}
// --- NEW ADDED CODE END ---

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _servingSizeController = TextEditingController(text: '1');
  final _cuisineTypeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '30');
  final _tagsController = TextEditingController();

  String _selectedCategory = 'lunch';
  String _selectedMealType = 'veg';
  String _selectedSpiceLevel = 'medium';

  final List<String> _categories = [
    'breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'beverage', 'meal_kit',
  ];

  final List<String> _mealTypes = ['veg', 'non_veg', 'egg'];
  final List<String> _spiceLevels = ['mild', 'medium', 'spicy', 'extra_spicy'];

  final List<String> _allDietaryTags = [
    'gluten_free', 'dairy_free', 'nut_free', 'vegan', 'keto',
    'low_carb', 'sugar_free', 'organic', 'halal', 'kosher',
  ];
  final Set<String> _selectedDietaryTags = {};

  final List<String> _allAllergens = [
    'milk', 'eggs', 'peanuts', 'tree_nuts', 'soy',
    'wheat', 'fish', 'shellfish', 'sesame', 'mustard',
  ];
  final Set<String> _selectedAllergens = {};

  final List<String> _allFulfillmentModes = ['pickup', 'delivery'];
  final Set<String> _selectedFulfillmentModes = {'pickup'};

  final List<String> _allDays = [
  'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
];

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {};

  // --- NEW ADDED CODE START ---
  final List<String> _currencies = ['AUD', 'INR', 'USD', 'EUR'];
  final List<_AddOnItem> _addOns = [];
  // --- NEW ADDED CODE END ---

  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _mealNameController.dispose();
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
        setState(() => _selectedImages.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
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

  // --- NEW ADDED CODE START ---
  void _showAddOnDialog() {
    final addOnFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedType = 'veg';
    String selectedCurrency = 'AUD';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Add-on'),
        content: Form(
          key: addOnFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Add-on Name', hintText: 'e.g., Extra Raita'),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3, // Increased flex
                    child: TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                      validator: (val) => (val == null || double.tryParse(val) == null) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2, // Increased flex to give dropdown more room
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // <--- THIS FIXES THE OVERFLOW
                      value: selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Curr'),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => selectedCurrency = val!,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(_formatTagLabel(t)))).toList(),
                onChanged: (val) => selectedType = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (addOnFormKey.currentState!.validate()) {
                setState(() {
                  _addOns.add(_AddOnItem(
                    name: nameCtrl.text.trim(),
                    price: double.parse(priceCtrl.text.trim()),
                    itemType: selectedType,
                    currency: selectedCurrency,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  // --- NEW ADDED CODE END ---

  Future<void> _handlePublish() async {
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
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'discount_percentage': double.tryParse(_discountController.text.trim()) ?? 0,
      'serving_size': _servingSizeController.text.trim(),
      'category': _selectedCategory,
      'meal_type': _selectedMealType,
      'spice_level': _selectedSpiceLevel,
      // 'cuisine_type': _cuisineTypeController.text.trim(),
      // 'dietary_tags': _selectedDietaryTags.toList(),
      // 'allergen_info': _selectedAllergens.toList(),
      'fulfillment_modes': _selectedFulfillmentModes.toList(),
      'available_days': _selectedDays.toList(),
      'is_available': true,
      'status': 'active',
      // 'preparation_time_mins': int.tryParse(_prepTimeController.text.trim()) ?? 30,
      'tags': _tagsController.text.trim().isNotEmpty
          ? _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
          : <String>[],
    };

    // final caloriesText = _caloriesController.text.trim();
    // if (caloriesText.isNotEmpty) {
    //   data['calories_approx'] = int.tryParse(caloriesText);
    // }

    try {
      final response = await mealProvider.createMeal(data);
      final mealId = response['id']?.toString();

      // Upload images
      if (mealId != null && _selectedImages.isNotEmpty) {
        for (final imageFile in _selectedImages) {
          try {
            await mealProvider.uploadMealImage(mealId, imageFile.path);
          } catch (_) {
            // Continue uploading remaining images even if one fails
          }
        }
      }

      // --- NEW ADDED CODE START ---
      // Upload Add-ons
      if (mealId != null && _addOns.isNotEmpty) {
        for (final addon in _addOns) {
          try {
            await mealProvider.createMealExtra(mealId, {
              'name': addon.name,
              'price': addon.price,
              'item_type': addon.itemType,
              'currency': addon.currency,
              'is_available': true,
            });
          } catch (_) {}
        }
      }
      // --- NEW ADDED CODE END ---

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meal published successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _mealNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _discountController.text = '0';
      _servingSizeController.text = '1';
      _cuisineTypeController.clear();
      _caloriesController.clear();
      _prepTimeController.text = '30';
      _tagsController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedDietaryTags.clear();
        _selectedAllergens.clear();
        _selectedFulfillmentModes.clear();
        _selectedFulfillmentModes.add('pickup');
        _selectedDays.clear();
        _addOns.clear();
      });
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

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          'Add New Meal',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload
              if (_selectedImages.isEmpty)
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightGrey, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 48, color: AppTheme.greyText),
                          const SizedBox(height: 8),
                          Text('Add Meal Photo', style: TextStyle(fontSize: 14, color: AppTheme.greyText, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Tap to take photo or choose from gallery', style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return GestureDetector(
                              onTap: _showImageSourceSheet,
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.lightGrey),
                                ),
                                child: Center(
                                  child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.greyText),
                                ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImages[index], height: 180, width: 180, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Meal Name
              TextFormField(
                controller: _mealNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  hintText: 'e.g., Butter Chicken Rice Bowl',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the meal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price and Discount row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid price';
                        }
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

              // Serving Size and Prep Time row
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
                  // const SizedBox(width: 12),
                  // Expanded(
                  //   child: TextFormField(
                  //     controller: _prepTimeController,
                  //     keyboardType: TextInputType.number,
                  //     decoration: const InputDecoration(
                  //       labelText: 'Prep Time (min)',
                  //       hintText: '30',
                  //       suffixText: 'min',
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 16),

              // // Calories
              // TextFormField(
              //   controller: _caloriesController,
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //     labelText: 'Calories (approx)',
              //     hintText: 'Optional',
              //     prefixIcon: Icon(Icons.local_fire_department_outlined),
              //   ),
              // ),
              // const SizedBox(height: 20),

              // Category Dropdown
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Meal Type Dropdown
              _buildDropdown(
                label: 'Meal Type',
                value: _selectedMealType,
                items: _mealTypes,
                onChanged: (val) => setState(() => _selectedMealType = val!),
              ),
              const SizedBox(height: 16),

              // Spice Level Dropdown
              _buildDropdown(
                label: 'Spice Level',
                value: _selectedSpiceLevel,
                items: _spiceLevels,
                onChanged: (val) => setState(() => _selectedSpiceLevel = val!),
              ),
              const SizedBox(height: 16),

              // // Cuisine Type
              // TextFormField(
              //   controller: _cuisineTypeController,
              //   decoration: const InputDecoration(
              //     labelText: 'Cuisine Type',
              //     hintText: 'e.g., Indian, Italian, Chinese',
              //   ),
              // ),
              // const SizedBox(height: 16),

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

              // --- NEW ADDED CODE START ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('Meal Extras / Add-ons'),
                  TextButton.icon(
                    onPressed: _showAddOnDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Extra'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryOrange),
                  )
                ],
              ),
              if (_addOns.isEmpty)
                Text('No add-ons created yet.', style: TextStyle(color: AppTheme.greyText, fontSize: 13))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _addOns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = _addOns[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${_formatTagLabel(item.itemType)}  •  ${item.price} ${item.currency}', 
                                style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => setState(() => _addOns.removeAt(index)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              // --- NEW ADDED CODE END ---

              // // Dietary Tags
              // _buildSectionLabel('Dietary Tags'),
              // const SizedBox(height: 8),
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: _allDietaryTags.map((tag) {
              //     final selected = _selectedDietaryTags.contains(tag);
              //     return FilterChip(
              //       label: Text(_formatTagLabel(tag)),
              //       selected: selected,
              //       onSelected: (val) {
              //         setState(() {
              //           if (val) {
              //             _selectedDietaryTags.add(tag);
              //           } else {
              //             _selectedDietaryTags.remove(tag);
              //           }
              //         });
              //       },
              //       selectedColor: AppTheme.primaryOrange,
              //       checkmarkColor: Colors.white,
              //       labelStyle: TextStyle(
              //         color: selected ? Colors.white : AppTheme.darkText,
              //         fontSize: 13,
              //       ),
              //     );
              //   }).toList(),
              // ),
              // const SizedBox(height: 20),

              // // Allergen Info
              // _buildSectionLabel('Allergen Info'),
              // const SizedBox(height: 8),
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: _allAllergens.map((allergen) {
              //     final selected = _selectedAllergens.contains(allergen);
              //     return FilterChip(
              //       label: Text(_formatTagLabel(allergen)),
              //       selected: selected,
              //       onSelected: (val) {
              //         setState(() {
              //           if (val) {
              //             _selectedAllergens.add(allergen);
              //           } else {
              //             _selectedAllergens.remove(allergen);
              //           }
              //         });
              //       },
              //       selectedColor: Colors.red.shade400,
              //       checkmarkColor: Colors.white,
              //       labelStyle: TextStyle(
              //         color: selected ? Colors.white : AppTheme.darkText,
              //         fontSize: 13,
              //       ),
              //     );
              //   }).toList(),
              // ),
              // const SizedBox(height: 20),

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
              if (_selectedFulfillmentModes.contains('pickup')) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Make sure you have Pickup Slots set up in Manage Slots, otherwise customers cannot place pickup orders.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

              // Publish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: mealProvider.isLoading ? null : _handlePublish,
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
                      : const Text(
                          'Publish Meal',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(_formatTagLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
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

  String _formatTagLabel(String tag) {
    return tag
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}