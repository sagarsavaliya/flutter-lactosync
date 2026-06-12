import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/repositories/customer_billing_repository.dart';
import '../providers/customer_billing_provider.dart';

// ── Bills List Page ──────────────────────────────────────────────────────────

class CustomerBillsPage extends ConsumerWidget {
  const CustomerBillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(customerBillsProvider);

    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(customerBillsProvider),
      ),
      data: (bills) {
        if (bills.isEmpty) {
          return const _EmptyState();
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(customerBillsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpace.lg),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _BillCard(bill: bill),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Bill Card ────────────────────────────────────────────────────────────────

class _BillCard extends ConsumerStatefulWidget {
  const _BillCard({required this.bill});

  final CustomerBill bill;

  @override
  ConsumerState<_BillCard> createState() => _BillCardState();
}

class _BillCardState extends ConsumerState<_BillCard> {
  bool _loading = false;

  String _formatMonth(String billingMonth) {
    try {
      // billingMonth is "YYYY-MM" — append "-01" to parse it.
      final dt = DateTime.parse('$billingMonth-01');
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return billingMonth;
    }
  }

  String _formatAmount(double amount) {
    final fmt = NumberFormat('#,##,##0.##', 'en_IN');
    return '₹${fmt.format(amount)}';
  }

  Future<void> _openImageViewer() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(customerBillingRepositoryProvider);
      final url = await repo.fetchBillImageUrl(widget.bill.id);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _BillImageViewerPage(
            url: url,
            billingMonth: _formatMonth(widget.bill.billingMonth),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // Image not available — navigate to viewer in error state.
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _BillImageViewerPage(
            url: null,
            billingMonth: _formatMonth(widget.bill.billingMonth),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final formattedMonth = _formatMonth(bill.billingMonth);

    return AppCard(
      onTap: _loading ? null : _openImageViewer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: month + status badge ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _loading
                    ? Row(
                        children: [
                          Text(formattedMonth, style: AppText.cardTitle),
                          const SizedBox(width: AppSpace.sm),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      )
                    : Text(formattedMonth, style: AppText.cardTitle),
              ),
              _StatusBadge(status: bill.status),
            ],
          ),
          const SizedBox(height: AppSpace.xs),

          // ── Total row ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Total',
                  style: AppText.meta.copyWith(color: AppColors.inkMuted),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(bill.totalAmount),
                  style: AppText.body,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xxs),

          // ── Due row ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Due',
                  style: AppText.meta.copyWith(color: AppColors.inkMuted),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(bill.balanceDue),
                  style: AppText.body.copyWith(
                    color: bill.balanceDue > 0
                        ? AppColors.danger
                        : AppColors.ink,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color badgeBg;
    final Color badgeFg;
    final String label;

    switch (status.toLowerCase()) {
      case 'paid':
        label = 'Paid';
        badgeBg = AppColors.successFaint;
        badgeFg = AppColors.success;
      case 'partial':
        label = 'Partial';
        badgeBg = AppColors.warningFaint;
        badgeFg = AppColors.warning;
      default:
        label = 'Unpaid';
        badgeBg = AppColors.dangerFaint;
        badgeFg = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(color: badgeFg),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.inkFaint,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'No bills yet',
            style: AppText.body.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Bill Image Viewer Page ────────────────────────────────────────────────────

class _BillImageViewerPage extends StatefulWidget {
  const _BillImageViewerPage({
    required this.url,
    required this.billingMonth,
  });

  /// The signed URL for the bill PNG. Null means image is not available.
  final String? url;
  final String billingMonth;

  @override
  State<_BillImageViewerPage> createState() => _BillImageViewerPageState();
}

class _BillImageViewerPageState extends State<_BillImageViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill — ${widget.billingMonth}'),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: widget.url == null
          ? _buildNotAvailable()
          : _buildImageBody(widget.url!),
    );
  }

  Widget _buildImageBody(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildNotAvailable();
          },
        ),
      ),
    );
  }

  Widget _buildNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: AppColors.inkFaint,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Bill image not available',
            style: AppText.body.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
