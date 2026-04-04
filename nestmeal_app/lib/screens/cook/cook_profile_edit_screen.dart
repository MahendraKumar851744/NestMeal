// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';

// import 'package:nestmeal_app/config/theme.dart';
// import 'package:nestmeal_app/providers/auth_provider.dart';
// import 'package:nestmeal_app/models/user_model.dart';
// import 'package:nestmeal_app/screens/auth/login_screen.dart';
// import 'package:nestmeal_app/screens/common/location_picker_screen.dart';

// class CookProfileEditScreen extends StatefulWidget {
//   const CookProfileEditScreen({super.key});

//   @override
//   State<CookProfileEditScreen> createState() => _CookProfileEditScreenState();
// }

// class _CookProfileEditScreenState extends State<CookProfileEditScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // User fields
//   late TextEditingController _fullNameController;
//   late TextEditingController _phoneController;

//   // Cook profile fields
//   late TextEditingController _displayNameController;
//   late TextEditingController _bioController;
//   late TextEditingController _kitchenStreetController;
//   late TextEditingController _kitchenCityController;
//   late TextEditingController _kitchenStateController;
//   late TextEditingController _kitchenZipController;
//   late TextEditingController _pickupInstructionsController;

//   // Delivery settings
//   late bool _deliveryEnabled;
//   late TextEditingController _deliveryRadiusController;
//   late String _deliveryFeeType;
//   late TextEditingController _deliveryFeeValueController;
//   late TextEditingController _deliveryMinOrderController;

//   double? _kitchenLatitude;
//   double? _kitchenLongitude;
//   bool _isInitialized = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_isInitialized) {
//       _initControllers();
//       _isInitialized = true;
//     }
//   }

//   void _initControllers() {
//     final user = context.read<AuthProvider>().currentUser;
//     final cook = user?.cookProfile;

//     _fullNameController = TextEditingController(text: user?.fullName ?? '');
//     _phoneController = TextEditingController(text: user?.phone ?? '');

//     _displayNameController = TextEditingController(text: cook?.displayName ?? '');
//     _bioController = TextEditingController(text: cook?.bio ?? '');
//     _kitchenStreetController = TextEditingController(text: cook?.kitchenStreet ?? '');
//     _kitchenCityController = TextEditingController(text: cook?.kitchenCity ?? '');
//     _kitchenStateController = TextEditingController(text: cook?.kitchenState ?? '');
//     _kitchenZipController = TextEditingController(text: cook?.kitchenZip ?? '');
//     _pickupInstructionsController = TextEditingController(text: cook?.pickupInstructions ?? '');
//     _kitchenLatitude = cook?.kitchenLatitude;
//     _kitchenLongitude = cook?.kitchenLongitude;

//     _deliveryEnabled = cook?.deliveryEnabled ?? false;
//     _deliveryRadiusController = TextEditingController(
//       text: (cook?.deliveryRadiusKm ?? 0) > 0 ? cook!.deliveryRadiusKm.toStringAsFixed(1) : '',
//     );
//     _deliveryFeeType = cook?.deliveryFeeType ?? 'flat';
//     _deliveryFeeValueController = TextEditingController(
//       text: (cook?.deliveryFeeValue ?? 0) > 0 ? cook!.deliveryFeeValue.toStringAsFixed(2) : '',
//     );
//     _deliveryMinOrderController = TextEditingController(
//       text: (cook?.deliveryMinOrder ?? 0) > 0 ? cook!.deliveryMinOrder.toStringAsFixed(2) : '',
//     );
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _phoneController.dispose();
//     _displayNameController.dispose();
//     _bioController.dispose();
//     _kitchenStreetController.dispose();
//     _kitchenCityController.dispose();
//     _kitchenStateController.dispose();
//     _kitchenZipController.dispose();
//     _pickupInstructionsController.dispose();
//     _deliveryRadiusController.dispose();
//     _deliveryFeeValueController.dispose();
//     _deliveryMinOrderController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSave() async {
//     if (!_formKey.currentState!.validate()) return;

