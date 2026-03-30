/// Native implementation using flutter_stripe for mobile/desktop.
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void initializeStripe(String publishableKey) {
  Stripe.publishableKey = publishableKey;
}

Future<void> initAndPresentPaymentSheet({
  required String clientSecret,
  required String merchantDisplayName,
}) async {
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: merchantDisplayName,
      style: ThemeMode.light,
    ),
  );
  await Stripe.instance.presentPaymentSheet();
}

bool get isStripeSupported => true;
