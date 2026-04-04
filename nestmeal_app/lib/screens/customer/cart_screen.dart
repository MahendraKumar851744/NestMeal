import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/stripe_service.dart' as stripe_svc;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/slot_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/payment_provider.dart';
import '../common/location_picker_screen.dart';
import 'order_detail_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const CartScreen({super.key, this.onGoHome});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  final _deliveryStreetController = TextEditingController();
  final _deliveryCityController = TextEditingController();
  final _deliveryStateController = TextEditingController();
  final _deliveryZipController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  bool _isPlacingOrder = false;
  AddressModel? _selectedAddress;
  bool _useNewAddress = false;
  double? _newAddressLat;
  double? _newAddressLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    final addressProvider = context.read<AddressProvider>();
    await addressProvider.fetchAddresses();
    // Auto-select the default address
    if (addressProvider.addresses.isNotEmpty) {
      final defaultAddr = addressProvider.addresses
          .where((a) => a.isDefault)
          .firstOrNull;
      final addr = defaultAddr ?? addressProvider.addresses.first;
      _selectAddress(addr);
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _deliveryStreetController.dispose();
    _deliveryCityController.dispose();
    _deliveryStateController.dispose();
    _deliveryZipController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _loadSlots() {
    final cart = context.read<CartProvider>();
    if (cart.selectedCookId != null) {
      final slotProvider = context.read<SlotProvider>();
      if (cart.fulfillmentType == 'pickup') {
        slotProvider.fetchPickupSlots(cookId: cart.selectedCookId);
      } else {
        slotProvider.fetchDeliverySlots(cookId: cart.selectedCookId);
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final cart = context.read<CartProvider>();
    final couponProvider = context.read<CouponProvider>();

    try {
      final result = await couponProvider.validateCoupon(
        code,
        cart.itemTotal,
        cart.fulfillmentType,
      );

      if (result['valid'] == true) {
        final rawDiscount = result['discount_amount'];
        final discount = (rawDiscount is String)
            ? (double.tryParse(rawDiscount) ?? 0.0)
            : (rawDiscount ?? 0).toDouble();
        cart.setCoupon(code, discount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coupon applied! You save A\$${discount.toStringAsFixed(2)}'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid coupon code'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();

    if (cart.isEmpty) return;

    // Validate slot selection for both pickup and delivery
    if (cart.selectedSlotId == null) {
      final slotType =
          cart.fulfillmentType == 'pickup' ? 'pickup' : 'delivery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a $slotType time slot'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (cart.fulfillmentType == 'delivery' &&
        _selectedAddress == null &&
        _deliveryStreetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a delivery address'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Save special instructions to cart before placing
    cart.setSpecialInstructions(_specialInstructionsController.text.trim());

    setState(() => _isPlacingOrder = true);

    try {
      final orderProvider = context.read<OrderProvider>();
      final paymentProvider = context.read<PaymentProvider>();

      // 1. Create the order
      final items = cart.items
          .map((item) => {
                'mealId': item.mealId,
                'quantity': item.quantity,
              })
          .toList();

      await orderProvider.createOrder(
        cart.selectedCookId!,
        cart.fulfillmentType,
        items,
        cart.selectedSlotId,
        couponCode: cart.couponCode,
        specialInstructions: cart.specialInstructions.isNotEmpty
            ? cart.specialInstructions
            : null,
        deliveryAddressStreet: cart.fulfillmentType == 'delivery'
            ? _deliveryStreetController.text.trim()
            : null,
        deliveryAddressCity: cart.fulfillmentType == 'delivery'
            ? _deliveryCityController.text.trim()
            : null,
        deliveryAddressState: cart.fulfillmentType == 'delivery'
            ? _deliveryStateController.text.trim()
            : null,
        deliveryAddressZip: cart.fulfillmentType == 'delivery'
            ? _deliveryZipController.text.trim()
            : null,
        deliveryAddressLat: cart.fulfillmentType == 'delivery'
            ? _newAddressLat
            : null,
        deliveryAddressLng: cart.fulfillmentType == 'delivery'
            ? _newAddressLng
            : null,
      );

      final order = orderProvider.selectedOrder;
      if (order == null) throw Exception('Order creation failed');

      // 2. Create Stripe PaymentIntent
      final intentData = await paymentProvider.createPaymentIntent(order.id);
      final clientSecret = intentData['client_secret'] as String;
      final paymentIntentId =
          intentData['stripe_payment_intent_id'] as String;

      if (stripe_svc.isStripeSupported) {
        // 3. Init & present the Stripe payment sheet (mobile/desktop)
        await stripe_svc.initAndPresentPaymentSheet(
          clientSecret: clientSecret,
          merchantDisplayName: 'NestMeal',
        );
      }

      // 4. Confirm payment with backend
      await paymentProvider.confirmPayment(paymentIntentId);

      // 6. Clear cart and navigate
      cart.clearCart();
      _specialInstructionsController.clear();
      _deliveryStreetController.clear();
      _deliveryCityController.clear();
      _deliveryStateController.clear();
      _deliveryZipController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Order placed.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      }
    } on UnsupportedError catch (e) {
      // Stripe not supported on this platform (web)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Payments not supported on this platform'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _selectAddress(AddressModel address) {
    setState(() {
      _selectedAddress = address;
      _useNewAddress = false;
      _deliveryStreetController.text = address.street;
      _deliveryCityController.text = address.city;
      _deliveryStateController.text = address.state;
      _deliveryZipController.text = address.zipCode;
      _newAddressLat = address.latitude;
      _newAddressLng = address.longitude;
    });
  }

  Future<void> _openDeliveryLocationPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(title: 'Delivery Location'),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _useNewAddress = true;
        _selectedAddress = null;
        _deliveryStreetController.text = result.street;
        _deliveryCityController.text = result.city;
        _deliveryStateController.text = result.state;
        _deliveryZipController.text = result.zipCode;
        _newAddressLat = result.latitude;
        _newAddressLng = result.longitude;
      });
    }
  }

  Widget _buildAddressSelector() {
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saved addresses
        if (addressProvider.isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        else if (addresses.isNotEmpty) ...[
          ...addresses.map((address) => GestureDetector(
                onTap: () => _selectAddress(address),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedAddress?.id == address.id && !_useNewAddress
                          ? AppTheme.primaryOrange
                          : AppTheme.lightGrey,
                      width: _selectedAddress?.id == address.id && !_useNewAddress
                          ? 1.5
                          : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        address.label.toLowerCase() == 'work'
                            ? Icons.work_outline
                            : Icons.home_outlined,
                        size: 20,
                        color: _selectedAddress?.id == address.id && !_useNewAddress
                            ? AppTheme.primaryOrange
                            : AppTheme.greyText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedAddress?.id == address.id &&
                                            !_useNewAddress
                                        ? AppTheme.primaryOrange
                                        : AppTheme.darkText,
                                  ),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              address.fullAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedAddress?.id == address.id && !_useNewAddress
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: _selectedAddress?.id == address.id && !_useNewAddress
                            ? AppTheme.primaryOrange
                            : AppTheme.lightGrey,
                      ),
                    ],
                  ),
                ),
              )),
        ],

        // "Enter new address" option
        GestureDetector(
          onTap: () {
            setState(() {
              _useNewAddress = !_useNewAddress;
              if (_useNewAddress) {
                _selectedAddress = null;
                _deliveryStreetController.clear();
                _deliveryCityController.clear();
                _deliveryStateController.clear();
                _deliveryZipController.clear();
                _newAddressLat = null;
                _newAddressLng = null;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _useNewAddress
                    ? AppTheme.primaryOrange
                    : AppTheme.lightGrey,
                width: _useNewAddress ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_location_alt_outlined,
                  size: 20,
                  color: _useNewAddress
                      ? AppTheme.primaryOrange
                      : AppTheme.greyText,
                ),
                const SizedBox(width: 10),
                Text(
                  'Enter a new address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _useNewAddress
                        ? AppTheme.primaryOrange
                        : AppTheme.darkText,
                  ),
                ),
                const Spacer(),
                Icon(
                  _useNewAddress
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: _useNewAddress
                      ? AppTheme.primaryOrange
                      : AppTheme.lightGrey,
                ),
              ],
            ),
          ),
        ),

        // Manual input fields (shown only when "Enter new address" is selected)
        if (_useNewAddress) ...[
          const SizedBox(height: 4),
          // Pick on Map button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openDeliveryLocationPicker,
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text(
                _newAddressLat != null
                    ? 'Change Location on Map'
                    : 'Pick Location on Map',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: const BorderSide(color: AppTheme.primaryOrange),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_newAddressLat != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                const SizedBox(width: 4),
                Text(
                  'Location pinned on map',
                  style: const TextStyle(fontSize: 11, color: AppTheme.successGreen),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _deliveryStreetController,
            decoration: const InputDecoration(
              hintText: 'Street address',
              prefixIcon:
                  Icon(Icons.location_on_outlined, color: AppTheme.greyText),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deliveryCityController,
                  decoration: const InputDecoration(
                    hintText: 'City',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _deliveryStateController,
                  decoration: const InputDecoration(
                    hintText: 'State',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _deliveryZipController,
                  decoration: const InputDecoration(
                    hintText: 'ZIP',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          'Your Cart',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
      ),
      body: cart.isEmpty ? _buildEmptyCart() : _buildCartContent(cart),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.greyText.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse meals and add something delicious!',
            style: TextStyle(color: AppTheme.greyText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => widget.onGoHome?.call(),
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            label: const Text(
              'Browse Meals',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cook info
              if (cart.cookDisplayName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ordering from ${cart.cookDisplayName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.greyText,
                    ),
                  ),
                ),

              // Cart items
              ...cart.items.map((item) => _CartItemCard(
                    item: item,
                    onIncrement: () => cart.updateQuantity(
                        item.mealId, item.quantity + 1),
                    onDecrement: () => cart.updateQuantity(
                        item.mealId, item.quantity - 1),
                    onRemove: () => cart.removeItem(item.mealId),
                  )),

              const SizedBox(height: 24),

              // Delivery Method Toggle
              Text(
                'Delivery Method',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Pickup',
                      icon: Icons.store_outlined,
                      isSelected: cart.fulfillmentType == 'pickup',
                      onTap: () {
                        cart.setFulfillmentType('pickup');
                        _loadSlots();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Delivery',
                      icon: Icons.delivery_dining_outlined,
                      isSelected: cart.fulfillmentType == 'delivery',
                      onTap: () {
                        cart.setFulfillmentType('delivery');
                        _loadSlots();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slot selection
              if (cart.fulfillmentType == 'pickup') ...[
                Text(
                  'Pickup Time',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _SlotSelector(
                  selectedSlotId: cart.selectedSlotId,
                  onSlotSelected: (slotId) => cart.setSelectedSlot(slotId),
                  isPickup: true,
                ),
              ] else ...[
                // Delivery slot selector
                Text(
                  'Delivery Time',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _SlotSelector(
                  selectedSlotId: cart.selectedSlotId,
                  onSlotSelected: (slotId) => cart.setSelectedSlot(slotId),
                  isPickup: false,
                ),
                const SizedBox(height: 16),

                // Delivery address
                Text(
                  'Delivery Address',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAddressSelector(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppTheme.primaryOrange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery fee will be calculated based on distance',
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

              const SizedBox(height: 24),

              // Special Instructions
              Text(
                'Special Instructions',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _specialInstructionsController,
                decoration: const InputDecoration(
                  hintText: 'Any allergies, preferences, or special requests?',
                  prefixIcon:
                      Icon(Icons.edit_note_outlined, color: AppTheme.greyText),
                ),
                maxLines: 2,
                maxLength: 300,
              ),

              const SizedBox(height: 16),

              // Payment Method — Stripe
              Text(
                'Payment',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryOrange,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF635BFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Color(0xFF635BFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pay with Stripe',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cards, Apple Pay, Google Pay & more',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.lock_outlined,
                      size: 18,
                      color: AppTheme.successGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Coupon
              Text(
                'Have a coupon?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        suffixIcon: cart.couponCode != null
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppTheme.greyText),
                                onPressed: () {
                                  cart.clearCoupon();
                                  _couponController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: cart.couponCode != null ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
              if (cart.couponCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: AppTheme.successGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Coupon "${cart.couponCode}" applied',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Price Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Subtotal',
                      amount: cart.itemTotal,
                    ),
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: 'Service fee (3%)',
                      amount: cart.platformFee,
                    ),
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: 'Tax (5%)',
                      amount: cart.taxAmount,
                    ),
                    if (cart.fulfillmentType == 'delivery') ...[
                      const SizedBox(height: 8),
                      _PriceRow(
                        label: 'Delivery fee',
                        amount: cart.deliveryFee,
                      ),
                    ],
                    if (cart.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _PriceRow(
                        label: 'Discount',
                        amount: -cart.discountAmount,
                        isDiscount: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'A\$${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Place Order Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Place Order  \u00B7  A\$${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Cart Item Card ─────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 70,
                      width: 70,
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 70,
                      width: 70,
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      child: const Icon(Icons.restaurant,
                          color: AppTheme.greyText),
                    ),
                  )
                : Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.restaurant, color: AppTheme.greyText),
                  ),
          ),
          const SizedBox(width: 12),

          // Title, cook, price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${item.cookDisplayName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Column(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppTheme.errorRed),
                constraints: const BoxConstraints(
                  minHeight: 28,
                  minWidth: 28,
                ),
                padding: EdgeInsets.zero,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onDecrement,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onIncrement,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Toggle Button ──────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.lightGrey,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.greyText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.greyText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slot Selector (works for both Pickup and Delivery) ─────────────────────

class _SlotSelector extends StatelessWidget {
  final String? selectedSlotId;
  final ValueChanged<String> onSlotSelected;
  final bool isPickup;

  const _SlotSelector({
    required this.selectedSlotId,
    required this.onSlotSelected,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    final slotProvider = context.watch<SlotProvider>();

    if (slotProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    // Build a unified list of slot data for rendering
    final int slotCount;
    final String slotType;
    if (isPickup) {
      slotCount = slotProvider.pickupSlots.length;
      slotType = 'pickup';
    } else {
      slotCount = slotProvider.deliverySlots.length;
      slotType = 'delivery';
    }

    if (slotCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
        ),
        child: Text(
          'No $slotType slots available. The cook may not have set up slots yet.',
          style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: slotCount,
        itemBuilder: (context, index) {
          final String slotId;
          final String displayDate;
          final String displayTime;
          final int slotsRemaining;
          final bool isAvailable;

          if (isPickup) {
            final slot = slotProvider.pickupSlots[index];
            slotId = slot.id;
            displayDate = slot.displayDate;
            displayTime = slot.displayTime;
            slotsRemaining = slot.slotsRemaining;
            isAvailable = slot.isAvailable;
          } else {
            final slot = slotProvider.deliverySlots[index];
            slotId = slot.id;
            displayDate = slot.displayDate;
            displayTime = slot.displayTime;
            slotsRemaining = slot.slotsRemaining;
            isAvailable = slot.isAvailable;
          }

          final isSelected = selectedSlotId == slotId;

          return GestureDetector(
            onTap: isAvailable ? () => onSlotSelected(slotId) : null,
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryOrange
                    : isAvailable
                        ? Colors.white
                        : AppTheme.lightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : AppTheme.lightGrey,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayTime,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$slotsRemaining left',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Price Row ──────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.greyText,
          ),
        ),
        Text(
          isDiscount
              ? '-A\$${amount.abs().toStringAsFixed(2)}'
              : 'A\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDiscount ? AppTheme.successGreen : AppTheme.darkText,
          ),
        ),
      ],
    );
  }
}
