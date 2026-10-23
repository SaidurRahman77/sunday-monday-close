import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_service.dart';
import '../widgets/premium_ui.dart';
import 'client_applicants_screen.dart';
import 'post_job_screen.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final JobService jobService =
        JobService();

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
            ),

            Expanded(
              child: StreamBuilder<
                  List<Map<String, dynamic>>>(
                stream:
                    jobService.getMyJobs(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            AppColors.ink,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const _ErrorState(
                      message:
                          'Unable to load your jobs.',
                    );
                  }

                  final jobs =
                      snapshot.data ?? [];

                  if (jobs.isEmpty) {
                    return _EmptyJobsState(
                      onPostJob: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PostJobScreen(),
                          ),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      36,
                    ),
                    itemCount:
                        jobs.length,
                    separatorBuilder:
                        (
                          context,
                          index,
                        ) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final job =
                          jobs[index];

                      return _JobCard(
                        job: job,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
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
        color:
            AppColors.background,
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
                AppColors.surface,
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
              child: Container(
                width: 44,
                height: 44,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        AppColors.line,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons.arrowLeft,
                  size: 19,
                  color:
                      AppColors.ink,
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
                  'My jobs',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                Text(
                  'Your posted opportunities',
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
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: Text(
              'CLIENT',
              style:
                  AppText.label(
                size: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard
    extends StatelessWidget {
  const _JobCard({
    required this.job,
  });

  final Map<String, dynamic>
      job;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        job['title']?.toString() ??
            'Untitled job';

    final category =
        job['category']?.toString() ??
            'Other';

    final location =
        job['location']?.toString() ??
            'Location not set';

    final startTime =
        job['startTime']?.toString() ??
            '';

    final status =
        job['status']?.toString() ??
            'open';

    final durationHours =
        (job['durationHours']
                    as num?)
                ?.toInt() ??
            0;

    final rawBudget =
        job['budget'];

    double budget = 0;

    if (rawBudget is num) {
      budget =
          rawBudget.toDouble();
    }

    final rawDate =
        job['workDate'];

    DateTime? workDate;

    if (rawDate is Timestamp) {
      workDate =
          rawDate.toDate();
    }

    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        24,
      ),
      child: InkWell(
        onTap: () {
          _showJobDetails(
            context,
          );
        },
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            20,
          ),
          decoration:
              BoxDecoration(
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
                      size: 20,
                      color:
                          AppColors.ink,
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
                          category
                              .toUpperCase(),
                          style:
                              AppText.label(
                            size: 9,
                            color:
                                AppColors.gold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
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
                    width: 10,
                  ),

                  _StatusBadge(
                    status:
                        status,
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              _InfoRow(
                icon:
                    LucideIcons.mapPin,
                value:
                    location,
              ),

              const SizedBox(
                height: 9,
              ),

              Row(
                children: [
                  const Icon(
                    LucideIcons.calendarDays,
                    size: 15,
                    color:
                        AppColors.muted,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    workDate == null
                        ? 'Date not set'
                        : _formatDate(
                            workDate,
                          ),
                    style:
                        AppText.body(
                      size: 11.5,
                      color:
                          AppColors.inkSoft,
                    ),
                  ),

                  if (startTime
                      .isNotEmpty) ...[
                    const SizedBox(
                      width: 14,
                    ),

                    const Icon(
                      LucideIcons.clock3,
                      size: 15,
                      color:
                          AppColors.muted,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      _formatTime(
                        startTime,
                      ),
                      style:
                          AppText.body(
                        size: 11.5,
                        color:
                            AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
                height: 1,
                color:
                    AppColors.line,
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style:
                            AppText.label(
                          size: 8.5,
                          color:
                              AppColors.muted,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        '৳${_formatBudget(budget)}',
                        style:
                            AppText.heading(
                          size: 17,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DURATION',
                        style:
                            AppText.label(
                          size: 8.5,
                          color:
                              AppColors.muted,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        '$durationHours hr',
                        style:
                            AppText.heading(
                          size: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Container(
                    width: 36,
                    height: 36,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.background,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        const Icon(
                      LucideIcons.chevronRight,
                      size: 17,
                      color:
                          AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetails(
    BuildContext context,
  ) {
    final description =
        job['description']
                ?.toString() ??
            'No description';

    final skills =
        (job['requiredSkills']
                    as List?)
                ?.map(
                  (e) =>
                      e.toString(),
                )
                .toList() ??
            <String>[];

    final jobId =
        job['jobId']
                ?.toString() ??
            '';

    final jobTitle =
        job['title']
                ?.toString() ??
            'Job';

    final status =
        job['status']
                ?.toString()
                .toLowerCase() ??
            'open';

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true,
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
            22,
            14,
            22,
            28,
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
                mainAxisSize:
                    MainAxisSize.min,
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
                    height: 22,
                  ),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          jobTitle,
                          style:
                              AppText.heading(
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      _StatusBadge(
                        status:
                            status,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    description,
                    style:
                        AppText.body(
                      size: 13,
                    ),
                  ),

                  if (skills
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 22,
                    ),

                    Text(
                      'Required skills',
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          skills.map(
                        (skill) {
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  11,
                              vertical:
                                  7,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.goldSoft,
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                            ),
                            child:
                                Text(
                              skill,
                              style:
                                  AppText.label(
                                size: 10,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],

                  const SizedBox(
                    height: 26,
                  ),

                  if (jobId.isNotEmpty)
                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClientApplicantsScreen(
                                jobId:
                                    jobId,
                                jobTitle:
                                    jobTitle,
                              ),
                            ),
                          );
                        },
                        icon:
                            const Icon(
                          LucideIcons.users,
                          size: 18,
                        ),
                        label:
                            Text(
                          'View Applicants',
                          style:
                              AppText.label(
                            size: 12,
                            color:
                                Colors.white,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.ink,
                          foregroundColor:
                              Colors.white,
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

                  if (jobId.isNotEmpty)
                    const SizedBox(
                      height: 10,
                    ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            AppColors.ink,
                        side:
                            const BorderSide(
                          color:
                              AppColors.line,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),
                      child:
                          Text(
                        'Close',
                        style:
                            AppText.label(
                          size: 12,
                        ),
                      ),
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
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

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
          width: 6,
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                AppText.body(
              size: 11.5,
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
    final normalized =
        status.toLowerCase();

    Color background;
    Color foreground;
    String text;

    switch (normalized) {
      case 'open':
        background =
            AppColors.goldSoft;
        foreground =
            const Color(
          0xFF85611E,
        );
        text =
            'OPEN';
        break;

      case 'assigned':
        background =
            const Color(
          0xFFE6EDF8,
        );
        foreground =
            const Color(
          0xFF385A85,
        );
        text =
            'ASSIGNED';
        break;

      case 'in_progress':
        background =
            const Color(
          0xFFE9E6F5,
        );
        foreground =
            const Color(
          0xFF5F5188,
        );
        text =
            'IN PROGRESS';
        break;

      case 'completed':
        background =
            const Color(
          0xFFE4EFE8,
        );
        foreground =
            AppColors.success;
        text =
            'COMPLETED';
        break;

      case 'cancelled':
        background =
            const Color(
          0xFFF3E5E5,
        );
        foreground =
            const Color(
          0xFF925252,
        );
        text =
            'CANCELLED';
        break;

      default:
        background =
            AppColors.background;
        foreground =
            AppColors.inkSoft;
        text =
            normalized
                .toUpperCase();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Text(
        text,
        style:
            AppText.label(
          size: 8,
          color:
              foreground,
        ),
      ),
    );
  }
}

class _EmptyJobsState
    extends StatelessWidget {
  const _EmptyJobsState({
    required this.onPostJob,
  });

  final VoidCallback onPostJob;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration:
                  const BoxDecoration(
                color:
                    AppColors.goldSoft,
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                LucideIcons.briefcase,
                size: 28,
                color:
                    AppColors.ink,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            Text(
              'No jobs yet',
              style:
                  AppText.heading(
                size: 22,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Your posted jobs will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  AppText.body(
                size: 13,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            ElevatedButton.icon(
              onPressed:
                  onPostJob,
              icon:
                  const Icon(
                LucideIcons.plus,
                size: 17,
              ),
              label:
                  Text(
                'Post your first job',
                style:
                    AppText.label(
                  color:
                      Colors.white,
                  size: 12,
                ),
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    AppColors.ink,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      18,
                  vertical:
                      14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
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
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              size: 32,
              color:
                  AppColors.muted,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  AppText.body(),
            ),
          ],
        ),
      ),
    );
  }
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
      text.split(
    ':',
  );

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