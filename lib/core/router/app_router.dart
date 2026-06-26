import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../features/auth/presentation/forgot_pin_page.dart';
import '../../features/auth/presentation/reset_pin_page.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/verify_otp_page.dart';
import '../../features/customer/presentation/pages/customer_coming_soon_page.dart';
import '../../features/customer/presentation/pages/customer_dashboard_page.dart';
import '../../features/customer/presentation/pages/customer_payments_page.dart';
import '../../features/customer/presentation/pages/customer_login_page.dart';
import '../../features/customer/presentation/pages/customer_orders_page.dart';
import '../../features/customer/presentation/pages/customer_otp_page.dart';
import '../../features/customer/presentation/pages/customer_profile_page.dart';
import '../../features/customer/presentation/pages/customer_set_pin_page.dart';
import '../../features/customer/presentation/pages/customer_vacation_page.dart';
import '../../features/customer/presentation/shell/customer_shell.dart';
import '../../features/onboarding/domain/entities/onboarding_models.dart';
import '../../features/onboarding/presentation/pages/add_customer_page.dart';
import '../../features/onboarding/presentation/pages/farm_details_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_dashboard_page.dart';
import '../../features/onboarding/presentation/pages/product_setup_page.dart';
import '../../features/onboarding/presentation/pages/role_picker_page.dart';
import '../../features/onboarding/presentation/pages/set_pin_page.dart';
import '../../features/onboarding/presentation/pages/signup_otp_page.dart';
import '../../features/onboarding/presentation/pages/signup_page.dart';
import '../../features/onboarding/presentation/pages/subscription_page.dart';
import '../../features/owner/presentation/pages/activity_page.dart';
import '../../features/owner/presentation/pages/communications_page.dart';
import '../../features/owner/presentation/pages/billing_page.dart';
import '../../features/owner/presentation/pages/customer_detail_page.dart';
import '../../features/owner/presentation/pages/edit_customer_page.dart';
import '../../features/owner/presentation/pages/customers_list_page.dart';
import '../../features/owner/presentation/pages/daily_orders_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_cash_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_forgot_pin_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_login_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_pickup_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_profile_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_reset_pin_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_set_pin_page.dart';
import '../../features/delivery_boy/presentation/pages/delivery_boy_stops_page.dart';
import '../../features/delivery_boy/presentation/shell/delivery_boy_shell.dart';
import '../../features/owner/presentation/pages/delivery_boys_page.dart';
import '../../features/owner/presentation/pages/invoice_detail_page.dart';
import '../../features/owner/presentation/pages/owner_home_page.dart';
import '../../features/owner/presentation/pages/owner_route_sheet_page.dart';
import '../../features/owner/presentation/pages/owner_settings_page.dart';
import '../../features/owner/presentation/pages/payments_page.dart';
import '../../features/owner/presentation/pages/route_detail_page.dart';
import '../../features/owner/presentation/pages/routes_page.dart';
import '../../features/owner/presentation/shell/owner_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
final customerShellNavigatorKey = GlobalKey<NavigatorState>();
final deliveryBoyShellNavigatorKey = GlobalKey<NavigatorState>();

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
      redirect: (_, __) => '/onboarding/customer',
    ),
    GoRoute(
      path: '/onboarding/subscription',
      name: 'onboardingSubscription',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final lockedId = extra['lockedCustomerId'] as int?;
        final rawCustomer = extra['prefilledCustomer'];
        CustomerItem? prefilledCustomer;
        if (rawCustomer is CustomerItem) {
          prefilledCustomer = rawCustomer;
        } else if (rawCustomer is Map) {
          prefilledCustomer = CustomerItem.fromJson(
            Map<String, dynamic>.from(rawCustomer),
          );
        }
        return SubscriptionPage(
          lockedCustomerId: lockedId,
          prefilledCustomer: prefilledCustomer,
        );
      },
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
          path: '/owner/routes',
          builder: (context, state) => const RoutesPage(),
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
      path: '/owner/customers/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EditCustomerPage(customerId: id);
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
      path: '/owner/communications',
      builder: (context, state) => const CommunicationsPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/routes/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return RouteDetailPage(routeId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/delivery-boys',
      builder: (context, state) => const DeliveryBoysPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/owner/route-sheet',
      builder: (context, state) => const OwnerRouteSheetPage(),
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

    // ── Customer auth screens (CA-11) ────────────────────────────────────────
    GoRoute(
      path: '/customer/login',
      name: 'customerLogin',
      builder: (context, state) => const CustomerLoginPage(),
    ),
    GoRoute(
      path: '/customer/otp',
      name: 'customerOtp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CustomerOtpPage(
          initialContact: (extra['contact'] as String?) ?? '',
          reason: (extra['reason'] as String?) ?? 'first_time',
        );
      },
    ),
    GoRoute(
      path: '/customer/set-pin',
      name: 'customerSetPin',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CustomerSetPinPage(
          contact: (extra['contact'] as String?) ?? '',
        );
      },
    ),

    // ── Customer pushed screens (outside the shell) ──────────────────────────
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/customer/vacation',
      builder: (context, state) => const CustomerVacationPage(),
    ),

    // ── Delivery Boy ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/delivery-boy/login',
      builder: (context, state) => const DeliveryBoyLoginPage(),
    ),
    GoRoute(
      path: '/delivery-boy/forgot-pin',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return DeliveryBoyForgotPinPage(initialPhone: phone);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/delivery-boy/reset-pin',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return DeliveryBoyResetPinPage(
          phone: (extra['phone'] as String?) ?? '',
          resetToken: (extra['reset_token'] as String?) ?? '',
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/delivery-boy/change-pin',
      builder: (context, state) => const DeliveryBoySetPinPage(),
    ),
    ShellRoute(
      navigatorKey: deliveryBoyShellNavigatorKey,
      builder: (context, state, child) => DeliveryBoyShell(child: child),
      routes: [
        GoRoute(
          path: '/delivery-boy/pickup',
          builder: (context, state) => const DeliveryBoyPickupPage(),
        ),
        GoRoute(
          path: '/delivery-boy/stops',
          builder: (context, state) => const DeliveryBoyStopsPage(),
        ),
        GoRoute(
          path: '/delivery-boy/cash',
          builder: (context, state) => const DeliveryBoyCashPage(),
        ),
        GoRoute(
          path: '/delivery-boy/profile',
          builder: (context, state) => const DeliveryBoyProfilePage(),
        ),
        GoRoute(
          path: '/delivery-boy/home',
          redirect: (_, __) => '/delivery-boy/pickup',
        ),
        GoRoute(
          path: '/delivery-boy/route-sheet',
          redirect: (_, __) => '/delivery-boy/stops',
        ),
      ],
    ),

    // ── Customer shell + tabs ────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: customerShellNavigatorKey,
      builder: (context, state, child) => CustomerShell(child: child),
      routes: [
        GoRoute(
          path: '/customer/home',
          name: 'customerHome',
          builder: (context, state) => const CustomerDashboardPage(),
        ),
        GoRoute(
          path: '/customer/orders',
          name: 'customerOrders',
          builder: (context, state) => const CustomerOrdersPage(),
        ),
        GoRoute(
          path: '/customer/payments',
          name: 'customerPayments',
          builder: (context, state) => const CustomerPaymentsPage(),
        ),
        GoRoute(
          path: '/customer/profile',
          name: 'customerProfile',
          builder: (context, state) => const CustomerProfilePage(),
        ),
      ],
    ),
  ],
);
