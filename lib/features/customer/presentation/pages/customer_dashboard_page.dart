import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../providers/customer_profile_provider.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final profileAsync = ref.watch(customerProfileProvider);

    return dashAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CusColors.surface,
        body: Center(child: CircularProgressIndicator(color: CusColors.primaryContainer)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CusColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: CusColors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('Failed to load', style: TextStyle(color: CusColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CusColors.primaryContainer),
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

// ── Main body ─────────────────────────────────────────────────────────────────

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
      backgroundColor: CusColors.surface,
      body: RefreshIndicator(
        color: CusColors.primaryContainer,
        onRefresh: () async {
          ref.invalidate(customerDashboardProvider);
          ref.invalidate(customerProfileProvider);
          await ref.read(customerDashboardProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            _SliverHeader(firstName: firstName),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            style: TextStyle(
                              color: CusColors.onSurfaceVariant,
                              fontSize: 14,
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
                  const SizedBox(height: 24),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sliver header ─────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final greeting = firstName.isNotEmpty ? 'Hello, $firstName 👋' : 'My Dairy';
    return SliverAppBar(
      backgroundColor: CusColors.surface,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      titleSpacing: 20,
      title: Text(
        greeting,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CusColors.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: CusColors.primary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Today's delivery card ─────────────────────────────────────────────────────

class _TodayDeliveryCard extends StatelessWidget {
  const _TodayDeliveryCard({required this.subs});
  final List<Map<String, dynamic>> subs;

  @override
  Widget build(BuildContext context) {
    final morningSubs = subs.where((s) => s['shift'] == 'morning').toList();
    final eveningSubs = subs.where((s) => s['shift'] == 'evening').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CusColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_outlined, size: 20, color: CusColors.primaryContainer),
              ),
              const SizedBox(width: 12),
              const Text(
                "Today's Delivery",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CusColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (morningSubs.isNotEmpty)
            _DeliveryShiftRow(shift: 'Morning', icon: Icons.wb_sunny_outlined, subs: morningSubs),
          if (morningSubs.isNotEmpty && eveningSubs.isNotEmpty) const SizedBox(height: 6),
          if (eveningSubs.isNotEmpty)
            _DeliveryShiftRow(shift: 'Evening', icon: Icons.nightlight_outlined, subs: eveningSubs),
        ],
      ),
    );
  }
}

class _DeliveryShiftRow extends StatelessWidget {
  const _DeliveryShiftRow({required this.shift, required this.icon, required this.subs});
  final String shift;
  final IconData icon;
  final List<Map<String, dynamic>> subs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CusColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          shift,
          style: const TextStyle(fontSize: 12, color: CusColors.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subs.map((s) => '${s['product_name'] ?? ''} ×${s['qty'] ?? ''}').join(', '),
            style: const TextStyle(fontSize: 13, color: CusColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Outstanding bill banner ───────────────────────────────────────────────────

class _OutstandingBanner extends StatelessWidget {
  const _OutstandingBanner({
    required this.balance,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String? upiVpa;
  final String? upiPayeeName;

  String get _formattedBalance =>
      '₹${NumberFormat('#,##,##0.##', 'en_IN').format(balance)}';

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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CusColors.primaryContainer, Color(0xFF1A5C3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CusColors.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT OUTSTANDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CusColors.onPrimaryContainer,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formattedBalance,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: CusColors.onPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _payNow,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CusColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: CusColors.primaryContainer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions grid (3×2) ──────────────────────────────────────────────────

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Tomorrow's delivery skipped"),
            backgroundColor: CusColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: CusColors.error),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(icon: Icons.skip_next_outlined, label: 'Skip Tomorrow', loading: _skipping, onTap: _skipTomorrow),
      _ActionItem(icon: Icons.beach_access_outlined, label: 'Vacation Mode', onTap: () => context.push('/customer/vacation')),
      _ActionItem(icon: Icons.edit_note_outlined, label: 'Change Sub', onTap: () => context.go('/customer/orders')),
      _ActionItem(icon: Icons.chat_outlined, label: 'WhatsApp', onTap: _whatsAppOwner),
      _ActionItem(icon: Icons.phone_outlined, label: 'Call Dairy', onTap: _callOwner),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CusColors.onSurface),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: CusColors.primaryContainer),
                  )
                : Icon(icon, size: 24, color: CusColors.primaryContainer),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CusColors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirm bottom sheet ──────────────────────────────────────────────────────

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
    backgroundColor: Colors.white,
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: CusColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CusColors.onSurface)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(fontSize: 14, color: CusColors.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CusColors.outlineVariant),
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: CusColors.onSurface,
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
                    backgroundColor: destructive ? CusColors.error : CusColors.primaryContainer,
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
