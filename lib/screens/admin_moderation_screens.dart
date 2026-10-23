import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_moderation_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/safe_text_input_dialog.dart';

class AdminReviewManagementScreen
    extends StatefulWidget {
  const AdminReviewManagementScreen({
    super.key,
  });

  @override
  State<AdminReviewManagementScreen> createState() =>
      _AdminReviewManagementScreenState();
}

class _AdminReviewManagementScreenState
    extends State<AdminReviewManagementScreen> {
  final AdminModerationService _service =
      AdminModerationService();

  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';
  String _filter = 'all';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> reviews,
  ) {
    final query =
        _query.trim().toLowerCase();

    return reviews.where((review) {
      final comment =
          review['comment']?.toString().toLowerCase() ?? '';

      final clientId =
          review['clientId']?.toString().toLowerCase() ?? '';

      final workerId =
          review['workerId']?.toString().toLowerCase() ?? '';

      final jobId =
          review['jobId']?.toString().toLowerCase() ?? '';

      final hidden =
          review['isHidden'] == true;

      final matchesQuery =
          query.isEmpty ||
              comment.contains(query) ||
              clientId.contains(query) ||
              workerId.contains(query) ||
              jobId.contains(query);

      final matchesFilter =
          _filter == 'all' ||
              (_filter == 'visible' && !hidden) ||
              (_filter == 'hidden' && hidden);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _toggleHidden(
    Map<String, dynamic> review,
  ) async {
    final reviewId =
        review['reviewId']?.toString() ?? '';

    final hidden =
        review['isHidden'] == true;

    if (reviewId.isEmpty || _busy) {
      return;
    }

    String reason = '';

    if (!hidden) {
      final result =
          await showSafeTextInputDialog(
        context,
        title: 'Hide review?',
        description:
            'The review will be marked hidden by moderation.',
        fieldLabel: 'Reason (optional)',
        actionLabel: 'Hide review',
      );

      if (result == null ||
          !mounted) {
        return;
      }

      reason = result;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _service.setReviewHidden(
        reviewId:
            reviewId,
        hidden:
            !hidden,
        reason:
            reason,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        hidden
            ? 'Review restored.'
            : 'Review hidden.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
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
              title:
                  'Review moderation',
              label:
                  'REVIEWS',
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
                        .watchReviews(),
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

                  final reviews =
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
                              'Search comment, user ID or job ID',
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
                          filled: true,
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
                      SizedBox(
                        height: 38,
                        child:
                            ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            _FilterChip(
                              label:
                                  'All',
                              selected:
                                  _filter ==
                                      'all',
                              onTap: () {
                                setState(() {
                                  _filter =
                                      'all';
                                });
                              },
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            _FilterChip(
                              label:
                                  'Visible',
                              selected:
                                  _filter ==
                                      'visible',
                              onTap: () {
                                setState(() {
                                  _filter =
                                      'visible';
                                });
                              },
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            _FilterChip(
                              label:
                                  'Hidden',
                              selected:
                                  _filter ==
                                      'hidden',
                              onTap: () {
                                setState(() {
                                  _filter =
                                      'hidden';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        '${reviews.length} review(s)',
                        style:
                            AppText.heading(
                          size: 17,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (reviews.isEmpty)
                        const _EmptyCard(
                          icon:
                              LucideIcons.star,
                          title:
                              'No reviews found',
                        )
                      else
                        ...reviews.map(
                          (review) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                                _ReviewCard(
                              review:
                                  review,
                              busy:
                                  _busy,
                              onToggle:
                                  () {
                                _toggleHidden(
                                  review,
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

class AdminReportsScreen
    extends StatefulWidget {
  const AdminReportsScreen({
    super.key,
  });

  @override
  State<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState
    extends State<AdminReportsScreen> {
  final AdminModerationService _service =
      AdminModerationService();

  String _filter = 'all';
  bool _busy = false;

  Future<void> _changeStatus(
    Map<String, dynamic> report,
    String status,
  ) async {
    final reportId =
        report['reportId']?.toString() ?? '';

    if (reportId.isEmpty ||
        _busy) {
      return;
    }

    final note =
        await showSafeTextInputDialog(
      context,
      title: 'Update report',
      description:
          'Add an optional note for this moderation update.',
      fieldLabel: 'Admin note (optional)',
      actionLabel: 'Save',
      initialValue:
          report['adminNote']
                  ?.toString() ??
              '',
    );

    if (note == null ||
        !mounted) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _service.setReportStatus(
        reportId:
            reportId,
        status:
            status,
        adminNote:
            note,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            'Report marked $status.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
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
              title:
                  'Reports & complaints',
              label:
                  'REPORTS',
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
                        .watchReports(),
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

                  final all =
                      snapshot.data ??
                          [];

                  final reports =
                      _filter ==
                              'all'
                          ? all
                          : all.where(
                              (item) =>
                                  (item['status']
                                              ?.toString()
                                              .toLowerCase() ??
                                          'pending') ==
                                      _filter,
                            ).toList();

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      40,
                    ),
                    children: [
                      SizedBox(
                        height: 38,
                        child:
                            ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            for (final item
                                in const [
                              ('all', 'All'),
                              ('pending', 'Pending'),
                              ('reviewing', 'Reviewing'),
                              ('resolved', 'Resolved'),
                            ]) ...[
                              _FilterChip(
                                label:
                                    item.$2,
                                selected:
                                    _filter ==
                                        item.$1,
                                onTap: () {
                                  setState(() {
                                    _filter =
                                        item.$1;
                                  });
                                },
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        '${reports.length} report(s)',
                        style:
                            AppText.heading(
                          size: 17,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (reports.isEmpty)
                        const _EmptyCard(
                          icon:
                              LucideIcons
                                  .messageSquareWarning,
                          title:
                              'No reports found',
                        )
                      else
                        ...reports.map(
                          (report) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                                _ReportCard(
                              report:
                                  report,
                              busy:
                                  _busy,
                              onStatus:
                                  (status) {
                                _changeStatus(
                                  report,
                                  status,
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
    required this.title,
    required this.label,
    required this.onBack,
  });

  final String title;
  final String label;
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
                  label,
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
                  title,
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

class _FilterChip
    extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ChoiceChip(
      label:
          Text(label),
      selected:
          selected,
      onSelected: (_) =>
          onTap(),
    );
  }
}

class _ReviewCard
    extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.busy,
    required this.onToggle,
  });

  final Map<String, dynamic> review;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(
    BuildContext context,
  ) {
    final stars =
        (review['stars'] as num?)
                ?.toInt() ??
            0;

    final comment =
        review['comment']?.toString().trim() ?? '';

    final hidden =
        review['isHidden'] == true;

    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$stars / 5 stars',
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),
              ),
              Text(
                hidden
                    ? 'HIDDEN'
                    : 'VISIBLE',
                style:
                    AppText.label(
                  size: 7.5,
                  color:
                      hidden
                          ? AppColors.muted
                          : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            comment.isEmpty
                ? 'No written comment.'
                : comment,
            style:
                AppText.body(
              size: 11,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Worker: ${review['workerId'] ?? '-'}',
            style:
                AppText.body(
              size: 9,
              color:
                  AppColors.muted,
            ),
          ),
          Text(
            'Client: ${review['clientId'] ?? '-'}',
            style:
                AppText.body(
              size: 9,
              color:
                  AppColors.muted,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  busy
                      ? null
                      : onToggle,
              icon:
                  Icon(
                hidden
                    ? LucideIcons.eye
                    : LucideIcons.eyeOff,
                size: 16,
              ),
              label:
                  Text(
                hidden
                    ? 'Restore review'
                    : 'Hide review',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard
    extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.busy,
    required this.onStatus,
  });

  final Map<String, dynamic> report;
  final bool busy;
  final ValueChanged<String> onStatus;

  @override
  Widget build(
    BuildContext context,
  ) {
    final status =
        report['status']
                ?.toString()
                .toLowerCase() ??
            'pending';

    final reason =
        report['reason']?.toString().trim() ??
            report['message']?.toString().trim() ??
            'No report details provided.';

    return Container(
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report['type']
                          ?.toString() ??
                      'Report',
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),
              ),
              Text(
                status.toUpperCase(),
                style:
                    AppText.label(
                  size: 7.5,
                  color:
                      AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            reason,
            style:
                AppText.body(
              size: 11,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Reporter: ${report['reporterId'] ?? '-'}',
            style:
                AppText.body(
              size: 9,
              color:
                  AppColors.muted,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed:
                    busy
                        ? null
                        : () => onStatus(
                              'pending',
                            ),
                child:
                    const Text(
                  'Pending',
                ),
              ),
              OutlinedButton(
                onPressed:
                    busy
                        ? null
                        : () => onStatus(
                              'reviewing',
                            ),
                child:
                    const Text(
                  'Reviewing',
                ),
              ),
              ElevatedButton(
                onPressed:
                    busy
                        ? null
                        : () => onStatus(
                              'resolved',
                            ),
                child:
                    const Text(
                  'Resolved',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard
    extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

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
          Icon(
            icon,
            color:
                AppColors.muted,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
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
