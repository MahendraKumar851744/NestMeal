import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';

import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/stripe_service.dart' as stripe_svc;
import 'providers/auth_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/order_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/review_provider.dart';
import 'providers/slot_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/address_provider.dart';
import 'providers/cook_provider.dart';
import 'providers/story_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/cook/cook_shell.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  stripe_svc.initializeStripe(
    'pk_test_51TFuhvDjhz5B3fVQVenaO1KM7WaHnrQPOqNLdJCFXHfXFKRjXyPAAQfTHB79pw3pnH1Tnt0t3vgm4dGh1ug7xSlC00lXh9La8M',
  );
  runApp(const NestMealApp());
}

class NestMealApp extends StatelessWidget {
  const NestMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final apiService = ApiService(authService: authService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MealProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SlotProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CouponProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AddressProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CookProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => StoryProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'NestMeal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashWrapper(),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.tryAutoLogin();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'NestMeal',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Home-cooked meals, delivered fresh',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.greyText,
                    ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // If logged in but not verified, route to OTP verification
    if (!auth.currentUser!.isVerified) {
      return OTPVerificationScreen(phone: auth.currentUser!.phone);
    }

    switch (auth.currentUser!.role) {
      case 'cook':
        return const CookShell();
      case 'admin':
        return const AdminDashboardScreen();
      case 'customer':
      default:
        return const CustomerShell();
    }
  }
}
