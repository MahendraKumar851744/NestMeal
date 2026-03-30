import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

/// A one-time screen shown after login/register to request location permission.
/// After the user grants, denies, or skips, it navigates to [destination].
class LocationPermissionScreen extends StatefulWidget {
  final Widget destination;

  const LocationPermissionScreen({super.key, required this.destination});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them in your device settings.'),
            ),
          );
        }
        setState(() => _isRequesting = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is permanently denied. Please enable it from app settings.'),
              duration: Duration(seconds: 3),
            ),
          );
          // Open app settings so the user can enable it manually
          await Geolocator.openAppSettings();
        }
        setState(() => _isRequesting = false);
        return;
      }

      // Permission granted or whileInUse — proceed
      _navigateToDestination();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permission: $e')),
        );
      }
      setState(() => _isRequesting = false);
    }
  }

  void _navigateToDestination() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 60,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Enable Location',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'NestMeal needs your location to find nearby home cooks and deliver meals to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.greyText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Features list
              _buildFeatureRow(
                Icons.restaurant_outlined,
                'Discover home cooks near you',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.delivery_dining_outlined,
                'Accurate delivery estimates',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.map_outlined,
                'Easy pickup point navigation',
              ),

              const Spacer(flex: 3),

              // Allow button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRequesting ? null : _requestPermission,
                  icon: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.location_on_outlined),
                  label: Text(
                      _isRequesting ? 'Requesting...' : 'Allow Location Access'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isRequesting ? null : _navigateToDestination,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppTheme.greyText,
                      fontSize: 14,
                    ),
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

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryOrange, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
