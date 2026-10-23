import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_audit_log_service.dart';
import '../widgets/premium_ui.dart';

class AdminAuditLogsScreen
    extends StatefulWidget {
  const AdminAuditLogsScreen({
    super.key,
  });

  @override
  State<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState
    extends State<AdminAuditLogsScreen> {
  final AdminAuditLogService _service =
      AdminAuditLogService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';
  String _targetFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> logs,
  ) {
    final query =
        _query.trim().toLowerCase();

    return logs.where((log) {
      final action =
          log['action']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final adminEmail =
          log['adminEmail']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final adminId =
          log['adminId']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final targetType =
          log['targetType']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final targetId =
          log['targetId']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final details =
          log['details']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final matchesQuery =
          query.isEmpty ||
              action.contains(query) ||
              adminEmail.contains(query) ||
              adminId.contains(query) ||
              targetType.contains(query) ||
              targetId.contains(query) ||
              details.contains(query);

      final matchesFilter =
          _targetFilter == 'all' ||
              targetType ==
                  _targetFilter;

      return matchesQuery &&
          matchesFilter;
    }).toList();
  }

  String _prettyAction(
    String raw,
  ) {
    if (raw.trim().isEmpty) {
      return 'Admin action';
    }

    return raw
        .split('_')
        .where(
          (part) =>
              part.isNotEmpty,
        )
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatTimestamp(
    dynamic value,
  ) {
    if (value is! Timestamp) {
      return 'Time unavailable';
    }

    final date =
        value.toDate();

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hour12 =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$day/$month/${date.year} • '
        '$hour12:$minute $period';
  }

  void _showDetails(
    Map<String, dynamic> log,
  ) {
    final action =
        _prettyAction(
      log['action']
              ?.toString() ??
          '',
    );

    final detailsRaw =
        log['details'];

    final details =
        detailsRaw is Map
            ? Map<String, dynamic>.from(
                detailsRaw,
              )
            : <String, dynamic>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        sheetContext,
      ) {
        return Container(
          margin:
              const EdgeInsets.all(
            12,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            24,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              28,
            ),
          ),
          child: SafeArea(
            top: false,
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.line,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    action,
                    style:
                        AppText.heading(
                      size: 19,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _formatTimestamp(
                      log['createdAt'],
                    ),
                    style:
                        AppText.body(
                      size: 10,
                      color:
                          AppColors.muted,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _DetailRow(
                    label:
                        'Admin',
                    value:
                        log['adminEmail']
                                ?.toString() ??
                            log['adminId']
                                ?.toString() ??
                            'Unknown',
                  ),
                  _DetailRow(
                    label:
                        'Target type',
                    value:
                        log['targetType']
                                ?.toString() ??
                            '-',
                  ),
                  _DetailRow(
                    label:
                        'Target ID',
                    value:
                        log['targetId']
                                ?.toString() ??
                            '-',
                  ),
                  _DetailRow(
                    label:
                        'Log ID',
                    value:
                        log['logId']
                                ?.toString() ??
                            '-',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Details',
                    style:
                        AppText.heading(
                      size: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (details.isEmpty)
                    Text(
                      'No additional details.',
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors.muted,
                      ),
                    )
                  else
                    ...details.entries.map(
                      (entry) =>
                          _DetailRow(
                        label:
                            _prettyLabel(
                          entry.key,
                        ),
                        value:
                            entry.value
                                    ?.toString() ??
                                '-',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _prettyLabel(
    String raw,
  ) {
    if (raw.isEmpty) {
      return '-';
    }

    final spaced =
        raw.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) =>
          ' ${match.group(1)}',
    );

    return spaced
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where(
          (part) =>
              part.isNotEmpty,
        )
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () =>
                  Navigator.pop(
                context,
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _service
                        .watchAuditLogs(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                              .connectionState ==
                          ConnectionState
                              .waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child:
                          Text(
                        snapshot.error
                            .toString(),
                      ),
                    );
                  }

                  final logs =
                      _filtered(
                    snapshot.data ??
                        [],
                  );

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      40,
                    ),
                    children: [
                      TextField(
                        controller:
                            _searchController,
                        style:
                            AppText.body(
                          size: 13,
                          color:
                              AppColors.ink,
                        ),
                        cursorColor:
                            AppColors.ink,
                        onChanged:
                            (value) {
                          setState(() {
                            _query =
                                value;
                          });
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              'Search action, admin, target or details',
                          hintStyle:
                              AppText.body(
                            size: 11.5,
                            color:
                                AppColors.muted,
                          ),
                          prefixIcon:
                              const Icon(
                            LucideIcons.search,
                            size: 18,
                          ),
                          filled:
                              true,
                          fillColor:
                              AppColors.surface,
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors.line,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors.line,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      _TargetFilters(
                        selected:
                            _targetFilter,
                        onChanged:
                            (value) {
                          setState(() {
                            _targetFilter =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Audit history',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${logs.length} log(s)',
                            style:
                                AppText.body(
                              size: 10,
                              color:
                                  AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (logs.isEmpty)
                        const _EmptyState()
                      else
                        ...logs.map(
                          (log) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                                _AuditLogTile(
                              action:
                                  _prettyAction(
                                log['action']
                                        ?.toString() ??
                                    '',
                              ),
                              targetType:
                                  log['targetType']
                                          ?.toString() ??
                                      'unknown',
                              admin:
                                  log['adminEmail']
                                          ?.toString() ??
                                      'Admin',
                              time:
                                  _formatTimestamp(
                                log['createdAt'],
                              ),
                              onTap:
                                  () {
                                _showDetails(
                                  log,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header
    extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        0,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          25,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                onBack,
            icon:
                const Icon(
              LucideIcons.arrowLeft,
              color:
                  Colors.white,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AUDIT LOGS',
                  style:
                      AppText.label(
                    size: 8,
                    color:
                        AppColors.gold,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Admin activity history',
                  style:
                      AppText.heading(
                    size: 18,
                    color:
                        Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetFilters
    extends StatelessWidget {
  const _TargetFilters({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String>
      onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    final items = [
      ('all', 'All'),
      ('user', 'Users'),
      ('job', 'Jobs'),
      ('category', 'Categories'),
      ('review', 'Reviews'),
      ('report', 'Reports'),
      (
        'platform_settings',
        'Settings',
      ),
    ];

    return SizedBox(
      height: 38,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            items.length,
        separatorBuilder:
            (
          context,
          index,
        ) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final item =
              items[index];

          return ChoiceChip(
            label:
                Text(
              item.$2,
            ),
            selected:
                selected ==
                    item.$1,
            onSelected:
                (_) =>
                    onChanged(
              item.$1,
            ),
          );
        },
      ),
    );
  }
}

class _AuditLogTile
    extends StatelessWidget {
  const _AuditLogTile({
    required this.action,
    required this.targetType,
    required this.admin,
    required this.time,
    required this.onTap,
  });

  final String action;
  final String targetType;
  final String admin;
  final String time;
  final VoidCallback onTap;

  IconData get _icon {
    switch (targetType) {
      case 'user':
        return LucideIcons.userRound;
      case 'job':
        return LucideIcons.briefcaseBusiness;
      case 'category':
        return LucideIcons.layoutGrid;
      case 'review':
        return LucideIcons.star;
      case 'report':
        return LucideIcons.messageSquareWarning;
      case 'platform_settings':
        return LucideIcons.settings2;
      default:
        return LucideIcons.scrollText;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            15,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Row(
            children: [
              PremiumIconBox(
                icon:
                    _icon,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      action,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppText.heading(
                        size: 13.5,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '$admin • $time',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppText.body(
                        size: 9,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 17,
                color:
                    AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style:
                  AppText.body(
                size: 10,
                color:
                    AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style:
                  AppText.body(
                size: 10.5,
                color:
                    AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.scrollText,
            color:
                AppColors.muted,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No audit logs found',
            style:
                AppText.heading(
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
