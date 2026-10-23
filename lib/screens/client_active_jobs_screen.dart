import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_service.dart';
import '../utils/app_error.dart';
import '../widgets/premium_ui.dart';

class ClientActiveJobsScreen extends StatelessWidget {
  const ClientActiveJobsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final jobService =
        JobService();

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),

            Expanded(
              child: StreamBuilder<
                  List<Map<String, dynamic>>>(
                stream:
                    jobService.getClientActiveJobs(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
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
                    debugPrint(
                      'CLIENT ACTIVE JOBS STREAM ERROR: ${snapshot.error}',
                    );

                    return const _ErrorState(
                      message:
                          'Please try again in a moment.',
                    );
                  }

                  final jobs =
                      snapshot.data ?? [];

                  if (jobs.isEmpty) {
                    return const _EmptyState();
                  }

                  final assignedCount =
                      jobs
                          .where(
                            (job) =>
                                job['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'assigned',
                          )
                          .length;

                  final inProgressCount =
                      jobs
                          .where(
                            (job) =>
                                job['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'in_progress',
                          )
                          .length;

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      40,
                    ),
                    children: [
                      _OverviewCard(
                        total:
                            jobs.length,
                        assigned:
                            assignedCount,
                        inProgress:
                            inProgressCount,
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Active jobs',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${jobs.length} active',
                            style:
                                AppText.body(
                              size: 11,
                              color:
                                  AppColors.muted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      ...jobs.map(
                        (job) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _ClientActiveJobCard(
                            job:
                                job,
                            jobService:
                                jobService,
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
  const _Header();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        16,
        20,
        18,
      ),
      decoration:
          const BoxDecoration(
        border:
            Border(
          bottom:
              BorderSide(
            color:
                AppColors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color:
                AppColors.ink,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(
                  context,
                );
              },
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child:
                  const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Ongoing work',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Track assigned and active jobs',
                  style:
                      AppText.body(
                    size: 11,
                    color:
                        AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 40,
            height: 40,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child:
                const Icon(
              LucideIcons.clock3,
              size: 18,
              color:
                  AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard
    extends StatelessWidget {
  const _OverviewCard({
    required this.total,
    required this.assigned,
    required this.inProgress,
  });

  final int total;
  final int assigned;
  final int inProgress;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        19,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.ink,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE WORK OVERVIEW',
            style:
                AppText.label(
              size: 8.5,
              color:
                  Colors.white60,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            '$total active ${total == 1 ? 'job' : 'jobs'}',
            style:
                AppText.heading(
              size: 21,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            height: 19,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _OverviewItem(
                  label:
                      'Assigned',
                  value:
                      assigned,
                  icon:
                      LucideIcons.userCheck,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _OverviewItem(
                  label:
                      'In progress',
                  value:
                      inProgress,
                  icon:
                      LucideIcons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem
    extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                AppColors.gold,
          ),

          const SizedBox(
            width: 9,
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style:
                    AppText.heading(
                  size: 18,
                  color:
                      Colors.white,
                ),
              ),
              Text(
                label,
                style:
                    AppText.body(
                  size: 8.5,
                  color:
                      Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientActiveJobCard
    extends StatefulWidget {
  const _ClientActiveJobCard({
    required this.job,
    required this.jobService,
  });

  final Map<String, dynamic>
      job;

  final JobService
      jobService;

  @override
  State<_ClientActiveJobCard>
      createState() =>
          _ClientActiveJobCardState();
}

class _ClientActiveJobCardState
    extends State<_ClientActiveJobCard> {
  bool _busy = false;

  Future<void> _completeWork() async {
    final jobId =
        widget.job['jobId']
                ?.toString() ??
            '';

    if (jobId.isEmpty ||
        _busy) {
      return;
    }

    final confirmed =
        await _confirmComplete(
      context,
    );

    if (!confirmed ||
        !mounted) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await widget.jobService
          .completeWork(
        jobId:
            jobId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Work marked as completed.',
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
          content: Text(
            AppError.message(
              e,
              fallback:
                  'Unable to complete this job. Please try again.',
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
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
    final job =
        widget.job;

    final title =
        job['title']
                ?.toString() ??
            'Untitled job';

    final category =
        job['category']
                ?.toString() ??
            'Job';

    final location =
        job['location']
                ?.toString() ??
            'Location not set';

    final status =
        job['status']
                ?.toString()
                .toLowerCase() ??
            'assigned';

    final workerId =
        job['assignedWorkerId']
                ?.toString() ??
            '';

    final budget =
        (job['budget']
                    as num?)
                ?.toDouble() ??
            0;

    final duration =
        (job['durationHours']
                    as num?)
                ?.toInt() ??
            0;

    final startTime =
        job['startTime']
                ?.toString() ??
            '';

    final rawDate =
        job['workDate'];

    final date =
        rawDate is Timestamp
            ? _formatDate(
                rawDate.toDate(),
              )
            : 'Date not set';

    final inProgress =
        status ==
            'in_progress';

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          24,
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons.briefcase,
                  size: 19,
                  color:
                      AppColors.ink,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      category
                          .toUpperCase(),
                      style:
                          AppText.label(
                        size: 8.5,
                        color:
                            AppColors.gold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          AppText.heading(
                        size: 16,
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
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          _InfoRow(
            icon:
                LucideIcons.mapPin,
            text:
                location,
          ),

          const SizedBox(
            height: 8,
          ),

          _InfoRow(
            icon:
                LucideIcons.calendarDays,
            text:
                '$date${startTime.isEmpty ? '' : ' • ${_formatTime(startTime)}'}',
          ),

          const SizedBox(
            height: 8,
          ),

          _InfoRow(
            icon:
                LucideIcons.clock3,
            text:
                '$duration ${duration == 1 ? 'hour' : 'hours'}',
          ),

          if (workerId.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            _AssignedWorkerInfo(
              workerId:
                  workerId,
            ),
          ],

          const SizedBox(
            height: 17,
          ),

          Container(
            height: 1,
            color:
                AppColors.line,
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 18,
                color:
                    AppColors.gold,
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                '৳${_formatBudget(budget)}',
                style:
                    AppText.heading(
                  size: 16,
                ),
              ),

              const Spacer(),

              if (status == 'assigned')
                Text(
                  'Waiting for worker',
                  style:
                      AppText.label(
                    size: 9,
                    color:
                        AppColors.muted,
                  ),
                ),

              if (inProgress)
                Row(
                  children: [
                    const Icon(
                      LucideIcons.timer,
                      size: 14,
                      color:
                          AppColors.success,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      'Work in progress',
                      style:
                          AppText.label(
                        size: 9,
                        color:
                            AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (status == 'assigned') ...[
            const SizedBox(
              height: 16,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                13,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.background,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.clock3,
                    size: 16,
                    color:
                        AppColors.gold,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'The worker has been assigned. Waiting for them to start the work.',
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (inProgress) ...[
            const SizedBox(
              height: 18,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _busy
                        ? null
                        : _completeWork,
                icon:
                    _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.circleCheck,
                            size: 17,
                          ),
                label: Text(
                  _busy
                      ? 'Completing...'
                      : 'Mark Work Complete',
                  style:
                      AppText.label(
                    size: 12,
                    color:
                        Colors.white,
                  ),
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      AppColors.ink,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      AppColors.inkSoft,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignedWorkerInfo
    extends StatelessWidget {
  const _AssignedWorkerInfo({
    required this.workerId,
  });

  final String workerId;

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(workerId)
              .get(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _InfoRow(
            icon:
                LucideIcons.userRound,
            text:
                'Loading worker...',
          );
        }

        final data =
            snapshot.data?.data();

        final name =
            data?['name']
                    ?.toString()
                    .trim() ??
                '';

        final phone =
            data?['phone']
                    ?.toString()
                    .trim() ??
                '';

        if (name.isEmpty &&
            phone.isEmpty) {
          return const _InfoRow(
            icon:
                LucideIcons.userRound,
            text:
                'Assigned worker',
          );
        }

        if (name.isNotEmpty &&
            phone.isNotEmpty) {
          return _InfoRow(
            icon:
                LucideIcons.userRound,
            text:
                '$name • $phone',
          );
        }

        return _InfoRow(
          icon:
              LucideIcons.userRound,
          text:
              name.isNotEmpty
                  ? name
                  : phone,
        );
      },
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              AppColors.muted,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                AppText.body(
              size: 11,
              color:
                  AppColors.inkSoft,
            ),
          ),
        ),
      ],
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
    final inProgress =
        status ==
            'in_progress';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            inProgress
                ? const Color(
                    0xFFE4EFE8,
                  )
                : const Color(
                    0xFFE6EDF8,
                  ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Text(
        inProgress
            ? 'IN PROGRESS'
            : 'ASSIGNED',
        style:
            AppText.label(
          size: 7.5,
          color:
              inProgress
                  ? AppColors.success
                  : const Color(
                      0xFF385A85,
                    ),
        ),
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
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const PremiumIconBox(
              icon:
                  LucideIcons.clock3,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'No ongoing work',
              style:
                  AppText.heading(
                size: 19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Assigned and in-progress jobs will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  AppText.body(
                size: 12,
                color:
                    AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Text(
          'Unable to load ongoing work.\n$message',
          textAlign:
              TextAlign.center,
          style:
              AppText.body(
            size: 12,
            color:
                AppColors.muted,
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmComplete(
  BuildContext context,
) async {
  final result =
      await showDialog<bool>(
    context: context,
    builder: (
      dialogContext,
    ) {
      return AlertDialog(
        backgroundColor:
            AppColors.surface,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),
        title: Text(
          'Mark work complete?',
          style:
              AppText.heading(
            size: 18,
          ),
        ),
        content: Text(
          'Confirm that the worker has finished this job. The job will be moved to Completed.',
          style:
              AppText.body(
            size: 12,
            color:
                AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child:
                Text(
              'Cancel',
              style:
                  AppText.label(
                size: 11,
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  AppColors.ink,
              foregroundColor:
                  Colors.white,
            ),
            child:
                Text(
              'Complete',
              style:
                  AppText.label(
                size: 11,
                color:
                    Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

String _formatDate(
  DateTime date,
) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}

String _formatTime(
  String value,
) {
  final text =
      value.trim();

  if (text.toUpperCase().contains(
        'AM',
      ) ||
      text.toUpperCase().contains(
        'PM',
      )) {
    return text;
  }

  final parts =
      text.split(':');

  if (parts.length != 2) {
    return value;
  }

  final hour =
      int.tryParse(
    parts[0],
  );

  final minute =
      int.tryParse(
    parts[1],
  );

  if (hour == null ||
      minute == null) {
    return value;
  }

  final period =
      hour >= 12
          ? 'PM'
          : 'AM';

  final hour12 =
      hour == 0
          ? 12
          : hour > 12
              ? hour - 12
              : hour;

  return '$hour12:'
      '${minute.toString().padLeft(2, '0')} '
      '$period';
}

String _formatBudget(
  double value,
) {
  if (value ==
      value.roundToDouble()) {
    return value
        .toInt()
        .toString();
  }

  return value.toStringAsFixed(
    2,
  );
}