//     final authProvider = context.read<AuthProvider>();
//     final cook = authProvider.currentUser?.cookProfile;
//     if (cook == null) return;

//     try {
//       // Update user profile (name, phone)
//       await authProvider.updateProfile(
//         _fullNameController.text.trim(),
//         _phoneController.text.trim(),
//         null,
//       );

//       // Update cook profile
//       final cookData = <String, dynamic>{
//         'display_name': _displayNameController.text.trim(),
//         'bio': _bioController.text.trim(),
//         'kitchen_street': _kitchenStreetController.text.trim(),
//         'kitchen_city': _kitchenCityController.text.trim(),
//         'kitchen_state': _kitchenStateController.text.trim(),
//         'kitchen_zip': _kitchenZipController.text.trim(),
//         'pickup_instructions': _pickupInstructionsController.text.trim(),
//         'delivery_enabled': _deliveryEnabled,
//       };

//       if (_kitchenLatitude != null) cookData['kitchen_latitude'] = _kitchenLatitude;
//       if (_kitchenLongitude != null) cookData['kitchen_longitude'] = _kitchenLongitude;

//       if (_deliveryEnabled) {
//         final radius = double.tryParse(_deliveryRadiusController.text.trim());
//         if (radius != null) cookData['delivery_radius_km'] = radius;
//         cookData['delivery_fee_type'] = _deliveryFeeType;
//         final feeValue = double.tryParse(_deliveryFeeValueController.text.trim());
//         if (feeValue != null) cookData['delivery_fee_value'] = feeValue;
//         final minOrder = double.tryParse(_deliveryMinOrderController.text.trim());
//         if (minOrder != null) cookData['delivery_min_order'] = minOrder;
//       }

//       await authProvider.updateCookProfile(cook.id, cookData);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Profile updated successfully!'),
//           backgroundColor: AppTheme.successGreen,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: AppTheme.errorRed,
//         ),
//       );
//     }
//   }

//   Future<void> _openKitchenLocationPicker() async {
//     LatLng? initial;
//     if (_kitchenLatitude != null && _kitchenLongitude != null) {
//       initial = LatLng(_kitchenLatitude!, _kitchenLongitude!);
//     }

//     final result = await Navigator.push<LocationResult>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => LocationPickerScreen(
//           initialLatLng: initial,
//           title: 'Kitchen Location',
//         ),
//       ),
//     );

//     if (result != null && mounted) {
//       setState(() {
//         _kitchenLatitude = result.latitude;
//         _kitchenLongitude = result.longitude;
//         _kitchenStreetController.text = result.street;
//         _kitchenCityController.text = result.city;
//         _kitchenStateController.text = result.state;
//         _kitchenZipController.text = result.zipCode;
//       });
//     }
//   }

//   Future<void> _handleLogout() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true || !mounted) return;

//     await context.read<AuthProvider>().logout();

//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.currentUser;
//     final cook = user?.cookProfile;

//     return Scaffold(
//       backgroundColor: AppTheme.warmCream,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header
//                 Text(
//                   'My Profile',
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                     color: AppTheme.darkText,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Manage your account and kitchen settings',
//                   style: TextStyle(fontSize: 14, color: AppTheme.greyText),
//                 ),
//                 const SizedBox(height: 24),

//                 // Profile Avatar & Status
//                 _buildProfileHeader(user, cook),
//                 const SizedBox(height: 24),

