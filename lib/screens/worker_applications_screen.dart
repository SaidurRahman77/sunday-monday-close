import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/application_service.dart';
import '../widgets/premium_ui.dart';

class WorkerApplicationsScreen extends StatelessWidget {
  const WorkerApplicationsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final applicationService =
        ApplicationService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ApplicationsHeader(),

            Expanded(
              child: StreamBuilder<
                  List<Map<String, dynamic>>>(
                stream: applicationService
                    .getMyApplications(),
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
                        color: AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message:
                          snapshot.error.toString(),
                    );
                  }

                  final applications =
                      snapshot.data ?? [];

                  if (applications.isEmpty) {
                    return const _EmptyState();
                  }

                  final pendingCount =
                      applications
                          .where(
                            (item) =>
                                item['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'pending',
                          )
                          .length;

                  final acceptedCount =
                      applications
                          .where(
                            (item) =>
                                item['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'accepted',
                          )
                          .length;

                  final rejectedCount =
                      applications
                          .where(
                            (item) =>
                                item['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'rejected',
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
                      _SummaryCard(
                        total:
                            applications.length,
                        pending:
                            pendingCount,
                        accepted:
                            acceptedCount,
                        rejected:
                            rejectedCount,
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your applications',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),

                          Text(
                            '${applications.length} total',
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

                      ...applications.map(
                        (
                          application,
                        ) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child:
                                _ApplicationCard(
                              application:
                                  application,
                            ),
                          );
                        },
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

class _ApplicationsHeader
    extends StatelessWidget {
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
        border: Border(
          bottom: BorderSide(
            color: AppColors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.ink,
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
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: Colors.white,
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
                  'Applications',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  'Track your submitted job applications',
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
            child: const Icon(
              LucideIcons.send,
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

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int accepted;
  final int rejected;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color: AppColors.ink,
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
            'APPLICATION OVERVIEW',
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
            '$total applications submitted',
            style:
                AppText.heading(
              size: 20,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label:
                      'Pending',
                  value:
                      pending,
                  icon:
                      LucideIcons.clock3,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _SummaryItem(
                  label:
                      'Accepted',
                  value:
                      accepted,
                  icon:
                      LucideIcons.circleCheck,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _SummaryItem(
                  label:
                      'Rejected',
                  value:
                      rejected,
                  icon:
                      LucideIcons.circleX,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem
    extends StatelessWidget {
  const _SummaryItem({
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
        horizontal: 10,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                AppColors.gold,
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            '$value',
            style:
                AppText.heading(
              size: 18,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            height: 2,
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
    );
  }
}

class _ApplicationCard
    extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
  });

  final Map<String, dynamic>
      application;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        application['jobTitle']
                ?.toString() ??
            'Untitled job';

    final category =
        application['jobCategory']
                ?.toString() ??
            'Job';

    final status =
        application['status']
                ?.toString()
                .toLowerCase() ??
            'pending';

    final matchScore =
        (application['matchScore']
                    as num?)
                ?.toInt() ??
            0;

    final createdAt =
        application['createdAt']
            as Timestamp?;

    final appliedDate =
        createdAt == null
            ? 'Recently'
            : _formatDateTime(
                createdAt.toDate(),
              );

    final statusData =
        _statusData(
      status,
    );

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
          22,
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
                width: 44,
                height: 44,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  LucideIcons.briefcase,
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
                      category
                          .toUpperCase(),
                      style:
                          AppText.label(
                        size: 8,
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
                width: 10,
              ),

              _StatusBadge(
                label:
                    statusData.label,
                icon:
                    statusData.icon,
                color:
                    statusData.color,
              ),
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
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  icon:
                      LucideIcons.sparkles,
                  label:
                      'Match',
                  value:
                      '$matchScore%',
                ),
              ),

              Container(
                width: 1,
                height: 34,
                color:
                    AppColors.line,
              ),

              Expanded(
                child: _SmallInfo(
                  icon:
                      LucideIcons.calendar,
                  label:
                      'Applied',
                  value:
                      appliedDate,
                ),
              ),
            ],
          ),

          if (status ==
              'pending') ...[
            const SizedBox(
              height: 16,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.goldSoft,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.clock3,
                    size: 15,
                    color:
                        AppColors.ink,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'Waiting for the client to review your application.',
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
            ),
          ],

          if (status ==
              'accepted') ...[
            const SizedBox(
              height: 16,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.surface,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border:
                    Border.all(
                  color:
                      AppColors.success,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.circleCheck,
                    size: 16,
                    color:
                        AppColors.success,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'Your application has been accepted by the client.',
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
            ),
          ],

          if (status ==
              'rejected') ...[
            const SizedBox(
              height: 16,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.background,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.circleX,
                    size: 16,
                    color:
                        AppColors.muted,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'The client selected another applicant for this job.',
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallInfo
    extends StatelessWidget {
  const _SmallInfo({
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
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              AppColors.gold,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style:
                    AppText.label(
                  size: 7,
                  color:
                      AppColors.muted,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppText.heading(
                  size: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
                color,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label.toUpperCase(),
            style:
                AppText.label(
              size: 7.5,
              color:
                  color,
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
                  LucideIcons.send,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'No applications yet',
              style:
                  AppText.heading(
                size: 19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Apply to jobs from Find jobs or Best matches. Your applications will appear here.',
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
          'Unable to load applications.\n$message',
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

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_StatusData _statusData(
  String status,
) {
  switch (status) {
    case 'accepted':
      return const _StatusData(
        label: 'Accepted',
        icon:
            LucideIcons.circleCheck,
        color:
            AppColors.success,
      );

    case 'rejected':
      return const _StatusData(
        label: 'Rejected',
        icon:
            LucideIcons.circleX,
        color:
            AppColors.muted,
      );

    default:
      return const _StatusData(
        label: 'Pending',
        icon:
            LucideIcons.clock3,
        color:
            AppColors.gold,
      );
  }
}

String _formatDateTime(
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
      '${months[date.month - 1]}';
}