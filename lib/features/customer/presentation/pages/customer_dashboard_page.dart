import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final profileAsync = ref.watch(customerProfileProvider);

    return dashAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CustomerDetailColors.background,
        body: Center(child: CircularProgressIndicator(color: CustomerDetailColors.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CustomerDetailColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.cloudOff, size: 48, color: CustomerDetailColors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Failed to load',
                style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.accent),
                onPressed: () => ref.invalidate(customerDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _DashboardBody(
        data: data,
        profileAsync: profileAsync,
        ref: ref,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.profileAsync,
    required this.ref,
  });

  final Map<String, dynamic> data;
  final AsyncValue<CustomerProfileData> profileAsync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final balance = (data['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
    final upiVpa = data['upi_vpa'] as String?;
    final upiPayeeName = data['upi_payee_name'] as String?;
    final rawSubs = data['active_subscriptions'];
    final subs = rawSubs is List ? rawSubs.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    final farmContact = profileAsync.valueOrNull?.farmContact;
    final ownerMobile = farmContact?['owner_mobile'] as String?;
    final firstName = profileAsync.valueOrNull?.profile['first_name'] as String? ?? '';

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: RefreshIndicator(
        color: CustomerDetailColors.accent,
        onRefresh: () async {
          ref.invalidate(customerDashboardProvider);
          ref.invalidate(customerProfileProvider);
          await ref.read(customerDashboardProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            _SliverHeader(firstName: firstName),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  if (subs.isNotEmpty) ...[
                    _TodayDeliveryCard(subs: subs),
                    const SizedBox(height: 16),
                  ],
                  if (balance > 0) ...[
                    _OutstandingBanner(
                      balance: balance,
                      upiVpa: upiVpa,
                      upiPayeeName: upiPayeeName,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _QuickActionsGrid(ownerMobile: ownerMobile, ref: ref),
                  const SizedBox(height: 24),
                  if (subs.isNotEmpty) ...[
                    CustomerDetailSectionLabel(
                      title: AppStrings.subscriptionsTitle.toUpperCase(),
                    ),
                    ...subs.asMap().entries.map((entry) {
                      final line = customerSubscriptionLineFromOrders(
                        subscription: entry.value,
                        days: const [],
                      );
                      return CustomerDetailSubscriptionCard(
                        index: entry.key + 1,
                        line: line,
                        month: DateTime(DateTime.now().year, DateTime.now().month),
                        showCalendar: false,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  CustomerDetailSectionLabel(
                    title: AppStrings.consumptionTitle.toUpperCase(),
                  ),
                  Builder(
                    builder: (context) {
                      final consumption = data['consumption'] as Map<String, dynamic>?;
                      final rows = customerConsumptionRowsFromJson(consumption);
                      final grandTotal = customerConsumptionGrandTotal(consumption);
                      if (rows.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            AppStrings.noConsumptionRecorded,
                            style: AppText.body.copyWith(
                              color: CustomerDetailColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return CustomerDetailConsumptionCard(
                        rows: rows,
                        grandTotal: grandTotal,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final greeting = firstName.isNotEmpty ? 'Hello, $firstName' : 'My Dairy';
    return SliverAppBar(
      backgroundColor: CustomerDetailColors.background,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      titleSpacing: 16,
      title: Text(
        greeting,
        style: AppText.screenTitle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CustomerDetailColors.accent,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.bell, color: CustomerDetailColors.accent, size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _TodayDeliveryCard extends StatelessWidget {
  const _TodayDeliveryCard({required this.subs});
  final List<Map<String, dynamic>> subs;

  @override
  Widget build(BuildContext context) {
    final morningSubs = subs.where((s) => s['shift'] == 'morning').toList();
    final eveningSubs = subs.where((s) => s['shift'] == 'evening').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CustomerDetailColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.truck,
                  size: 22,
                  color: CustomerDetailColors.success,
                ),
              ),
              const SizedBox(width: 13),
              Text(
                "Today's Delivery",
                style: AppText.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: CustomerDetailColors.divider),
          const SizedBox(height: 12),
          if (morningSubs.isNotEmpty)
            _DeliveryShiftRow(shift: 'Morning', isMorning: true, subs: morningSubs),
          if (morningSubs.isNotEmpty && eveningSubs.isNotEmpty) const SizedBox(height: 8),
          if (eveningSubs.isNotEmpty)
            _DeliveryShiftRow(shift: 'Evening', isMorning: false, subs: eveningSubs),
        ],
      ),
    );
  }
}

class _DeliveryShiftRow extends StatelessWidget {
  const _DeliveryShiftRow({
    required this.shift,
    required this.isMorning,
    required this.subs,
  });
  final String shift;
  final bool isMorning;
  final List<Map<String, dynamic>> subs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CustomerDetailColors.morningChipBg,
            border: Border.all(color: CustomerDetailColors.morningChipBorder),
            borderRadius: BorderRadius.circular(CustomerDetailMetrics.chipRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMorning ? LucideIcons.sun : LucideIcons.moon,
                size: 13,
                color: CustomerDetailColors.morningChipInk,
              ),
              const SizedBox(width: 5),
              Text(
                shift,
                style: AppText.meta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.morningChipInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subs.map((s) => '${s['product_name'] ?? ''} ×${s['qty'] ?? ''}').join(', '),
            style: AppText.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.bodyInk,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OutstandingBanner extends StatelessWidget {
  const _OutstandingBanner({
    required this.balance,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String? upiVpa;
  final String? upiPayeeName;

  Future<void> _payNow() async {
    if (upiVpa == null || upiVpa!.isEmpty) return;
    final payee = Uri.encodeComponent(upiPayeeName ?? 'Dairy');
    final vpa = Uri.encodeComponent(upiVpa!);
    final amount = balance.toStringAsFixed(2);
    final url = 'upi://pay?pa=$vpa&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomerDetailColors.duesGradientStart,
            CustomerDetailColors.duesGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CustomerDetailColors.danger.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending balance',
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF7DBCD),
            ),
          ),
          Text(
            '₹${fmt.format(balance.round())}',
            style: AppText.screenTitle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFCEFE8),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: _payNow,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.wallet, size: 17, color: CustomerDetailColors.danger),
                    const SizedBox(width: 7),
                    Text(
                      'Pay Now',
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerStatefulWidget {
  const _QuickActionsGrid({required this.ownerMobile, required this.ref});
  final String? ownerMobile;
  final WidgetRef ref;

  @override
  ConsumerState<_QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends ConsumerState<_QuickActionsGrid> {
  bool _skipping = false;

  Future<void> _skipTomorrow() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateStr =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final confirmed = await _showConfirmSheet(
      context: context,
      title: 'Skip Tomorrow?',
      message: 'Your delivery on $dateStr will be skipped.',
      confirmLabel: 'Skip',
    );
    if (confirmed != true) return;

    setState(() => _skipping = true);
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      await repo.skipDay(dateStr);
      ref.invalidate(customerDashboardProvider);
      ref.invalidate(customerOrdersProvider(
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}',
      ));
      if (mounted) {
        AppSnackBar.show(context, "Tomorrow's delivery skipped");
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  Future<void> _callOwner() async {
    final mobile = widget.ownerMobile;
    if (mobile == null || mobile.isEmpty) return;
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsAppOwner() async {
    final mobile = widget.ownerMobile;
    if (mobile == null || mobile.isEmpty) return;
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.length == 10 ? '91$cleaned' : cleaned;
    final uri = Uri.parse('https://wa.me/$number');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not open WhatsApp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(icon: LucideIcons.skipForward, label: 'Skip Tomorrow', loading: _skipping, onTap: _skipTomorrow),
      _ActionItem(icon: LucideIcons.plane, label: 'Vacation Mode', onTap: () => context.push('/customer/vacation')),
      _ActionItem(icon: LucideIcons.clipboardEdit, label: 'Change Sub', onTap: () => context.go('/customer/orders')),
      _ActionItem(icon: LucideIcons.messageCircle, label: 'WhatsApp', onTap: _whatsAppOwner),
      _ActionItem(icon: LucideIcons.phone, label: 'Call Dairy', onTap: _callOwner),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomerDetailSectionLabel(title: 'QUICK ACTIONS'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => _QuickActionTile(
            icon: actions[i].icon,
            label: actions[i].label,
            loading: actions[i].loading,
            onTap: actions[i].onTap,
          ),
        ),
      ],
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.surface,
      borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
            border: Border.all(color: CustomerDetailColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF283C28).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CustomerDetailColors.accent,
                      ),
                    )
                  : Icon(icon, size: 22, color: CustomerDetailColors.accent),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: false,
    backgroundColor: CustomerDetailColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CustomerDetailColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppText.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppText.body.copyWith(
              color: CustomerDetailColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CustomerDetailColors.border),
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: CustomerDetailColors.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: destructive
                        ? CustomerDetailColors.danger
                        : CustomerDetailColors.accent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
