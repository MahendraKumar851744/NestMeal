import 'package:flutter/foundation.dart';

class CartItem {
  final String mealId;
  final String title;
  final String? imageUrl;
  final double price;
  int quantity;
  final String cookId;
  final String cookDisplayName;

  CartItem({
    required this.mealId,
    required this.title,
    this.imageUrl,
    required this.price,
    this.quantity = 1,
    required this.cookId,
    required this.cookDisplayName,
  });
}

class CartProvider extends ChangeNotifier {
  List<CartItem> items = [];
  String? selectedCookId;
  String? cookDisplayName;
  List<String> supportedFulfillmentModes = [];
  String fulfillmentType = 'pickup';
  String selectedPaymentMethod = 'card'; // 'card' or 'wallet'
  String? selectedSlotId;
  String? couponCode;
  double discountAmount = 0;
  String specialInstructions = '';
  double _deliveryFee = 0;

  double get itemTotal =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double get platformFee => itemTotal * 0.03;

  double get taxAmount => (itemTotal + platformFee) * 0.05;

  double get deliveryFee => _deliveryFee;

  set deliveryFee(double value) {
    _deliveryFee = value;
    notifyListeners();
  }

  double get totalAmount =>
      itemTotal + platformFee + taxAmount + _deliveryFee - discountAmount;

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  /// Adds an item to the cart. If the item comes from a different cook,
  /// returns false to indicate the cart needs to be cleared first.
  /// The caller should confirm with the user and call clearCart() before retrying.
  bool addItem(
    String mealId,
    String title,
    String? imageUrl,
    double price,
    String cookId,
    String cookDisplayName, {
    List<String> fulfillmentModes = const ['pickup', 'delivery'],
  }) {
    // Check if adding from a different cook
    if (selectedCookId != null && selectedCookId != cookId && items.isNotEmpty) {
      return false;
    }

    selectedCookId = cookId;
    this.cookDisplayName = cookDisplayName;

    // Set supported modes from the meal; auto-select first supported mode
    supportedFulfillmentModes = fulfillmentModes.isNotEmpty
        ? fulfillmentModes
        : ['pickup', 'delivery'];
    if (!supportedFulfillmentModes.contains(fulfillmentType)) {
      fulfillmentType = supportedFulfillmentModes.first;
      selectedSlotId = null;
    }

    final existingIndex = items.indexWhere((item) => item.mealId == mealId);
    if (existingIndex >= 0) {
      items[existingIndex].quantity++;
    } else {
      items.add(CartItem(
        mealId: mealId,
        title: title,
        imageUrl: imageUrl,
        price: price,
        cookId: cookId,
        cookDisplayName: cookDisplayName,
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
    if (type == 'pickup') {
      _deliveryFee = 0;
    }
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
