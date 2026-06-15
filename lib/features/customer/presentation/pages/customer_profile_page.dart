import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../owner/domain/entities/owner_models.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../providers/customer_auth_provider.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/customer_dashboard_styles.dart';
import '../widgets/customer_profile_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';
import '../../../../core/widgets/app_snackbar.dart';

class CustomerProfilePage extends ConsumerWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CusDashColors.background,
        body: Center(child: CircularProgressIndicator(color: CusDashColors.accent)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: CusDashColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.user, size: 48, color: CusDashColors.inkMuted),
              const SizedBox(height: 12),
              Text(
                error is ApiException ? error.message : 'Failed to load profile.',
                style: AppText.body.copyWith(color: CusDashColors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CusDashColors.accent),
                onPressed: () => ref.invalidate(customerProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _ProfileContent(data: data),
    );
  }
}

// ── Profile content ───────────────────────────────────────────────────────────

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.data});
  final CustomerProfileData data;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.data.profile['whatsapp_enabled'] == true;
  }

  @override
  void didUpdateWidget(_ProfileContent old) {
    super.didUpdateWidget(old);
    _notificationsEnabled = widget.data.profile['whatsapp_enabled'] == true;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _firstName => (widget.data.profile['first_name'] as String? ?? '').trim();
  String get _lastName => (widget.data.profile['last_name'] as String? ?? '').trim();
  String get _fullName {
    final parts = [_firstName, _lastName].where((s) => s.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(' ');
  }
  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '';
    final l = _lastName.isNotEmpty ? _lastName[0].toUpperCase() : '';
    final r = '$f$l';
    return r.isNotEmpty ? r : '?';
  }
  String get _mobile => (widget.data.profile['contact'] as String? ?? '').trim();

  String get _deliveryAddress {
    final parts = [
      widget.data.profile['address_line'],
      widget.data.profile['area'],
      widget.data.profile['landmark'],
      widget.data.profile['city'],
      widget.data.profile['zip'],
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String _formatMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return raw;
  }

  String _subscriptionLabel(
    Map<String, dynamic> sub,
    List<ConsumptionRow> rows,
  ) {
    final name = sub['product_name'] as String? ?? 'Subscription';
    for (final row in rows) {
      if (row.productName.toLowerCase().contains(name.toLowerCase().split(' ').first)) {
        return '${row.productName} – ₹${row.unitRate.round()}';
      }
    }
    if (rows.isNotEmpty) {
      return '${rows.first.productName} – ₹${rows.first.unitRate.round()}';
    }
    return name;
  }

  void _showManagePlanSheet(String ownerMobile) {
    showModalBottomSheet<void>(
      context: context,
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
            Text(
              'Manage your plan',
              style: AppText.cardTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CusDashColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To change quantity, shift, or product, contact your dairy owner.',
              style: AppText.body.copyWith(
                fontSize: 14,
                color: CusDashColors.inkMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (ownerMobile.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _call(ownerMobile);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: CusDashColors.accent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(LucideIcons.phone, size: 18),
                  label: const Text('Call dairy'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Notifications toggle ─────────────────────────────────────────────────────

  Future<void> _onNotificationsToggle(bool newValue) async {
    setState(() => _notificationsEnabled = newValue);
    try {
      await ref.read(customerProfileProvider.notifier).saveProfile({'whatsapp_enabled': newValue});
    } catch (_) {
      if (mounted) setState(() => _notificationsEnabled = !newValue);
    }
  }

  // ── Contact actions ──────────────────────────────────────────────────────────

  Future<void> _call(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(String mobile) async {
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

  Future<bool?> _showConfirmSheet({
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
                  color: CustomerDetailColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CustomerDetailColors.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(fontSize: 14, color: CustomerDetailColors.onSurfaceVariant, height: 1.5)),
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
                      backgroundColor: destructive ? CustomerDetailColors.danger : CustomerDetailColors.accent,
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

  void _showFaqSheet() {
    const faqs = [
      ('How do I skip a delivery?', 'Go to Home → Quick Actions → Skip Tomorrow, or open the Orders calendar and tap on tomorrow\'s date.'),
      ('How do I change my subscription quantity?', 'Go to Orders, tap on any upcoming delivery date, and adjust the quantity using the stepper.'),
      ('How do I pay my bill?', 'Go to Payments and tap "Pay Now" on your outstanding balance. You can pay via GPay, PhonePe, Paytm, or any UPI app.'),
      ('How do I apply for vacation?', 'Go to Home → Quick Actions → Vacation Mode, or open the Profile and tap "Manage Vacation".'),
      ('When is my bill generated?', 'Bills are generated at the end of each month based on deliveries made.'),
      ('How do I update my delivery address?', 'Go to Profile and tap "Change" next to your delivery address.'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: CustomerDetailColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('FAQs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CustomerDetailColors.onSurface)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: faqs.length,
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: CustomerDetailColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CustomerDetailColors.border.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faqs[i].$1,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CustomerDetailColors.onSurface)),
                      const SizedBox(height: 6),
                      Text(faqs[i].$2,
                          style: const TextStyle(fontSize: 13, color: CustomerDetailColors.onSurfaceVariant, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: CustomerDetailColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CustomerDetailColors.onSurface)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: const [
                  _PrivacySection(
                    title: 'Data We Collect',
                    body: 'We collect your name, mobile number, and delivery address to manage your milk subscription. Your contact details are only shared with your dairy owner for delivery purposes.',
                  ),
                  _PrivacySection(
                    title: 'How We Use Your Data',
                    body: 'Your data is used solely to process deliveries, generate bills, and send delivery notifications. We do not sell or share your data with third parties.',
                  ),
                  _PrivacySection(
                    title: 'Payment Information',
                    body: 'Payments are processed via UPI apps on your device. We do not store any payment card or UPI credentials.',
                  ),
                  _PrivacySection(
                    title: 'Data Security',
                    body: 'All data is transmitted securely over HTTPS. Access to your account is protected by a PIN that only you know.',
                  ),
                  _PrivacySection(
                    title: 'Your Rights',
                    body: 'You may request deletion of your account and personal data at any time by contacting your dairy owner or reaching out to LactoSync support.',
                  ),
                  _PrivacySection(
                    title: 'Contact',
                    body: 'For privacy concerns, contact: support@lactosync.com',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await _showConfirmSheet(
      title: 'Logout?',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      destructive: true,
    );
    if (confirmed != true) return;

    final prefs = ref.read(customerSharedPrefsProvider);
    await prefs.remove('customer_auth_token');
    if (mounted) context.go('/customer/login');
  }

  // ── Edit profile ─────────────────────────────────────────────────────────────

  Future<void> _openEditSheet() async {
    final profile = widget.data.profile;

    final addressCtrl = TextEditingController(text: profile['address_line'] as String? ?? '');
    final areaCtrl = TextEditingController(text: profile['area'] as String? ?? '');
    final landmarkCtrl = TextEditingController(text: profile['landmark'] as String? ?? '');
    final zipCtrl = TextEditingController(text: profile['zip'] as String? ?? '');
    final cityCtrl = TextEditingController(text: profile['city'] as String? ?? '');
    final stateCtrl = TextEditingController(text: profile['state'] as String? ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: CustomerDetailColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(
        addressCtrl: addressCtrl,
        areaCtrl: areaCtrl,
        landmarkCtrl: landmarkCtrl,
        zipCtrl: zipCtrl,
        cityCtrl: cityCtrl,
        stateCtrl: stateCtrl,
        onSave: (fields) async {
          await ref.read(customerProfileProvider.notifier).saveProfile(fields);
          if (mounted) {
            Navigator.of(context).pop();
            AppSnackBar.show(context, 'Address updated.');
          }
        },
      ),
    );

    addressCtrl.dispose();
    areaCtrl.dispose();
    landmarkCtrl.dispose();
    zipCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final farmContact = widget.data.farmContact;
    final ownerMobile = farmContact?['owner_mobile'] as String? ?? '';
    final dashData = ref.watch(customerDashboardProvider).valueOrNull;
    final consumption = dashData?['consumption'] as Map<String, dynamic>?;
    final rows = customerConsumptionRowsFromJson(consumption);

    final subs = (widget.data.profile['active_subscriptions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final primarySub = subs.isNotEmpty ? subs.first : null;

    final shift = primarySub?['shift'] as String? ?? 'morning';
    final shiftLabel = shift.isEmpty
        ? 'Morning'
        : '${shift[0].toUpperCase()}${shift.substring(1)}';

    return Scaffold(
      backgroundColor: CusDashColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: CusProfileHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: CusDashMetrics.horizontalPad),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CusProfileUserCard(
                  initials: _initials,
                  fullName: _fullName,
                  mobile: _formatMobile(_mobile),
                  address: _deliveryAddress,
                  onEdit: _openEditSheet,
                ),
                const SizedBox(height: CusDashMetrics.sectionGap),
                if (primarySub != null) ...[
                  const CusProfileSectionLabel(title: 'SUBSCRIPTION'),
                  CusProfileSubscriptionCard(
                    productLabel: _subscriptionLabel(primarySub, rows),
                    shiftLabel: shiftLabel,
                    isMorning: shift == 'morning',
                    qtyPerDay: (primarySub['qty'] as num?)?.toDouble() ?? 1,
                    isActive: true,
                    onManage: () => _showManagePlanSheet(ownerMobile),
                  ),
                  const SizedBox(height: CusDashMetrics.sectionGap),
                ],
                const CusProfileSectionLabel(title: 'PREFERENCES'),
                CusProfileSettingsCard(
                  children: [
                    CusProfileToggleRow(
                      icon: LucideIcons.bell,
                      label: 'Delivery notifications',
                      value: _notificationsEnabled,
                      onChanged: _onNotificationsToggle,
                    ),
                    const CusProfileDivider(),
                    CusProfileToggleRow(
                      icon: LucideIcons.messageCircle,
                      label: 'WhatsApp updates',
                      value: _notificationsEnabled,
                      onChanged: _onNotificationsToggle,
                      isWhatsApp: true,
                    ),
                    const CusProfileDivider(),
                    CusProfileNavRow(
                      icon: LucideIcons.globe,
                      label: 'Language',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'English',
                            style: AppText.meta.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CusDashColors.inkMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, size: 18, color: CusDashColors.labelMuted),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: CusDashMetrics.sectionGap),
                const CusProfileSectionLabel(title: 'SUPPORT'),
                CusProfileSettingsCard(
                  children: [
                    CusProfileNavRow(
                      icon: LucideIcons.phone,
                      label: 'Call dairy',
                      onTap: ownerMobile.isNotEmpty ? () => _call(ownerMobile) : null,
                    ),
                    const CusProfileDivider(),
                    CusProfileNavRow(
                      icon: LucideIcons.helpCircle,
                      label: 'Help & FAQs',
                      onTap: _showFaqSheet,
                    ),
                  ],
                ),
                const SizedBox(height: CusDashMetrics.sectionGap),
                CusProfileLogoutButton(onTap: _logout),
                const SizedBox(height: 16),
                const CusProfileFooter(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings group (card with dividers) ───────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
        border: Border.all(color: CustomerDetailColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: CustomerDetailColors.border),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: CustomerDetailColors.onSurface),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: CustomerDetailColors.border),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CustomerDetailColors.accentLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: CustomerDetailColors.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15, color: CustomerDetailColors.onSurface)),
            ),
            if (trailing != null) trailing!,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: CustomerDetailColors.border),
          ],
        ),
      ),
    );
  }
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.addressCtrl,
    required this.areaCtrl,
    required this.landmarkCtrl,
    required this.zipCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.onSave,
  });

  final TextEditingController addressCtrl;
  final TextEditingController areaCtrl;
  final TextEditingController landmarkCtrl;
  final TextEditingController zipCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final Future<void> Function(Map<String, dynamic> fields) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _saving = false;
  String? _addressError;
  bool _lookingUpPincode = false;
  bool _pincodeError = false;
  late final Map<String, String> _original;

  @override
  void initState() {
    super.initState();
    _original = {
      'address_line': widget.addressCtrl.text,
      'area': widget.areaCtrl.text,
      'landmark': widget.landmarkCtrl.text,
      'zip': widget.zipCtrl.text,
      'city': widget.cityCtrl.text,
      'state': widget.stateCtrl.text,
    };
    widget.zipCtrl.addListener(_onZipChanged);
  }

  @override
  void dispose() {
    widget.zipCtrl.removeListener(_onZipChanged);
    super.dispose();
  }

  void _onZipChanged() {
    if (widget.zipCtrl.text.length == 6) _doLookupPincode(widget.zipCtrl.text);
  }

  Future<void> _doLookupPincode(String pincode) async {
    setState(() { _lookingUpPincode = true; _pincodeError = false; });
    try {
      final response = await _pincodeGet(pincode);
      if (mounted && response != null) {
        widget.cityCtrl.text = response['city'] as String? ?? '';
        widget.stateCtrl.text = response['state'] as String? ?? '';
        setState(() => _lookingUpPincode = false);
      }
    } catch (_) {
      if (mounted) setState(() { _lookingUpPincode = false; _pincodeError = true; });
    }
  }

  Future<Map<String, dynamic>?> _pincodeGet(String pincode) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final dio = container.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>('/pincode/$pincode');
      final body = response.data;
      if (body == null) return null;
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _changedFields() {
    final fields = <String, dynamic>{};
    void check(String key, TextEditingController ctrl) {
      final trimmed = ctrl.text.trim();
      if (trimmed != (_original[key] ?? '').trim()) fields[key] = trimmed;
    }
    check('address_line', widget.addressCtrl);
    check('area', widget.areaCtrl);
    check('landmark', widget.landmarkCtrl);
    check('zip', widget.zipCtrl);
    check('city', widget.cityCtrl);
    check('state', widget.stateCtrl);
    return fields;
  }

  Future<void> _submit() async {
    setState(() { _addressError = null; _saving = true; });
    final fields = _changedFields();
    if (fields.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      await widget.onSave(fields);
    } on ApiException catch (e) {
      if (mounted) {
        if (e.code == 'ADDRESS_RATE_LIMITED') {
          setState(() { _saving = false; _addressError = e.message; });
        } else {
          setState(() => _saving = false);
          AppSnackBar.showError(context, e.message);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.show(context, 'Failed to save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: CustomerDetailColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Edit Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CustomerDetailColors.onSurface)),
            const SizedBox(height: 20),
            _Field(label: 'Address', ctrl: widget.addressCtrl, enabled: !_saving),
            const SizedBox(height: 14),
            _Field(label: 'Area', ctrl: widget.areaCtrl, enabled: !_saving),
            const SizedBox(height: 14),
            _Field(label: 'Landmark (optional)', ctrl: widget.landmarkCtrl, enabled: !_saving),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: 'PIN code',
                    ctrl: widget.zipCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _Field(
                    label: 'City',
                    ctrl: widget.cityCtrl,
                    readOnly: _lookingUpPincode,
                    enabled: !_saving,
                    suffix: _lookingUpPincode
                        ? const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _Field(
                    label: 'State',
                    ctrl: widget.stateCtrl,
                    readOnly: _lookingUpPincode,
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            if (_pincodeError)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Pincode not found', style: TextStyle(fontSize: 12, color: CustomerDetailColors.danger)),
              ),
            if (_addressError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_addressError!, style: const TextStyle(fontSize: 12, color: CustomerDetailColors.danger)),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 13, color: CustomerDetailColors.onSurfaceVariant),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Address can only be updated once every 24 hours.',
                    style: TextStyle(fontSize: 12, color: CustomerDetailColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CustomerDetailColors.accent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (_saving || _lookingUpPincode) ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CustomerDetailColors.onSurface)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(fontSize: 13, color: CustomerDetailColors.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.enabled = true,
    this.suffix,
  });

  final String label;
  final TextEditingController ctrl;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CustomerDetailColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enabled: enabled,
          style: const TextStyle(fontSize: 14, color: CustomerDetailColors.onSurface),
          decoration: InputDecoration(
            suffix: suffix,
            filled: true,
            fillColor: CustomerDetailColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CustomerDetailColors.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
