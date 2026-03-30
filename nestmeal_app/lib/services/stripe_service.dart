/// Conditional export: uses native stripe on mobile, stub on web.
export 'stripe_service_stub.dart'
    if (dart.library.io) 'stripe_service_native.dart';
