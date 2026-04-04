class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String accountsUrl = '$baseUrl/accounts';
  static const String mealsUrl = '$baseUrl/meals';
  static const String ordersUrl = '$baseUrl/orders';
  static const String paymentsUrl = '$baseUrl/payments';
  static const String reviewsUrl = '$baseUrl/reviews';
  static const String couponsUrl = '$baseUrl/coupons';
  static const String deliveryZonesUrl = '$baseUrl/delivery-zones';
  static const String deliverySlotsUrl = '$baseUrl/delivery-slots';
  static const String deliveryFeeUrl = '$baseUrl/delivery/calculate-fee';
  static const String notificationsUrl = '$baseUrl/notifications';
  static const String pickupSlotsUrl = '$baseUrl/pickup-slots';
  static const String payoutsUrl = '$baseUrl/payouts';
  static const String cookProfilesUrl = '$baseUrl/accounts/cook-profiles';
  static const String cooksPublicUrl = '$baseUrl/accounts/cooks';
  static const String followingUrl = '$baseUrl/accounts/me/following';
  static const String storiesUrl = '$baseUrl/stories';
  static const String walletTopUpUrl = '$baseUrl/payments/wallet/top-up';

  static String orderMessagesUrl(String orderId) =>
      '$ordersUrl/$orderId/messages/';
}
