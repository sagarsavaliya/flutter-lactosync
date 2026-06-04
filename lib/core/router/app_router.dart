import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/forgot_pin_page.dart';
import '../../features/auth/presentation/reset_pin_page.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/verify_otp_page.dart';
import '../../features/customer/presentation/pages/customer_coming_soon_page.dart';
import '../../features/onboarding/presentation/pages/add_customer_page.dart';
import '../../features/onboarding/presentation/pages/customer_saved_page.dart';
import '../../features/onboarding/presentation/pages/farm_details_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_dashboard_page.dart';
import '../../features/onboarding/presentation/pages/product_setup_page.dart';
import '../../features/onboarding/presentation/pages/role_picker_page.dart';
import '../../features/onboarding/presentation/pages/set_pin_page.dart';
import '../../features/onboarding/presentation/pages/signup_otp_page.dart';
import '../../features/onboarding/presentation/pages/signup_page.dart';
import '../../features/onboarding/presentation/pages/subscription_page.dart';
import '../../features/owner/presentation/pages/billing_page.dart';
import '../../features/owner/presentation/pages/activity_page.dart';
import '../../features/owner/presentation/pages/customer_detail_page.dart';
import '../../features/owner/presentation/pages/customers_list_page.dart';
import '../../features/owner/presentation/pages/daily_orders_page.dart';
import '../../features/owner/presentation/pages/invoice_detail_page.dart';
import '../../features/owner/presentation/pages/owner_home_page.dart';
import '../../features/owner/presentation/pages/owner_settings_page.dart';
import '../../features/owner/presentation/pages/payments_page.dart';
import '../../features/owner/presentation/shell/owner_shell.dart';
import '../../core/constants/app_strings.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/signup/otp',
      name: 'signupOtp',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return SignupOtpPage(
          mobile: extra['mobile'] ?? '',
          firstName: extra['first_name'] ?? '',
          lastName: extra['last_name'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/signup/role',
      name: 'signupRole',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return RolePickerPage(
          mobile: extra['mobile'] ?? '',
          signupToken: extra['signup_token'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/signup/set-pin',
      name: 'setPin',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return SetPinPage(
          mobile: extra['mobile'] ?? '',
          signupToken: extra['signup_token'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/onboarding/farm',
      name: 'onboardingFarm',
      builder: (context, state) => const FarmDetailsPage(),
    ),
    GoRoute(
      path: '/onboarding/dashboard',
      name: 'onboardingDashboard',
      builder: (context, state) => const OnboardingDashboardPage(),
    ),
    GoRoute(
      path: '/onboarding/products',
      name: 'onboardingProducts',
      builder: (context, state) => const ProductSetupPage(),
    ),
    GoRoute(
      path: '/onboarding/customer',
      name: 'onboardingCustomer',
      builder: (context, state) => const AddCustomerPage(),
    ),
    GoRoute(
      path: '/onboarding/customer-saved',
      name: 'customerSaved',
      builder: (context, state) => const CustomerSavedPage(),
    ),
    GoRoute(
      path: '/onboarding/subscription',
      name: 'onboardingSubscription',
      builder: (context, state) => const SubscriptionPage(),
    ),
    GoRoute(
      path: '/customer/coming-soon',
      name: 'customerComingSoon',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return CustomerComingSoonPage(fromSignup: extra['from'] == 'signup');
      },
    ),
    GoRoute(
      path: '/dashboard',
      redirect: (_, __) => '/owner/home',
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => OwnerShell(child: child),
      routes: [
        GoRoute(
          path: '/owner/home',
          builder: (context, state) => const OwnerHomePage(),
        ),
        GoRoute(
          path: '/owner/customers',
          builder: (context, state) => const CustomersListPage(),
        ),
        GoRoute(
          path: '/owner/daily-orders',
          builder: (context, state) => const DailyOrdersPage(),
        ),
        GoRoute(
          path: '/owner/billing',
          builder: (context, state) => const BillingPage(),
        ),
        GoRoute(
          path: '/owner/payment',
          builder: (context, state) => const PaymentsPage(),
        ),
        GoRoute(
          path: '/owner/settings',
          builder: (context, state) => const OwnerSettingsPage(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/billing/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return InvoiceDetailPage(invoiceId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/customers/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return CustomerDetailPage(customerId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/activity',
      builder: (context, state) => const ActivityPage(),
    ),
    GoRoute(
      path: '/forgot-pin',
      name: 'forgotPin',
      builder: (context, state) => const ForgotPinPage(),
    ),
    GoRoute(
      path: '/verify-otp',
      name: 'verifyOtp',
      builder: (context, state) {
        final mobile = state.extra as String? ?? '';
        return VerifyOtpPage(mobile: mobile);
      },
    ),
    GoRoute(
      path: '/reset-pin',
      name: 'resetPin',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return ResetPinPage(
          mobile: extra['mobile'] ?? '',
          resetToken: extra['reset_token'] ?? '',
        );
      },
    ),
  ],
);
