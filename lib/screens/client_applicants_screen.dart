import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/application_service.dart';
import '../utils/app_error.dart';
import '../widgets/premium_ui.dart';
import 'worker_public_profile_screen.dart';
import 'worker_public_reviews_screen.dart';

class ClientApplicantsScreen extends StatelessWidget {
  const ClientApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    final applicationService = ApplicationService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ApplicantsHeader(
              jobTitle: jobTitle,
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: applicationService.getApplicantsForJob(
                  jobId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      'CLIENT APPLICANTS STREAM ERROR: ${snapshot.error}',
                    );

                    return const _ErrorState(
                      message:
                          'Please try again in a moment.',
                    );
                  }

                  final applications = snapshot.data ?? [];

                  if (applications.isEmpty) {
                    return const _EmptyState();
                  }

                  final pendingCount = applications
                      .where(
                        (item) =>
                            item['status']
                                ?.toString()
                                .toLowerCase() ==
                            'pending',
                      )
                      .length;

                  final acceptedCount = applications
                      .where(
                        (item) =>
                            item['status']
                                ?.toString()
                                .toLowerCase() ==
                            'accepted',
                      )
                      .length;

                  final rejectedCount = applications
                      .where(
                        (item) =>
                            item['status']
                                ?.toString()
                                .toLowerCase() ==
                            'rejected',
                      )
                      .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      40,
                    ),
                    children: [
                      _SummaryCard(
                        total: applications.length,
                        pending: pendingCount,
                        accepted: acceptedCount,
                        rejected: rejectedCount,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Applicants',
                              style: AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${applications.length} total',
                            style: AppText.body(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      ...applications.map(
                        (application) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child: _ApplicantCard(
                              application: application,
                              service: applicationService,
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

class _ApplicantsHeader extends StatelessWidget {
  const _ApplicantsHeader({
    required this.jobTitle,
  });

  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        20,
        18,
      ),
      decoration: const BoxDecoration(
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
            borderRadius: BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applicants',
                  style: AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              LucideIcons.users,
              size: 18,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLICANT OVERVIEW',
            style: AppText.label(
              size: 8.5,
              color: Colors.white60,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            '$total ${total == 1 ? 'application' : 'applications'} received',
            style: AppText.heading(
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Pending',
                  value: pending,
                  icon: LucideIcons.clock3,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Accepted',
                  value: accepted,
                  icon: LucideIcons.circleCheck,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Rejected',
                  value: rejected,
                  icon: LucideIcons.circleX,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.gold,
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            '$value',
            style: AppText.heading(
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            style: AppText.body(
              size: 8.5,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatefulWidget {
  const _ApplicantCard({
    required this.application,
    required this.service,
  });

  final Map<String, dynamic> application;
  final ApplicationService service;

  @override
  State<_ApplicantCard> createState() =>
      _ApplicantCardState();
}

class _ApplicantCardState extends State<_ApplicantCard> {
  bool _busy = false;

  Future<bool> _accept() async {
    final applicationId =
        widget.application['applicationId']
                ?.toString() ??
            '';

    if (applicationId.isEmpty || _busy) {
      return false;
    }

    final confirmed = await _confirmAction(
      context,
      title: 'Accept applicant?',
      message:
          'This worker will be assigned to the job. Other pending applications will be rejected.',
      confirmText: 'Accept',
    );

    if (!confirmed || !mounted) {
      return false;
    }

    setState(() {
      _busy = true;
    });

    try {
      await widget.service.acceptApplication(
        applicationId: applicationId,
      );

      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Applicant accepted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              e,
              fallback:
                  'Unable to accept this applicant. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<bool> _reject() async {
    final applicationId =
        widget.application['applicationId']
                ?.toString() ??
            '';

    if (applicationId.isEmpty || _busy) {
      return false;
    }

    final confirmed = await _confirmAction(
      context,
      title: 'Reject applicant?',
      message:
          'This application will be marked as rejected.',
      confirmText: 'Reject',
    );

    if (!confirmed || !mounted) {
      return false;
    }

    setState(() {
      _busy = true;
    });

    try {
      await widget.service.rejectApplication(
        applicationId: applicationId,
      );

      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application rejected.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              e,
              fallback:
                  'Unable to reject this application. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _openProfile({
    required String workerId,
    required String workerName,
    required String status,
  }) {
    if (workerId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerPublicProfileScreen(
          workerId: workerId,
          workerName: workerName,
          applicationStatus: status,
          onAccept: status == 'pending'
              ? () async {
                  final success = await _accept();

                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                }
              : null,
          onReject: status == 'pending'
              ? () async {
                  final success = await _reject();

                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;

    final workerName =
        application['workerName']?.toString() ??
            'Worker';

    final workerId =
        application['workerId']?.toString() ?? '';

    final workerEmail =
        application['workerEmail']?.toString() ?? '';

    final workerLocation =
        application['workerLocation']?.toString() ??
            'Location not provided';

    final status =
        application['status']
                ?.toString()
                .toLowerCase() ??
            'pending';

    final matchScore =
        (application['matchScore'] as num?)
                ?.toInt() ??
            0;

    final experience =
        (application['experienceYears'] as num?)
                ?.toInt() ??
            0;

    final rating =
        (application['rating'] as num?)
                ?.toDouble() ??
            0;

    final reviewCount =
        (application['reviewCount'] as num?)
                ?.toInt() ??
            0;

    final rawSkills =
        application['workerSkills'];

    final skills = rawSkills is List
        ? rawSkills
            .map(
              (item) => item.toString(),
            )
            .toList()
        : <String>[];

    final statusData = _statusData(
      status,
    );

    final canManage = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ApplicantAvatar(
                workerId: workerId,
                workerName: workerName,
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
                      workerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(
                        size: 16,
                      ),
                    ),
                    if (workerEmail.isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mail,
                            size: 12,
                            color: AppColors.muted,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(
                              workerEmail,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (workerId.isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      _WorkerPhone(
                        workerId: workerId,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              _StatusBadge(
                label: statusData.label,
                color: statusData.color,
                icon: statusData.icon,
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Match',
                  value: '$matchScore%',
                  icon: LucideIcons.sparkles,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: _Metric(
                  label: 'Experience',
                  value:
                      '$experience ${experience == 1 ? 'yr' : 'yrs'}',
                  icon:
                      LucideIcons.briefcaseBusiness,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: _LiveWorkerRatingMetric(
                  workerId: workerId,
                  fallbackRating: rating,
                  fallbackReviewCount: reviewCount,
                ),
              ),
            ],
          ),
          if (workerId.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _openProfile(
                        workerId: workerId,
                        workerName: workerName,
                        status: status,
                      );
                    },
                    icon: const Icon(
                      LucideIcons.userRoundSearch,
                      size: 16,
                    ),
                    label: Text(
                      'View profile',
                      style: AppText.label(
                        size: 10.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      backgroundColor:
                          AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.line,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: _WorkerReviewsButton(
                    workerId: workerId,
                    workerName: workerName,
                    fallbackReviewCount:
                        reviewCount,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: Text(
                  workerLocation,
                  style: AppText.body(
                    size: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: skills
                  .take(6)
                  .map(
                    (skill) => Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: AppText.label(
                          size: 8.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(
            height: 18,
          ),
          Container(
            height: 1,
            color: AppColors.line,
          ),
          const SizedBox(
            height: 16,
          ),
          if (_busy)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.ink,
                ),
              ),
            )
          else if (canManage)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _reject();
                    },
                    icon: const Icon(
                      LucideIcons.x,
                      size: 16,
                    ),
                    label: Text(
                      'Reject',
                      style: AppText.label(
                        size: 11.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.inkSoft,
                      side: const BorderSide(
                        color: AppColors.line,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _accept();
                    },
                    icon: const Icon(
                      LucideIcons.check,
                      size: 16,
                    ),
                    label: Text(
                      'Accept',
                      style: AppText.label(
                        size: 11.5,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.ink,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Text(
                status == 'accepted'
                    ? 'This worker has been selected.'
                    : 'This application has been rejected.',
                style: AppText.body(
                  size: 10.5,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({
    required this.workerId,
    required this.workerName,
  });

  final String workerId;
  final String workerName;

  @override
  Widget build(BuildContext context) {
    if (workerId.isEmpty) {
      return _fallbackAvatar();
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final photoUrl =
            data?['photoUrl']
                    ?.toString()
                    .trim() ??
                '';

        if (photoUrl.isEmpty) {
          return _fallbackAvatar();
        }

        return Container(
          width: 48,
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: AppColors.line,
            ),
          ),
          child: Image.network(
            photoUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return _fallbackAvatar();
            },
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: Text(
        _initials(
          workerName,
        ),
        style: AppText.heading(
          size: 15,
        ),
      ),
    );
  }
}

class _WorkerPhone extends StatelessWidget {
  const _WorkerPhone({
    required this.workerId,
  });

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return Row(
            children: [
              const Icon(
                LucideIcons.phone,
                size: 12,
                color: AppColors.muted,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                'Loading phone...',
                style: AppText.body(
                  size: 10,
                  color: AppColors.muted,
                ),
              ),
            ],
          );
        }

        final data = snapshot.data?.data();

        final phone =
            data?['phone']?.toString().trim() ?? '';

        return Row(
          children: [
            const Icon(
              LucideIcons.phone,
              size: 12,
              color: AppColors.muted,
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: Text(
                phone.isEmpty
                    ? 'Phone not provided'
                    : phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 10,
                  color: phone.isEmpty
                      ? AppColors.muted
                      : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveWorkerRatingMetric extends StatelessWidget {
  const _LiveWorkerRatingMetric({
    required this.workerId,
    required this.fallbackRating,
    required this.fallbackReviewCount,
  });

  final String workerId;
  final double fallbackRating;
  final int fallbackReviewCount;

  @override
  Widget build(BuildContext context) {
    if (workerId.isEmpty) {
      return _Metric(
        label: 'Rating',
        value: fallbackReviewCount == 0
            ? 'New'
            : fallbackRating.toStringAsFixed(1),
        icon: LucideIcons.star,
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final rawWorkerProfile =
            data?['workerProfile'];

        final workerProfile =
            rawWorkerProfile is Map
                ? Map<String, dynamic>.from(
                    rawWorkerProfile,
                  )
                : <String, dynamic>{};

        final liveRating =
            (workerProfile['rating'] as num?)
                    ?.toDouble() ??
                fallbackRating;

        final liveReviewCount =
            (workerProfile['reviewCount'] as num?)
                    ?.toInt() ??
                fallbackReviewCount;

        return _Metric(
          label: liveReviewCount == 1
              ? '1 review'
              : '$liveReviewCount reviews',
          value: liveReviewCount == 0
              ? 'New'
              : liveRating.toStringAsFixed(1),
          icon: LucideIcons.star,
        );
      },
    );
  }
}

class _WorkerReviewsButton extends StatelessWidget {
  const _WorkerReviewsButton({
    required this.workerId,
    required this.workerName,
    required this.fallbackReviewCount,
  });

  final String workerId;
  final String workerName;
  final int fallbackReviewCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final rawWorkerProfile =
            data?['workerProfile'];

        final workerProfile =
            rawWorkerProfile is Map
                ? Map<String, dynamic>.from(
                    rawWorkerProfile,
                  )
                : <String, dynamic>{};

        final reviewCount =
            (workerProfile['reviewCount'] as num?)
                    ?.toInt() ??
                fallbackReviewCount;

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkerPublicReviewsScreen(
                    workerId: workerId,
                    workerName: workerName,
                  ),
                ),
              );
            },
            icon: const Icon(
              LucideIcons.messageSquareText,
              size: 16,
            ),
            label: Text(
              reviewCount == 0
                  ? 'View reviews'
                  : 'Reviews ($reviewCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                size: 10.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              backgroundColor: AppColors.surface,
              side: const BorderSide(
                color: AppColors.line,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.gold,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.heading(
              size: 12,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 7.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            label.toUpperCase(),
            style: AppText.label(
              size: 7.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumIconBox(
              icon: LucideIcons.users,
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              'No applicants yet',
              style: AppText.heading(
                size: 19,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Workers who apply to this job will appear here.',
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Text(
          'Unable to load applicants.\n$message',
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 12,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_StatusInfo _statusData(
  String status,
) {
  switch (status) {
    case 'accepted':
      return const _StatusInfo(
        label: 'Accepted',
        color: AppColors.success,
        icon: LucideIcons.circleCheck,
      );

    case 'rejected':
      return const _StatusInfo(
        label: 'Rejected',
        color: AppColors.muted,
        icon: LucideIcons.circleX,
      );

    default:
      return const _StatusInfo(
        label: 'Pending',
        color: AppColors.gold,
        icon: LucideIcons.clock3,
      );
  }
}

Future<bool> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (
      dialogContext,
    ) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            22,
          ),
        ),
        title: Text(
          title,
          style: AppText.heading(
            size: 18,
          ),
        ),
        content: Text(
          message,
          style: AppText.body(
            size: 12,
            color: AppColors.inkSoft,
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
            child: Text(
              'Cancel',
              style: AppText.label(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              confirmText,
              style: AppText.label(
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

String _initials(
  String name,
) {
  final parts = name
      .trim()
      .split(
        RegExp(
          r'\s+',
        ),
      )
      .where(
        (part) => part.isNotEmpty,
      )
      .toList();

  if (parts.isEmpty) {
    return 'W';
  }

  if (parts.length == 1) {
    return parts.first
        .substring(
          0,
          1,
        )
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'
      .toUpperCase();
}
