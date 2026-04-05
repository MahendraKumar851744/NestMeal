import 'package:flutter/foundation.dart';

class CartExtra {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartExtra({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  CartExtra copyWith({int? quantity}) => CartExtra(
        id: id,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
      );
}

class CartItem {
  final String mealId;
  final String title;
  final String? imageUrl;
  final double basePrice;
  int quantity;
  final String cookId;
  final String cookDisplayName;
  List<CartExtra> extras;

  CartItem({
    required this.mealId,
    required this.title,
    this.imageUrl,
    required this.basePrice,
    this.quantity = 1,
    required this.cookId,
    required this.cookDisplayName,
    List<CartExtra>? extras,
  }) : extras = extras ?? [];

  double get extrasSubtotal =>
      extras.fold(0.0, (sum, e) => sum + e.subtotal);

  double get lineTotal => (basePrice + extrasSubtotal) * quantity;
}

class CartProvider extends ChangeNotifier {
  List<CartItem> items = [];
  String? selectedCookId;
  String? cookDisplayName;
  List<String> supportedFulfillmentModes = [];
  String fulfillmentType = 'pickup';
  String selectedPaymentMethod = 'card';
  String? selectedSlotId;
  String? couponCode;
  double discountAmount = 0;
  String specialInstructions = '';
  double _deliveryFee = 0;

  double get itemTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get platformFee => itemTotal * 0.03;

  double get taxAmount => (itemTotal + platformFee) * 0.05;

  double get deliveryFee => _deliveryFee;

  set deliveryFee(double value) {
    _deliveryFee = value;
    notifyListeners();
  }

  double get totalAmount =>
      itemTotal + platformFee + taxAmount + _deliveryFee - discountAmount;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  /// Adds a meal to the cart. Extras are a list of selected [CartExtra].
  /// Returns false if the cart already has items from a different cook.
  bool addItem(
    String mealId,
    String title,
    String? imageUrl,
    double basePrice,
    String cookId,
    String cookDisplayName, {
    List<String> fulfillmentModes = const ['pickup', 'delivery'],
    List<CartExtra> extras = const [],
  }) {
    if (selectedCookId != null && selectedCookId != cookId && items.isNotEmpty) {
      return false;
    }

    selectedCookId = cookId;
    this.cookDisplayName = cookDisplayName;

    supportedFulfillmentModes =
        fulfillmentModes.isNotEmpty ? fulfillmentModes : ['pickup', 'delivery'];
    if (!supportedFulfillmentModes.contains(fulfillmentType)) {
      fulfillmentType = supportedFulfillmentModes.first;
      selectedSlotId = null;
    }

    final existingIndex = items.indexWhere((item) => item.mealId == mealId);
    if (existingIndex >= 0) {
      // Same meal already in cart — just increment quantity, keep existing extras
      items[existingIndex].quantity++;
    } else {
      items.add(CartItem(
        mealId: mealId,
        title: title,
        imageUrl: imageUrl,
        basePrice: basePrice,
        cookId: cookId,
        cookDisplayName: cookDisplayName,
        extras: List<CartExtra>.from(extras),
      ));
    }

    notifyListeners();
    return true;
  }

  void removeItem(String mealId) {
    items.removeWhere((item) => item.mealId == mealId);
    if (items.isEmpty) {
      selectedCookId = null;
      cookDisplayName = null;
    }
    notifyListeners();
  }

  void updateQuantity(String mealId, int quantity) {
    if (quantity <= 0) {
      removeItem(mealId);
      return;
    }
    final index = items.indexWhere((item) => item.mealId == mealId);
    if (index >= 0) {
      items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// Update the quantity of a specific extra on a cart item.
  /// Pass quantity = 0 to remove the extra.
  void updateExtraQuantity(String mealId, String extraId, int quantity) {
    final index = items.indexWhere((item) => item.mealId == mealId);
    if (index < 0) return;

    final item = items[index];
    if (quantity <= 0) {
      item.extras.removeWhere((e) => e.id == extraId);
    } else {
      final extraIndex = item.extras.indexWhere((e) => e.id == extraId);
      if (extraIndex >= 0) {
        item.extras[extraIndex] = item.extras[extraIndex].copyWith(quantity: quantity);
      }
    }
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  void clearCart() {
    items.clear();
    selectedCookId = null;
    cookDisplayName = null;
    supportedFulfillmentModes = [];
    fulfillmentType = 'pickup';
    selectedPaymentMethod = 'card';
    selectedSlotId = null;
    couponCode = null;
    discountAmount = 0;
    specialInstructions = '';
    _deliveryFee = 0;
    notifyListeners();
  }

  void setFulfillmentType(String type) {
    fulfillmentType = type;
    selectedSlotId = null;
    if (type == 'pickup') _deliveryFee = 0;
    notifyListeners();
  }

  void setSelectedSlot(String slotId) {
    selectedSlotId = slotId;
    notifyListeners();
  }

  void setCoupon(String code, double discount) {
    couponCode = code;
    discountAmount = discount;
    notifyListeners();
  }

  void clearCoupon() {
    couponCode = null;
    discountAmount = 0;
    notifyListeners();
  }

  void setSpecialInstructions(String text) {
    specialInstructions = text;
    notifyListeners();
  }
}
