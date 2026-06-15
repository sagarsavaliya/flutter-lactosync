import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/setup_checklist.dart';

class OnboardingDashboardPage extends ConsumerStatefulWidget {
  const OnboardingDashboardPage({super.key});

  @override
  ConsumerState<OnboardingDashboardPage> createState() =>
      _OnboardingDashboardPageState();
}

class _OnboardingDashboardPageState extends ConsumerState<OnboardingDashboardPage> {
  bool _loading = true;
  bool _skipping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ref.read(onboardingRepositoryProvider).fetchStatus();
      ref.invalidate(authSessionProvider);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _skip() async {
    setState(() => _skipping = true);
    try {
      await ref.read(onboardingRepositoryProvider).skipSubscription();
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapDioError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: CustomerDetailColors.background,
        body: Center(
          child: CircularProgressIndicator(color: CustomerDetailColors.accent),
        ),
      );
    }

    return FutureBuilder(
      future: ref.read(onboardingRepositoryProvider).fetchStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: CustomerDetailColors.background,
            body: Center(
              child: CircularProgressIndicator(color: CustomerDetailColors.accent),
            ),
          );
        }
        final status = snapshot.data!;
        if (status.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/dashboard');
          });
        }
        return SetupDashboardPage(
          status: status,
          showSkipSubscription: status.currentStep == 'first_subscription',
          onSkipSubscription: _skipping ? null : _skip,
        );
      },
    );
  }
}
