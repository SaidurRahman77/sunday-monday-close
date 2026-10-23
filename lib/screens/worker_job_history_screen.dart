import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_service.dart';
import '../widgets/premium_ui.dart';

class WorkerJobHistoryScreen extends StatelessWidget {
  const WorkerJobHistoryScreen({
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
                    jobService.getWorkerCompletedJobs(),
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
                    return _ErrorState(
                      message:
                          snapshot.error.toString(),
                    );
                  }

                  final jobs =
                      snapshot.data ?? [];

                  if (jobs.isEmpty) {
                    return const _EmptyState();
                  }

                  final totalEarned =
                      jobs.fold<double>(
                    0,
                    (
                      total,
                      job,
                    ) {
                      final budget =
                          job['budget'];

                      if (budget is num) {
                        return total +
                            budget.toDouble();
                      }

                      return total;
                    },
                  );

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
                        completed:
                            jobs.length,
                        totalEarned:
                            totalEarned,
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Completed work',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),

                          Text(
                            '${jobs.length} total',
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
                        (
                          job,
                        ) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _HistoryJobCard(
                            job:
                                job,
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
                  'Work history',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  'Your completed jobs and earnings',
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
              LucideIcons.history,
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
    required this.completed,
    required this.totalEarned,
  });

  final int completed;
  final double totalEarned;

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
            'WORK HISTORY',
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
            '$completed completed ${completed == 1 ? 'job' : 'jobs'}',
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
                  icon:
                      LucideIcons.circleCheck,
                  label:
                      'Completed',
                  value:
                      '$completed',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _OverviewItem(
                  icon:
                      Icons.payments_outlined,
                  label:
                      'Total earned',
                  value:
                      '৳${_formatBudget(totalEarned)}',
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
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      AppText.heading(
                    size: 16,
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
          ),
        ],
      ),
    );
  }
}

class _HistoryJobCard
    extends StatelessWidget {
  const _HistoryJobCard({
    required this.job,
  });

  final Map<String, dynamic>
      job;

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
            'Job';

    final location =
        job['location']
                ?.toString() ??
            'Location not set';

    final clientId =
        job['clientId']
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

    final workDateRaw =
        job['workDate'];

    final completedAtRaw =
        job['completedAt'];

    final workDate =
        workDateRaw is Timestamp
            ? _formatDate(
                workDateRaw.toDate(),
              )
            : 'Date not set';

    final completedAt =
        completedAtRaw is Timestamp
            ? _formatDateTime(
                completedAtRaw.toDate(),
              )
            : 'Completion time unavailable';

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
                  LucideIcons.circleCheck,
                  size: 19,
                  color:
                      AppColors.success,
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

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE4EFE8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  'COMPLETED',
                  style:
                      AppText.label(
                    size: 7.5,
                    color:
                        AppColors.success,
                  ),
                ),
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
                'Work date: $workDate',
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

          const SizedBox(
            height: 8,
          ),

          _InfoRow(
            icon:
                LucideIcons.circleCheck,
            text:
                'Completed: $completedAt',
          ),

          if (clientId.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            _ClientInfo(
              clientId:
                  clientId,
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
            height: 14,
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

              const Icon(
                LucideIcons.circleCheck,
                size: 15,
                color:
                    AppColors.success,
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                'Earned',
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
    );
  }
}

class _ClientInfo
    extends StatelessWidget {
  const _ClientInfo({
    required this.clientId,
  });

  final String clientId;

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(clientId)
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
                'Loading client...',
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

        if (name.isNotEmpty &&
            phone.isNotEmpty) {
          return _InfoRow(
            icon:
                LucideIcons.userRound,
            text:
                '$name • $phone',
          );
        }

        if (name.isNotEmpty) {
          return _InfoRow(
            icon:
                LucideIcons.userRound,
            text:
                name,
          );
        }

        if (phone.isNotEmpty) {
          return _InfoRow(
            icon:
                LucideIcons.phone,
            text:
                phone,
          );
        }

        return const _InfoRow(
          icon:
              LucideIcons.userRound,
          text:
              'Client details unavailable',
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
                  LucideIcons.history,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'No completed work',
              style:
                  AppText.heading(
                size: 19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Jobs you complete will appear here.',
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
          'Unable to load work history.\n$message',
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

String _formatDateTime(
  DateTime date,
) {
  final dateText =
      _formatDate(
    date,
  );

  final hour24 =
      date.hour;

  final period =
      hour24 >= 12
          ? 'PM'
          : 'AM';

  final hour12 =
      hour24 == 0
          ? 12
          : hour24 > 12
              ? hour24 - 12
              : hour24;

  final minute =
      date.minute
          .toString()
          .padLeft(
            2,
            '0',
          );

  return '$dateText • $hour12:$minute $period';
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