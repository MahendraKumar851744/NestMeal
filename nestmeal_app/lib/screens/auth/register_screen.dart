import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/services/api_service.dart';
import 'package:nestmeal_app/screens/auth/login_screen.dart';
import 'package:nestmeal_app/screens/auth/otp_verification_screen.dart';
import 'package:nestmeal_app/screens/common/location_picker_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Cook-specific fields
  final _kitchenNameController = TextEditingController();
  final _kitchenStreetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  double? _kitchenLatitude;
  double? _kitchenLongitude;
  XFile? _cookProfileImage;
  Uint8List? _cookProfileImageBytes;

  String _selectedRole = 'customer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _kitchenNameController.dispose();
    _kitchenStreetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.register(
        _emailController.text.trim(),
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        _selectedRole,
        _passwordController.text,
        _confirmPasswordController.text,
        businessName:
            _selectedRole == 'cook' ? _kitchenNameController.text.trim() : null,
        kitchenStreet:
            _selectedRole == 'cook' ? _kitchenStreetController.text.trim() : null,
        kitchenCity:
            _selectedRole == 'cook' ? _cityController.text.trim() : null,
        kitchenState:
            _selectedRole == 'cook' ? _stateController.text.trim() : null,
        kitchenZip:
            _selectedRole == 'cook' ? _zipController.text.trim() : null,
        kitchenLatitude:
            _selectedRole == 'cook' ? _kitchenLatitude : null,
        kitchenLongitude:
            _selectedRole == 'cook' ? _kitchenLongitude : null,
      );

      // Upload profile image if a cook selected one
      if (_selectedRole == 'cook' && _cookProfileImage != null && mounted) {
        final cookId = authProvider.currentUser?.cookProfile?.id;
        if (cookId != null) {
          try {
            final bytes = _cookProfileImageBytes ?? await _cookProfileImage!.readAsBytes();
            final filename = _cookProfileImage!.name.isNotEmpty ? _cookProfileImage!.name : 'profile.jpg';
            await authProvider.uploadCookProfileImage(cookId, bytes, filename);
          } catch (_) {
            // Non-fatal — cook can upload later from profile edit
          }
        }
      }

      if (!mounted) return;

      // Navigate to OTP verification instead of directly to the app
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phone: _phoneController.text.trim(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
        _cityController.text = result.city;
        _stateController.text = result.state;
        _zipController.text = result.zipCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Title
                Center(
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Join NestMeal today',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyText,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Role Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'customer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer'
                                  ? AppTheme.primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedRole == 'customer'
                                      ? Colors.white
                                      : AppTheme.greyText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'cook'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'cook'
                                  ? AppTheme.primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text(
                                'Cook',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedRole == 'cook'
                                      ? Colors.white
                                      : AppTheme.greyText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cook-specific fields
                if (_selectedRole == 'cook') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kitchen Details',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cook profile image (optional)
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Wrap(children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Camera'),
                                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Gallery'),
                                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                              ),
                            ]),
                          ),
                        );
                        if (source == null) return;
                        final picked = await ImagePicker().pickImage(
                          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85,
                        );
                        if (picked != null && mounted) {
                          final bytes = await picked.readAsBytes();
                          setState(() {
                            _cookProfileImage = picked;
                            _cookProfileImageBytes = bytes;
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                            backgroundImage: _cookProfileImageBytes != null
                                ? MemoryImage(_cookProfileImageBytes!)
                                : null,
                            child: _cookProfileImageBytes == null
                                ? const Icon(Icons.person_outline, size: 40, color: AppTheme.primaryOrange)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Profile Photo (optional)', style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _kitchenNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Kitchen Name',
                      hintText: 'Your kitchen or business name',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'cook' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter your kitchen name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pick on Map button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openKitchenLocationPicker,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(
                        _kitchenLatitude != null
                            ? 'Change Location on Map'
                            : 'Pick Kitchen Location on Map',
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

                  TextFormField(
                    controller: _kitchenStreetController,
                    decoration: const InputDecoration(
                      labelText: 'Kitchen Street',
                      hintText: 'Street address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'cook' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter the street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Suburb',
                            hintText: 'Suburb',
                          ),
                          validator: (value) {
                            if (_selectedRole == 'cook' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            hintText: 'City',
                          ),
                          validator: (value) {
                            if (_selectedRole == 'cook' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Postcode',
                            hintText: 'Postcode',
                          ),
                          validator: (value) {
                            if (_selectedRole == 'cook' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Terms & Conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        activeColor: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyText,
                          ),
                          children: [
                            const TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launchUrl(
                                    Uri.parse('https://example.com/terms-and-conditions'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Privacy Policy checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedPrivacy,
                        onChanged: (value) {
                          setState(() => _acceptedPrivacy = value ?? false);
                        },
                        activeColor: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.greyText,
                          ),
                          children: [
                            const TextSpan(text: 'I have read the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launchUrl(
                                    Uri.parse('https://example.com/privacy-policy'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
