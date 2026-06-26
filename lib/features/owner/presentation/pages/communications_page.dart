import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_screen_widgets.dart';

class CommunicationsPage extends ConsumerStatefulWidget {
  const CommunicationsPage({super.key});

  @override
  ConsumerState<CommunicationsPage> createState() => _CommunicationsPageState();
}

class _CommunicationsPageState extends ConsumerState<CommunicationsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  String _status = '';
  CommunicationSort _sort = CommunicationSort.newest;

  static const _statusFilters = <String, String>{
    '': AppStrings.communicationsStatusAll,
    'sent': AppStrings.communicationsStatusSent,
    'delivered': AppStrings.communicationsStatusDelivered,
    'read': AppStrings.communicationsStatusRead,
    'failed': AppStrings.communicationsStatusFailed,
    'simulated': AppStrings.communicationsStatusSimulated,
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  CommunicationsQuery get _query => CommunicationsQuery(search: _search, status: _status);

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  List<CommunicationMessage> _sortMessages(List<CommunicationMessage> items) {
    final list = List<CommunicationMessage>.from(items);
    list.sort((a, b) {
      final nameCmp = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      final aTime = DateTime.tryParse(a.primaryTimestamp ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b.primaryTimestamp ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return switch (_sort) {
        CommunicationSort.oldest => aTime.compareTo(bTime),
        CommunicationSort.customerAsc => nameCmp,
        CommunicationSort.customerDesc => -nameCmp,
        CommunicationSort.newest => bTime.compareTo(aTime),
      };
    });
    return list;
  }

  void _showSortMenu() {
    showOwnerBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OwnerSheetTitle(AppStrings.sortLabel),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.communicationsSortNewest, style: AppText.body),
            onTap: () {
              setState(() => _sort = CommunicationSort.newest);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.communicationsSortOldest, style: AppText.body),
            onTap: () {
              setState(() => _sort = CommunicationSort.oldest);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameAsc, style: AppText.body),
            onTap: () {
              setState(() => _sort = CommunicationSort.customerAsc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameDesc, style: AppText.body),
            onTap: () {
              setState(() => _sort = CommunicationSort.customerDesc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg, IconData icon}) _statusStyle(String status) {
    return switch (status) {
      'delivered' => (
          bg: CustomerDetailColors.successBg,
          fg: CustomerDetailColors.success,
          icon: LucideIcons.checkCheck,
        ),
      'read' => (
          bg: const Color(0xFFE0F2F1),
          fg: const Color(0xFF00695C),
          icon: LucideIcons.eye,
        ),
      'failed' => (
          bg: CustomerDetailColors.dangerBg,
          fg: CustomerDetailColors.danger,
          icon: LucideIcons.alertCircle,
        ),
      'simulated' => (
          bg: const Color(0xFFF3F4F6),
          fg: const Color(0xFF6B7280),
          icon: LucideIcons.flaskConical,
        ),
      'sent' => (
          bg: const Color(0xFFE8F4FD),
          fg: const Color(0xFF1A73E8),
          icon: LucideIcons.send,
        ),
      _ => (
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFFE65100),
          icon: LucideIcons.clock3,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(communicationsProvider(_query));
    final inkMuted = CustomerDetailColors.labelMuted;

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: AppBar(
        backgroundColor: CustomerDetailColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomerDetailColors.accent),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.communicationsTitle,
          style: AppText.screenTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CustomerDetailColors.accent,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OwnerSearchSortRow(
              controller: _searchController,
              hintText: AppStrings.communicationsSearchHint,
              onChanged: _onSearchChanged,
              onSort: _showSortMenu,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusFilters.entries.map((entry) {
                final selected = _status == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: AppText.meta.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : CustomerDetailColors.bodyInk,
                    ),
                    selectedColor: CustomerDetailColors.accent,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? CustomerDetailColors.accent : CustomerDetailColors.border,
                    ),
                    onSelected: (_) => setState(() => _status = entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: CustomerDetailColors.accent),
              ),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(communicationsProvider(_query)),
                  child: const Text('Retry'),
                ),
              ),
              data: (items) {
                final messages = _sortMessages(items);
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.communicationsEmpty,
                      style: AppText.body.copyWith(color: inkMuted),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: CustomerDetailColors.accent,
                  onRefresh: () async {
                    ref.invalidate(communicationsProvider(_query));
                    await ref.read(communicationsProvider(_query).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final style = _statusStyle(message.status);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: message.customerId == null
                                ? null
                                : () => context.push('/owner/customers/${message.customerId}'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: ownerWhiteCardDecoration(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: style.bg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(style.icon, size: 18, color: style.fg),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                message.displayName,
                                                style: AppText.cardTitle.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: CustomerDetailColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: style.bg,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                message.statusLabel,
                                                style: AppText.meta.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: style.fg,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message.headline,
                                          style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          message.typeLabel,
                                          style: AppText.meta.copyWith(color: inkMuted),
                                        ),
                                        if (message.failureReason != null &&
                                            message.failureReason!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            message.failureReason!,
                                            style: AppText.meta.copyWith(color: CustomerDetailColors.danger),
                                          ),
                                        ],
                                        if (message.primaryTimestamp != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatTime(message.primaryTimestamp),
                                            style: AppText.meta.copyWith(color: inkMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
