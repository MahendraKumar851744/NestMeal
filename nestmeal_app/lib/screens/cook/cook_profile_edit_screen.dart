import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/models/user_model.dart';
import 'package:nestmeal_app/screens/auth/login_screen.dart';
import 'package:nestmeal_app/screens/common/location_picker_screen.dart';

class CookProfileEditScreen extends StatefulWidget {
  const CookProfileEditScreen({super.key});

  @override
  State<CookProfileEditScreen> createState() => _CookProfileEditScreenState();
}

class _CookProfileEditScreenState extends State<CookProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // User fields
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  // Cook profile fields
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _kitchenStreetController;
  late TextEditingController _kitchenCityController;
  late TextEditingController _kitchenStateController;
  late TextEditingController _kitchenZipController;
  late TextEditingController _pickupInstructionsController;

  // Delivery settings
  late bool _deliveryEnabled;
  late TextEditingController _deliveryRadiusController;
  late String _deliveryFeeType;
  late TextEditingController _deliveryFeeValueController;
  late TextEditingController _deliveryMinOrderController;

  double? _kitchenLatitude;
  double? _kitchenLongitude;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initControllers();
      _isInitialized = true;
    }
  }

  void _initControllers() {
    final user = context.read<AuthProvider>().currentUser;
    final cook = user?.cookProfile;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    _displayNameController = TextEditingController(text: cook?.displayName ?? '');
    _bioController = TextEditingController(text: cook?.bio ?? '');
    _kitchenStreetController = TextEditingController(text: cook?.kitchenStreet ?? '');
    _kitchenCityController = TextEditingController(text: cook?.kitchenCity ?? '');
    _kitchenStateController = TextEditingController(text: cook?.kitchenState ?? '');
    _kitchenZipController = TextEditingController(text: cook?.kitchenZip ?? '');
    _pickupInstructionsController = TextEditingController(text: cook?.pickupInstructions ?? '');
    _kitchenLatitude = cook?.kitchenLatitude;
    _kitchenLongitude = cook?.kitchenLongitude;

    _deliveryEnabled = cook?.deliveryEnabled ?? false;
    _deliveryRadiusController = TextEditingController(
      text: (cook?.deliveryRadiusKm ?? 0) > 0 ? cook!.deliveryRadiusKm.toStringAsFixed(1) : '',
    );
    _deliveryFeeType = cook?.deliveryFeeType ?? 'flat';
    _deliveryFeeValueController = TextEditingController(
      text: (cook?.deliveryFeeValue ?? 0) > 0 ? cook!.deliveryFeeValue.toStringAsFixed(2) : '',
    );
    _deliveryMinOrderController = TextEditingController(
      text: (cook?.deliveryMinOrder ?? 0) > 0 ? cook!.deliveryMinOrder.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _kitchenStreetController.dispose();
    _kitchenCityController.dispose();
    _kitchenStateController.dispose();
    _kitchenZipController.dispose();
    _pickupInstructionsController.dispose();
    _deliveryRadiusController.dispose();
    _deliveryFeeValueController.dispose();
    _deliveryMinOrderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final cook = authProvider.currentUser?.cookProfile;
    if (cook == null) return;

    try {
      // Update user profile (name, phone)
      await authProvider.updateProfile(
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        null,
      );

      // Update cook profile
      final cookData = <String, dynamic>{
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'kitchen_street': _kitchenStreetController.text.trim(),
        'kitchen_city': _kitchenCityController.text.trim(),
        'kitchen_state': _kitchenStateController.text.trim(),
        'kitchen_zip': _kitchenZipController.text.trim(),
        'pickup_instructions': _pickupInstructionsController.text.trim(),
        'delivery_enabled': _deliveryEnabled,
      };

      if (_kitchenLatitude != null) cookData['kitchen_latitude'] = _kitchenLatitude;
      if (_kitchenLongitude != null) cookData['kitchen_longitude'] = _kitchenLongitude;

      if (_deliveryEnabled) {
        final radius = double.tryParse(_deliveryRadiusController.text.trim());
        if (radius != null) cookData['delivery_radius_km'] = radius;
        cookData['delivery_fee_type'] = _deliveryFeeType;
        final feeValue = double.tryParse(_deliveryFeeValueController.text.trim());
        if (feeValue != null) cookData['delivery_fee_value'] = feeValue;
        final minOrder = double.tryParse(_deliveryMinOrderController.text.trim());
        if (minOrder != null) cookData['delivery_min_order'] = minOrder;
      }

      await authProvider.updateCookProfile(cook.id, cookData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
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

  Future<void> _openKitchenLocationPicker() async {
    LatLng? initial;
    if (_kitchenLatitude != null && _kitchenLongitude != null) {
      initial = LatLng(_kitchenLatitude!, _kitchenLongitude!);
    }

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatLng: initial,
          title: 'Kitchen Location',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _kitchenLatitude = result.latitude;
        _kitchenLongitude = result.longitude;
        _kitchenStreetController.text = result.street;
        _kitchenCityController.text = result.city;
        _kitchenStateController.text = result.state;
        _kitchenZipController.text = result.zipCode;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final cook = user?.cookProfile;

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'My Profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your account and kitchen settings',
                  style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                ),
                const SizedBox(height: 24),

                // Profile Avatar & Status
                _buildProfileHeader(user, cook),
                const SizedBox(height: 24),

                // Personal Information
                _buildSectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        suffixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Kitchen Identity
                _buildSectionCard(
                  title: 'Kitchen Identity',
                  icon: Icons.restaurant_outlined,
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Display Name / Kitchen Name',
                        hintText: 'e.g., Mom\'s Kitchen',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell customers about your cooking...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Kitchen Address
                _buildSectionCard(
                  title: 'Kitchen Address',
                  icon: Icons.location_on_outlined,
                  children: [
                    // Pick on Map button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openKitchenLocationPicker,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text(
                          _kitchenLatitude != null
                              ? 'Change Location on Map'
                              : 'Pick Location on Map',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryOrange,
                          side: const BorderSide(color: AppTheme.primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_kitchenLatitude != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Location set (${_kitchenLatitude!.toStringAsFixed(5)}, ${_kitchenLongitude!.toStringAsFixed(5)})',
                            style: const TextStyle(fontSize: 12, color: AppTheme.successGreen),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kitchenStreetController,
                      decoration: const InputDecoration(labelText: 'Street Address'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _kitchenCityController,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _kitchenStateController,
                            decoration: const InputDecoration(labelText: 'State'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kitchenZipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ZIP Code'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pickupInstructionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Instructions',
                        hintText: 'e.g., Ring doorbell, apartment 3B...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Delivery Settings
                _buildSectionCard(
                  title: 'Delivery Settings',
                  icon: Icons.delivery_dining_outlined,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _deliveryEnabled ? 'You offer delivery to customers' : 'Pickup only',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                      ),
                      value: _deliveryEnabled,
                      activeColor: AppTheme.successGreen,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _deliveryEnabled = val),
                    ),
                    if (_deliveryEnabled) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deliveryRadiusController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Radius (km)',
                          hintText: 'e.g., 5.0',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _deliveryFeeType,
                        decoration: const InputDecoration(labelText: 'Delivery Fee Type'),
                        items: const [
                          DropdownMenuItem(value: 'flat', child: Text('Flat Rate')),
                          DropdownMenuItem(value: 'per_km', child: Text('Per Kilometer')),
                          DropdownMenuItem(value: 'free', child: Text('Free Delivery')),
                        ],
                        onChanged: (val) => setState(() => _deliveryFeeType = val!),
                      ),
                      if (_deliveryFeeType != 'free') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _deliveryFeeValueController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _deliveryFeeType == 'flat'
                                ? 'Flat Fee (A\$)'
                                : 'Fee per km (A\$)',
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deliveryMinOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Order Amount (A\$)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user, CookProfile? cook) {
    final initials = (user?.fullName ?? 'C')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    final statusColor = switch (cook?.status) {
      'active' => AppTheme.successGreen,
      'pending_verification' => Colors.amber,
      'suspended' => AppTheme.errorRed,
      _ => AppTheme.greyText,
    };

    final statusLabel = switch (cook?.status) {
      'active' => 'Active',
      'pending_verification' => 'Pending Verification',
      'suspended' => 'Suspended',
      'deactivated' => 'Deactivated',
      _ => cook?.status ?? 'Unknown',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryOrange,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cook?.displayName ?? user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 13, color: AppTheme.greyText),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (cook != null) ...[
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${cook.avgRating.toStringAsFixed(1)} (${cook.totalReviews})',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
