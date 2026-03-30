/// Stub implementation for platforms where flutter_stripe is not available (web).

void initializeStripe(String publishableKey) {
  // No-op on web
}

Future<void> initAndPresentPaymentSheet({
  required String clientSecret,
  required String merchantDisplayName,
}) async {
  throw UnsupportedError(
    'Stripe payments are not supported on web. Please use the mobile app.',
  );
}

bool get isStripeSupported => false;
