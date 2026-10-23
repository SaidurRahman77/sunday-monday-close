import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_job_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/safe_text_input_dialog.dart';

class AdminJobManagementScreen
    extends StatefulWidget {
  const AdminJobManagementScreen({
    super.key,
  });

  @override
  State<AdminJobManagementScreen> createState() =>
      _AdminJobManagementScreenState();
}

class _AdminJobManagementScreenState
    extends State<AdminJobManagementScreen> {
  final AdminJobService _jobService =
      AdminJobService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';
  String _statusFilter = 'all';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> jobs,
  ) {
    final query =
        _query.trim().toLowerCase();

    return jobs.where(
      (job) {
        final title =
            job['title']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final category =
            job['category']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final clientEmail =
            job['clientEmail']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final location =
            job['location']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final status =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final matchesQuery =
            query.isEmpty ||
                title.contains(query) ||
                category.contains(query) ||
                clientEmail.contains(query) ||
                location.contains(query);

        final matchesStatus =
            _statusFilter == 'all' ||
                status == _statusFilter;

        return matchesQuery &&
            matchesStatus;
      },
    ).toList();
  }

  Future<void> _showDetails(
    Map<String, dynamic> job,
  ) async {
    final jobId =
        job['jobId']?.toString() ?? '';

    final title =
        job['title']?.toString() ??
            'Untitled job';

    final category =
        job['category']?.toString() ?? '';

    final description =
        job['description']?.toString() ?? '';

    final location =
        job['location']?.toString() ?? '';

    final clientEmail =
        job['clientEmail']?.toString() ?? '';

    final clientId =
        job['clientId']?.toString() ?? '';

    final assignedWorkerId =
        job['assignedWorkerId']
                ?.toString() ??
            '';

    final status =
        job['status']
                ?.toString()
                .toLowerCase() ??
            '';

    final budget =
        (job['budget'] as num?)
                ?.toDouble() ??
            0;

    final workDate =
        job['workDate'];

    String workDateText = 'Not set';

    if (workDate is Timestamp) {
      final value =
          workDate.toDate();

      workDateText =
          '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/'
          '${value.year}';
    }

    await showModalBottomSheet<void>(
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
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style:
                                  AppText.heading(
                                size: 19,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              category.isEmpty
                                  ? 'No category'
                                  : category,
                              style:
                                  AppText.body(
                                size: 10.5,
                                color:
                                    AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        status:
                            status,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  _DetailRow(
                    label: 'Job ID',
                    value: jobId,
                  ),
                  _DetailRow(
                    label: 'Client',
                    value: clientEmail.isEmpty
                        ? clientId
                        : clientEmail,
                  ),
                  _DetailRow(
                    label: 'Location',
                    value: location.isEmpty
                        ? 'Not set'
                        : location,
                  ),
                  _DetailRow(
                    label: 'Budget',
                    value:
                        budget <= 0
                            ? 'Not set'
                            : '৳${budget.toStringAsFixed(0)}',
                  ),
                  _DetailRow(
                    label: 'Work date',
                    value: workDateText,
                  ),
                  _DetailRow(
                    label: 'Start time',
                    value:
                        job['startTime']
                                ?.toString() ??
                            'Not set',
                  ),
                  _DetailRow(
                    label: 'Duration',
                    value:
                        '${(job['durationHours'] as num?)?.toInt() ?? 0} hour(s)',
                  ),
                  _DetailRow(
                    label: 'Assigned worker',
                    value:
                        assignedWorkerId.isEmpty
                            ? 'Not assigned'
                            : assignedWorkerId,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Description',
                    style:
                        AppText.label(
                      size: 8.5,
                      color:
                          AppColors.muted,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    description.isEmpty
                        ? 'No description'
                        : description,
                    style:
                        AppText.body(
                      size: 11.5,
                      color:
                          AppColors.ink,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _ActionArea(
                    status:
                        status,
                    busy:
                        _busy,
                    onClose: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _closeJob(
                        jobId:
                            jobId,
                        title:
                            title,
                      );
                    },
                    onCancel: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _cancelJob(
                        jobId:
                            jobId,
                        title:
                            title,
                      );
                    },
                    onRemove: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _removeJob(
                        jobId:
                            jobId,
                        title:
                            title,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _closeJob({
    required String jobId,
    required String title,
  }) async {
    final reason =
        await _reasonDialog(
      title:
          'Close this job?',
      description:
          'Closing stops this open posting from accepting new workers.',
      actionLabel:
          'Close job',
    );

    if (reason == null ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _jobService
          .closeJob(
        jobId:
            jobId,
        jobTitle:
            title,
        reason:
            reason,
      ),
      success:
          'Job closed.',
    );
  }

  Future<void> _cancelJob({
    required String jobId,
    required String title,
  }) async {
    final reason =
        await _reasonDialog(
      title:
          'Cancel this job?',
      description:
          'Use this for moderation or when an active job must be stopped.',
      actionLabel:
          'Cancel job',
      destructive: true,
    );

    if (reason == null ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _jobService
          .cancelJob(
        jobId:
            jobId,
        jobTitle:
            title,
        reason:
            reason,
      ),
      success:
          'Job cancelled.',
    );
  }

  Future<void> _removeJob({
    required String jobId,
    required String title,
  }) async {
    final reason =
        await _reasonDialog(
      title:
          'Remove job permanently?',
      description:
          'This deletes the job document. Use it only for spam, abuse, or invalid content. Related historical records may still contain the job ID.',
      actionLabel:
          'Remove job',
      destructive: true,
    );

    if (reason == null ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _jobService
          .removeJob(
        jobId:
            jobId,
        jobTitle:
            title,
        reason:
            reason,
      ),
      success:
          'Job removed.',
    );
  }

  Future<String?> _reasonDialog({
    required String title,
    required String description,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showSafeTextInputDialog(
      context,
      title: title,
      description: description,
      fieldLabel: 'Reason (optional)',
      actionLabel: actionLabel,
      destructive: destructive,
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(
        success,
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
            Text(
          message,
        ),
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
                    _jobService
                        .watchJobs(),
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

                  final jobs =
                      snapshot.data ??
                          [];

                  final filtered =
                      _filtered(
                    jobs,
                  );

                  return ListView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      20,
                      20,
                      40,
                    ),
                    children: [
                      _SearchBox(
                        controller:
                            _searchController,
                        onChanged:
                            (value) {
                          setState(() {
                            _query =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _StatusFilters(
                        selected:
                            _statusFilter,
                        onChanged:
                            (value) {
                          setState(() {
                            _statusFilter =
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
                              'Jobs',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${filtered.length} found',
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
                      if (filtered.isEmpty)
                        const _EmptyState()
                      else
                        ...filtered.map(
                          (job) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom:
                                  10,
                            ),
                            child:
                                _JobTile(
                              job:
                                  job,
                              onTap:
                                  () {
                                _showDetails(
                                  job,
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
              LucideIcons
                  .arrowLeft,
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
                  'JOB MANAGEMENT',
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
                  'Platform jobs',
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

class _SearchBox
    extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      style:
          AppText.body(
        size: 13,
        color:
            AppColors.ink,
      ),
      cursorColor:
          AppColors.ink,
      onChanged:
          onChanged,
      decoration:
          InputDecoration(
        hintText:
            'Search title, category, client or location',
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
    );
  }
}

class _StatusFilters
    extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    final items = [
      ('all', 'All'),
      ('open', 'Open'),
      ('assigned', 'Assigned'),
      ('in_progress', 'In progress'),
      ('completed', 'Completed'),
      ('closed', 'Closed'),
      ('cancelled', 'Cancelled'),
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
            onSelected: (_) =>
                onChanged(
              item.$1,
            ),
          );
        },
      ),
    );
  }
}

class _JobTile
    extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.onTap,
  });

  final Map<String, dynamic> job;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        job['title']
                ?.toString() ??
            'Untitled job';

    final category =
        job['category']
                ?.toString() ??
            '';

    final status =
        job['status']
                ?.toString()
                .toLowerCase() ??
            '';

    final budget =
        (job['budget'] as num?)
                ?.toDouble() ??
            0;

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
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons
                      .briefcaseBusiness,
                  size: 18,
                  color:
                      AppColors.ink,
                ),
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
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      [
                        if (category
                            .isNotEmpty)
                          category,
                        if (budget > 0)
                          '৳${budget.toStringAsFixed(0)}',
                      ].join(
                        ' • ',
                      ),
                      style:
                          AppText.body(
                        size: 9.5,
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
              _StatusBadge(
                status:
                    status,
              ),
              const SizedBox(
                width: 4,
              ),
              const Icon(
                LucideIcons
                    .chevronRight,
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

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(
    BuildContext context,
  ) {
    final label =
        switch (status) {
      'in_progress' =>
        'IN PROGRESS',
      'assigned' =>
        'ASSIGNED',
      'completed' =>
        'COMPLETED',
      'closed' =>
        'CLOSED',
      'cancelled' =>
        'CANCELLED',
      _ => 'OPEN',
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            status == 'open'
                ? AppColors.goldSoft
                : AppColors.background,
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
      child: Text(
        label,
        style:
            AppText.label(
          size: 7,
          color:
              status == 'open'
                  ? AppColors.ink
                  : AppColors.muted,
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
            width: 110,
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
            child: Text(
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

class _ActionArea
    extends StatelessWidget {
  const _ActionArea({
    required this.status,
    required this.busy,
    required this.onClose,
    required this.onCancel,
    required this.onRemove,
  });

  final String status;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        if (status == 'open')
          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  busy
                      ? null
                      : onClose,
              icon:
                  const Icon(
                LucideIcons
                    .circleStop,
                size: 17,
              ),
              label:
                  const Text(
                'Close job',
              ),
            ),
          ),
        if (status != 'completed' &&
            status != 'cancelled')
          Padding(
            padding:
                const EdgeInsets.only(
              top: 8,
            ),
            child:
                SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    busy
                        ? null
                        : onCancel,
                icon:
                    const Icon(
                  LucideIcons.ban,
                  size: 17,
                ),
                label:
                    const Text(
                  'Cancel job',
                ),
              ),
            ),
          ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width:
              double.infinity,
          child:
              OutlinedButton.icon(
            onPressed:
                busy
                    ? null
                    : onRemove,
            icon:
                const Icon(
              LucideIcons.trash2,
              size: 17,
            ),
            label:
                const Text(
              'Remove job',
            ),
          ),
        ),
      ],
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
            LucideIcons
                .briefcaseBusiness,
            color:
                AppColors.muted,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No jobs found',
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
