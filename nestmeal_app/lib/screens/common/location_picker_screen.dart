import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../config/theme.dart';

/// Data class returned when a location is confirmed.
class LocationResult {
  final double latitude;
  final double longitude;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String formattedAddress;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.formattedAddress,
  });
}

/// A full-screen Google Map picker.
///
/// Opens with the given [initialLatLng] or the device's current location.
/// The user can drag the map (pin stays centered), tap "My Location", or
/// type an address in the search bar. On confirm, returns a [LocationResult].
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLatLng;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLatLng,
    this.title = 'Pick Location',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();

  // Default to Sydney, Australia — will be overridden by device location
  LatLng _currentLatLng = const LatLng(-33.8688, 151.2093);

  String _addressLine = '';
  String _street = '';
  String _city = '';
  String _state = '';
  String _zipCode = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  Timer? _debounce;
  Timer? _searchDebounce;
  List<_AddressSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatLng != null) {
      _currentLatLng = widget.initialLatLng!;
      _reverseGeocode(_currentLatLng);
    } else {
      _goToMyLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Device location ──────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in settings.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);

      _animateTo(latLng);
      _reverseGeocode(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // ── Camera / Map ─────────────────────────────────────────────────────

  void _animateTo(LatLng latLng) {
    setState(() => _currentLatLng = latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
  }

  void _onCameraIdle() {
    // Debounce reverse geocoding while the user is still dragging
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(_currentLatLng);
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentLatLng = position.target;
  }

  // ── Geocoding ────────────────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _street = [p.street, p.subLocality, p.thoroughfare]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          _city = p.locality ?? p.subAdministrativeArea ?? '';
          _state = p.administrativeArea ?? '';
          _zipCode = p.postalCode ?? '';
          _addressLine = [_street, _city, _state, _zipCode]
              .where((s) => s.isNotEmpty)
              .join(', ');
        });
      }
    } catch (_) {
      // Geocoding can occasionally fail — silently ignore
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoadingAddress = true);

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        _animateTo(latLng);
        _reverseGeocode(latLng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found for that address')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find that address')),
        );
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // ── Autocomplete suggestions ──────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      // Bias towards Australia
      final locations = await locationFromAddress('$query, Australia');
      if (!mounted) return;

      final results = <_AddressSuggestion>[];
      for (final loc in locations.take(5)) {
        try {
          final placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final street = [p.street, p.subLocality, p.thoroughfare]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');
            final city = p.locality ?? p.subAdministrativeArea ?? '';
            final state = p.administrativeArea ?? '';
            final zip = p.postalCode ?? '';
            final address = [street, city, state, zip]
                .where((s) => s.isNotEmpty)
                .join(', ');

            results.add(_AddressSuggestion(
              address: address,
              street: street,
              city: city,
              state: state,
              zipCode: zip,
              latLng: LatLng(loc.latitude, loc.longitude),
            ));
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  void _selectSuggestion(_AddressSuggestion suggestion) {
    _searchController.text = suggestion.address;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _animateTo(suggestion.latLng);
    setState(() {
      _street = suggestion.street;
      _city = suggestion.city;
      _state = suggestion.state;
      _zipCode = suggestion.zipCode;
      _addressLine = suggestion.address;
    });
  }

  // ── Confirm ──────────────────────────────────────────────────────────

  void _confirmLocation() {
    final result = LocationResult(
      latitude: _currentLatLng.latitude,
      longitude: _currentLatLng.longitude,
      street: _street,
      city: _city,
      state: _state,
      zipCode: _zipCode,
      formattedAddress: _addressLine,
    );
    Navigator.pop(context, result);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Center pin (static, always centered)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),

          // Top bar: back button + search
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  Material(
                    elevation: 2,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.darkText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Search bar
                  Expanded(
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(28),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          setState(() => _showSuggestions = false);
                          _searchAddress();
                        },
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search address...',
                          hintStyle: const TextStyle(fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _showSuggestions = false;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Autocomplete suggestions dropdown
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 60,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 44),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            size: 20, color: AppTheme.primaryOrange),
                        title: Text(
                          s.address,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(s),
                      );
                    },
                  ),
                ),
              ),
            ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
              onPressed: _isLoadingLocation ? null : _goToMyLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppTheme.primaryOrange),
            ),
          ),

          // Bottom address card + confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  const SizedBox(height: 16),

                  Text(
                    widget.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address display
                  if (_isLoadingAddress)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 20, color: AppTheme.primaryOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _addressLine.isNotEmpty
                                ? _addressLine
                                : 'Move the map to select a location',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addressLine.isNotEmpty ? _confirmLocation : null,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSuggestion {
  final String address;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final LatLng latLng;

  const _AddressSuggestion({
    required this.address,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latLng,
  });
}