//                 // Personal Information
//                 _buildSectionCard(
//                   title: 'Personal Information',
//                   icon: Icons.person_outline,
//                   children: [
//                     TextFormField(
//                       controller: _fullNameController,
//                       textCapitalization: TextCapitalization.words,
//                       decoration: const InputDecoration(labelText: 'Full Name'),
//                       validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration: const InputDecoration(labelText: 'Phone'),
//                       validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       initialValue: user?.email ?? '',
//                       enabled: false,
//                       decoration: const InputDecoration(
//                         labelText: 'Email',
//                         suffixIcon: Icon(Icons.lock_outline, size: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Kitchen Identity
//                 _buildSectionCard(
//                   title: 'Kitchen Identity',
//                   icon: Icons.restaurant_outlined,
//                   children: [
//                     TextFormField(
//                       controller: _displayNameController,
//                       textCapitalization: TextCapitalization.words,
//                       decoration: const InputDecoration(
//                         labelText: 'Display Name / Kitchen Name',
//                         hintText: 'e.g., Mom\'s Kitchen',
//                       ),
//                       validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _bioController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         labelText: 'Bio',
//                         hintText: 'Tell customers about your cooking...',
//                         alignLabelWithHint: true,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Kitchen Address
//                 _buildSectionCard(
//                   title: 'Kitchen Address',
//                   icon: Icons.location_on_outlined,
//                   children: [
//                     // Pick on Map button
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: _openKitchenLocationPicker,
//                         icon: const Icon(Icons.map_outlined, size: 18),
//                         label: Text(
//                           _kitchenLatitude != null
//                               ? 'Change Location on Map'
//                               : 'Pick Location on Map',
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: AppTheme.primaryOrange,
//                           side: const BorderSide(color: AppTheme.primaryOrange),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     if (_kitchenLatitude != null) ...[
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           const Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
//                           const SizedBox(width: 6),
//                           Text(
//                             'Location set (${_kitchenLatitude!.toStringAsFixed(5)}, ${_kitchenLongitude!.toStringAsFixed(5)})',
//                             style: const TextStyle(fontSize: 12, color: AppTheme.successGreen),
//                           ),
//                         ],
//                       ),
//                     ],
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _kitchenStreetController,
//                       decoration: const InputDecoration(labelText: 'Street Address'),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _kitchenCityController,
//                             decoration: const InputDecoration(labelText: 'Suburb'),
//                             validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _kitchenStateController,
//                             decoration: const InputDecoration(labelText: 'City'),
//                             validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _kitchenZipController,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(labelText: 'Postcode'),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _pickupInstructionsController,
//                       maxLines: 2,
//                       decoration: const InputDecoration(
//                         labelText: 'Pickup Instructions',
//                         hintText: 'e.g., Ring doorbell, apartment 3B...',
//                         alignLabelWithHint: true,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Pickup Locations
//                 _buildSectionCard(
//                   title: 'Pickup Locations',
//                   icon: Icons.store_mall_directory_outlined,
//                   children: [
//                     Text(
//                       'Add locations where customers can pick up orders.',
//                       style: TextStyle(fontSize: 13, color: AppTheme.greyText),
//                     ),
//                     const SizedBox(height: 12),
//                     if (cook != null && cook.pickupLocations.isNotEmpty)
//                       ...cook.pickupLocations.map((loc) => Container(
//                             margin: const EdgeInsets.only(bottom: 8),
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: AppTheme.warmCream,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.location_on,
//                                     size: 18, color: AppTheme.primaryOrange),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         loc.label,
//                                         style: const TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 14),
//                                       ),
//                                       Text(
//                                         loc.fullAddress,
//                                         style: TextStyle(
//                                             fontSize: 12,
//                                             color: AppTheme.greyText),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete_outline,
//                                       size: 20, color: AppTheme.errorRed),
//                                   onPressed: () async {
//                                     try {
//                                       await context
//                                           .read<AuthProvider>()
//                                           .deletePickupLocation(loc.id);
//                                     } catch (_) {}
//                                   },
//                                 ),
//                               ],
//                             ),
//                           )),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: () => _showAddPickupLocationDialog(),
//                         icon: const Icon(Icons.add, size: 18),
//                         label: const Text('Add Pickup Location'),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: AppTheme.primaryOrange,
//                           side: const BorderSide(color: AppTheme.primaryOrange),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),

//                 // Delivery Settings
//                 _buildSectionCard(
//                   title: 'Delivery Settings',
//                   icon: Icons.delivery_dining_outlined,
//                   children: [
//                     SwitchListTile(
//                       title: const Text('Enable Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
//                       subtitle: Text(
//                         _deliveryEnabled ? 'You offer delivery to customers' : 'Pickup only',
//                         style: TextStyle(fontSize: 12, color: AppTheme.greyText),
//                       ),
//                       value: _deliveryEnabled,
//                       activeColor: AppTheme.successGreen,
//                       contentPadding: EdgeInsets.zero,
//                       onChanged: (val) => setState(() => _deliveryEnabled = val),
//                     ),
//                     if (_deliveryEnabled) ...[
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _deliveryRadiusController,
//                         keyboardType: TextInputType.number,
//                         decoration: const InputDecoration(
//                           labelText: 'Delivery Radius (km)',
//                           hintText: 'e.g., 5.0',
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       DropdownButtonFormField<String>(
//                         value: _deliveryFeeType,
//                         decoration: const InputDecoration(labelText: 'Delivery Fee Type'),
//                         items: const [
//                           DropdownMenuItem(value: 'flat', child: Text('Flat Rate')),
//                           DropdownMenuItem(value: 'per_km', child: Text('Per Kilometer')),
//                           DropdownMenuItem(value: 'free', child: Text('Free Delivery')),
//                         ],
//                         onChanged: (val) => setState(() => _deliveryFeeType = val!),
//                       ),
//                       if (_deliveryFeeType != 'free') ...[
//                         const SizedBox(height: 12),
//                         TextFormField(
//                           controller: _deliveryFeeValueController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: _deliveryFeeType == 'flat'
//                                 ? 'Flat Fee (A\$)'
//                                 : 'Fee per km (A\$)',
//                             prefixIcon: const Icon(Icons.attach_money),
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _deliveryMinOrderController,
//                         keyboardType: TextInputType.number,
//                         decoration: const InputDecoration(
//                           labelText: 'Minimum Order Amount (A\$)',
//                           prefixIcon: Icon(Icons.attach_money),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Save Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: authProvider.isLoading ? null : _handleSave,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: authProvider.isLoading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                         : const Text('Save Changes', style: TextStyle(fontSize: 16)),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // Logout Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: _handleLogout,
//                     icon: const Icon(Icons.logout, size: 18),
//                     label: const Text('Logout'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppTheme.errorRed,
//                       side: const BorderSide(color: AppTheme.errorRed),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _showAddPickupLocationDialog() async {
//     final labelCtrl = TextEditingController();
//     final streetCtrl = TextEditingController();
//     final cityCtrl = TextEditingController();
//     final stateCtrl = TextEditingController();
//     final zipCtrl = TextEditingController();

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Add Pickup Location'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: labelCtrl,
//                 decoration: const InputDecoration(
//                   labelText: 'Label',
//                   hintText: 'e.g., Home, Kitchen, Park...',
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: streetCtrl,
//                 decoration: const InputDecoration(labelText: 'Street Address'),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: cityCtrl,
//                       decoration: const InputDecoration(labelText: 'Suburb'),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: stateCtrl,
//                       decoration: const InputDecoration(labelText: 'City'),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: zipCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Postcode'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.primaryOrange,
//             ),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );

//     if (result == true && mounted) {
//       final label = labelCtrl.text.trim();
//       final street = streetCtrl.text.trim();
//       final city = cityCtrl.text.trim();
//       final state = stateCtrl.text.trim();
//       final zip = zipCtrl.text.trim();

//       if (label.isEmpty || street.isEmpty || city.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Label, street and suburb are required'),
//             backgroundColor: AppTheme.errorRed,
//           ),
//         );
//         return;
//       }

//       try {
//         await context.read<AuthProvider>().addPickupLocation({
//           'label': label,
//           'street': street,
//           'city': city,
//           'state': state,
//           'zip_code': zip,
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Pickup location added!'),
//               backgroundColor: AppTheme.successGreen,
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(e.toString()),
//               backgroundColor: AppTheme.errorRed,
//             ),
//           );
//         }
//       }
//     }
//   }

//   Widget _buildProfileHeader(UserModel? user, CookProfile? cook) {
//     final initials = (user?.fullName ?? 'C')
//         .split(' ')
//         .where((w) => w.isNotEmpty)
//         .map((w) => w[0].toUpperCase())
//         .take(2)
//         .join();

//     final statusColor = switch (cook?.status) {
//       'active' => AppTheme.successGreen,
//       'pending_verification' => Colors.amber,
//       'suspended' => AppTheme.errorRed,
//       _ => AppTheme.greyText,
//     };

//     final statusLabel = switch (cook?.status) {
//       'active' => 'Active',
//       'pending_verification' => 'Pending Verification',
//       'suspended' => 'Suspended',
//       'deactivated' => 'Deactivated',
//       _ => cook?.status ?? 'Unknown',
//     };

//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Avatar
//           CircleAvatar(
//             radius: 48,
//             backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
//             child: Text(
//               initials,
//               style: const TextStyle(
//                 fontSize: 36,
//                 fontWeight: FontWeight.bold,
//                 color: AppTheme.primaryOrange,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           // Name
//           Text(
//             cook?.displayName ?? user?.fullName ?? '',
//             style: GoogleFonts.playfairDisplay(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: AppTheme.darkText,
//             ),
//           ),
//           const SizedBox(height: 4),
//           // Email
//           Text(
//             user?.email ?? '',
//             style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
//           ),
//           const SizedBox(height: 12),
//           // Status badge
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: statusColor.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.circle, size: 8, color: statusColor),
//                 const SizedBox(width: 6),
//                 Text(
//                   statusLabel,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: statusColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Stats row
//           if (cook != null)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildStat(
//                   icon: Icons.star,
//                   iconColor: Colors.amber,
//                   value: cook.avgRating.toStringAsFixed(1),
//                   label: 'Rating',
//                 ),
//                 Container(
//                   height: 32,
//                   width: 1,
//                   color: AppTheme.lightGrey,
//                 ),
//                 _buildStat(
//                   icon: Icons.rate_review_outlined,
//                   iconColor: AppTheme.primaryOrange,
//                   value: '${cook.totalReviews}',
//                   label: 'Reviews',
//                 ),
//                 Container(
//                   height: 32,
//                   width: 1,
//                   color: AppTheme.lightGrey,
//                 ),
//                 _buildStat(
//                   icon: Icons.people_outline,
//                   iconColor: AppTheme.primaryOrange,
//                   value: '${cook.followersCount}',
//                   label: 'Followers',
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStat({
//     required IconData icon,
//     required Color iconColor,
//     required String value,
//     required String label,
//   }) {
//     return Column(
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 16, color: iconColor),
//             const SizedBox(width: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: AppTheme.darkText,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionCard({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 20, color: AppTheme.primaryOrange),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: GoogleFonts.playfairDisplay(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: AppTheme.darkText,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

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

  // Grouped Save Methods for Bottom Sheets
  Future<void> _savePersonalDetails(BuildContext ctx) async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.updateProfile(
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        null,
      );
      if (ctx.mounted) Navigator.pop(ctx);
      _showSuccess('Personal details updated');
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _saveKitchenProfile(BuildContext ctx) async {
    final authProvider = context.read<AuthProvider>();
    final cookId = authProvider.currentUser?.cookProfile?.id;
    if (cookId == null) return;

    try {
      await authProvider.updateCookProfile(cookId, {
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      if (ctx.mounted) Navigator.pop(ctx);
      _showSuccess('Kitchen identity updated');
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _saveKitchenAddress(BuildContext ctx) async {
    final authProvider = context.read<AuthProvider>();
    final cookId = authProvider.currentUser?.cookProfile?.id;
    if (cookId == null) return;

    final data = <String, dynamic>{
      'kitchen_street': _kitchenStreetController.text.trim(),
      'kitchen_city': _kitchenCityController.text.trim(),
      'kitchen_state': _kitchenStateController.text.trim(),
      'kitchen_zip': _kitchenZipController.text.trim(),
      'pickup_instructions': _pickupInstructionsController.text.trim(),
    };

    if (_kitchenLatitude != null) data['kitchen_latitude'] = _kitchenLatitude;
    if (_kitchenLongitude != null) data['kitchen_longitude'] = _kitchenLongitude;

    try {
      await authProvider.updateCookProfile(cookId, data);
      if (ctx.mounted) Navigator.pop(ctx);
      _showSuccess('Kitchen address updated');
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _saveDeliverySettings(BuildContext ctx) async {
    final authProvider = context.read<AuthProvider>();
    final cookId = authProvider.currentUser?.cookProfile?.id;
    if (cookId == null) return;

    final data = <String, dynamic>{
      'delivery_enabled': _deliveryEnabled,
    };

    if (_deliveryEnabled) {
      final radius = double.tryParse(_deliveryRadiusController.text.trim());
      if (radius != null) data['delivery_radius_km'] = radius;
      
      data['delivery_fee_type'] = _deliveryFeeType;
      
      final feeValue = double.tryParse(_deliveryFeeValueController.text.trim());
      if (feeValue != null) data['delivery_fee_value'] = feeValue;
      
      final minOrder = double.tryParse(_deliveryMinOrderController.text.trim());
      if (minOrder != null) data['delivery_min_order'] = minOrder;
    }

    try {
      await authProvider.updateCookProfile(cookId, data);
      if (ctx.mounted) Navigator.pop(ctx);
      _showSuccess('Delivery settings updated');
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    final authProvider = context.read<AuthProvider>();
    final cookId = authProvider.currentUser?.cookProfile?.id;
    if (cookId == null) return;

    try {
      // Opt-in UI update: Depending on your state management, you might want 
      // to wrap this in a loading overlay, but a quick switch is usually fine.
      await authProvider.updateCookProfile(cookId, {
        'is_available': isAvailable,
      });
      _showSuccess(isAvailable ? 'You are now visible to customers' : 'Your kitchen is hidden');
    } catch (e) {
      _showError('Failed to update availability: $e');
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.successGreen),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed),
    );
  }

  Future<void> _openKitchenLocationPicker(void Function(void Function()) setSheetState) async {
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
      setSheetState(() {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Log Out'),
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
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Curved White Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Cook Profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        _buildProfileHeader(user, cook),
                      ],
                    ),
                  ),
                ),

                // Menu Sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                       
                        // ---> ADD THIS NEW AVAILABILITY SECTION <---
                        _buildSectionTitle(context, 'Availability'),
                        const SizedBox(height: 8),
                        _buildMenuCard([
                          _ProfileMenuItem(
                            icon: (cook?.isAvailable ?? true) 
                                ? Icons.storefront 
                                : Icons.storefront_outlined,
                            title: 'Accepting Orders',
                            subtitle: (cook?.isAvailable ?? true) 
                                ? 'Visible to customers' 
                                : 'Hidden from customers',
                            trailing: Switch(
                              value: cook?.isAvailable ?? true,
                              activeColor: AppTheme.successGreen,
                              onChanged: (val) => _toggleAvailability(val),
                            ),
                            onTap: () {
                              // Let them toggle by tapping the whole row too
                              _toggleAvailability(!(cook?.isAvailable ?? true));
                            },
                          ),
                        ]),
                        const SizedBox(height: 20),
                        // ---> END OF NEW SECTION <---


                        // Account Section
                        _buildSectionTitle(context, 'Account'),
                        const SizedBox(height: 8),
                        _buildMenuCard([
                          _ProfileMenuItem(
                            icon: Icons.person_outline,
                            title: 'Personal Details',
                            onTap: () => _showPersonalDetailsSheet(context),
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Kitchen Section
                        _buildSectionTitle(context, 'Kitchen Details'),
                        const SizedBox(height: 8),
                        _buildMenuCard([
                          _ProfileMenuItem(
                            icon: Icons.restaurant_outlined,
                            title: 'Kitchen Identity',
                            onTap: () => _showKitchenIdentitySheet(context),
                          ),
                          _ProfileMenuItem(
                            icon: Icons.location_on_outlined,
                            title: 'Kitchen Address',
                            onTap: () => _showKitchenAddressSheet(context),
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Fulfillment Section
                        _buildSectionTitle(context, 'Fulfillment'),
                        const SizedBox(height: 8),
                        _buildMenuCard([
                          _ProfileMenuItem(
                            icon: Icons.delivery_dining_outlined,
                            title: 'Delivery Settings',
                            subtitle: _deliveryEnabled ? 'Delivery Enabled' : 'Pickup Only',
                            onTap: () => _showDeliverySettingsSheet(context),
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Support & System Section
                        _buildSectionTitle(context, 'System'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(color: AppTheme.errorRed),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.errorRed),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // UI Components
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

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          cook?.displayName ?? user?.fullName ?? '',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.greyText,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        if (cook != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                icon: Icons.star,
                iconColor: Colors.amber,
                value: cook.avgRating.toStringAsFixed(1),
                label: 'Rating',
              ),
              Container(height: 32, width: 1, color: AppTheme.lightGrey),
              _buildStat(
                icon: Icons.rate_review_outlined,
                iconColor: AppTheme.primaryOrange,
                value: '${cook.totalReviews}',
                label: 'Reviews',
              ),
              Container(height: 32, width: 1, color: AppTheme.lightGrey),
              _buildStat(
                icon: Icons.people_outline,
                iconColor: AppTheme.primaryOrange,
                value: '${cook.followersCount}',
                label: 'Followers',
              ),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.greyText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildMenuCard(List<_ProfileMenuItem> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      )
                    : null,
                trailing: item.trailing ??
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.greyText,
                    ),
                onTap: item.onTap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSheetHeader(String title) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // BOTTOM SHEETS
  void _showPersonalDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHeader('Personal Details'),
            TextField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _savePersonalDetails(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKitchenIdentitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHeader('Kitchen Identity'),
            TextField(
              controller: _displayNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., Mom\'s Kitchen',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell customers about your cooking...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveKitchenProfile(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Identity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKitchenAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHeader('Kitchen Address'),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openKitchenLocationPicker(setSheetState),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _kitchenStreetController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _kitchenCityController,
                        decoration: const InputDecoration(labelText: 'Suburb'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _kitchenStateController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _kitchenZipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Postcode'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pickupInstructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Instructions',
                    hintText: 'e.g., Ring doorbell...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveKitchenAddress(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliverySettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSheetHeader('Delivery Settings'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warmCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Enable Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _deliveryEnabled ? 'You offer delivery to customers' : 'Pickup only',
                      style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                    ),
                    value: _deliveryEnabled,
                    activeColor: AppTheme.successGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setSheetState(() => _deliveryEnabled = val),
                  ),
                ),
                if (_deliveryEnabled) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _deliveryRadiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Radius (km)',
                      hintText: 'e.g., 5.0',
                      prefixIcon: Icon(Icons.radar_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sleek Custom Dropdown replacement
                  GestureDetector(
                    onTap: () => _showFeeTypePicker(setSheetState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGrey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Delivery Fee Type', style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                              const SizedBox(height: 4),
                              Text(
                                _feeTypeLabel(_deliveryFeeType),
                                style: const TextStyle(fontSize: 16, color: AppTheme.darkText),
                              ),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppTheme.greyText),
                        ],
                      ),
                    ),
                  ),

                  if (_deliveryFeeType != 'free') ...[
                    const SizedBox(height: 16),
                    TextField(
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deliveryMinOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Order Amount (A\$)',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveDeliverySettings(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _feeTypeLabel(String type) {
    switch (type) {
      case 'flat': return 'Flat Rate';
      case 'per_km': return 'Per Kilometer';
      case 'free': return 'Free Delivery';
      default: return 'Flat Rate';
    }
  }

  void _showFeeTypePicker(void Function(void Function()) setParentSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          {'value': 'flat', 'label': 'Flat Rate', 'icon': Icons.horizontal_rule},
          {'value': 'per_km', 'label': 'Per Kilometer', 'icon': Icons.map_outlined},
          {'value': 'free', 'label': 'Free Delivery', 'icon': Icons.card_giftcard},
        ];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHeader('Select Fee Type'),
              ...options.map((opt) {
                final isSelected = _deliveryFeeType == opt['value'];
                return ListTile(
                  leading: Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? AppTheme.primaryOrange : AppTheme.greyText,
                  ),
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.primaryOrange : AppTheme.darkText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryOrange)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    setParentSheetState(() {
                      _deliveryFeeType = opt['value'] as String;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });
}