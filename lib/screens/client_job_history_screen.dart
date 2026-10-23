import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_service.dart';
import '../services/review_service.dart';
import '../utils/app_error.dart';
import '../widgets/premium_ui.dart';

class ClientJobHistoryScreen extends StatelessWidget {
  const ClientJobHistoryScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final jobService =
        JobService();

    final reviewService =
        ReviewService();

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
                    jobService.getClientCompletedJobs(),
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
                      'CLIENT JOB HISTORY STREAM ERROR: ${snapshot.error}',
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

                  final totalSpent =
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
                        totalSpent:
                            totalSpent,
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Completed jobs',
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
                            reviewService:
                                reviewService,
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
                  'Job history',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  'Completed jobs and worker reviews',
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
    required this.totalSpent,
  });

  final int completed;
  final double totalSpent;

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
            'HISTORY OVERVIEW',
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
                      'Total spent',
                  value:
                      '৳${_formatBudget(totalSpent)}',
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
    extends StatefulWidget {
  const _HistoryJobCard({
    required this.job,
    required this.reviewService,
  });

  final Map<String, dynamic>
      job;

  final ReviewService
      reviewService;

  @override
  State<_HistoryJobCard>
      createState() =>
          _HistoryJobCardState();
}

class _HistoryJobCardState
    extends State<_HistoryJobCard> {
  bool _submittingReview = false;

  Future<void> _openReviewDialog() async {
    final jobId =
        widget.job['jobId']
                ?.toString() ??
            '';

    final workerId =
        widget.job['assignedWorkerId']
                ?.toString() ??
            '';

    if (jobId.isEmpty ||
        workerId.isEmpty ||
        _submittingReview) {
      return;
    }

    final result =
        await showDialog<_ReviewResult>(
      context:
          context,
      barrierDismissible:
          false,
      builder: (
        context,
      ) {
        return const _ReviewDialog();
      },
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _submittingReview =
          true;
    });

    try {
      await widget.reviewService
          .submitReview(
        jobId:
            jobId,
        stars:
            result.stars,
        comment:
            result.comment,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Review submitted successfully.',
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
            AppError.message(
              e,
              fallback:
                  'Unable to submit your review. Please try again.',
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingReview =
              false;
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

    final jobId =
        job['jobId']
                ?.toString() ??
            '';

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

          if (workerId.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            _WorkerInfo(
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
                'Job finished',
                style:
                    AppText.label(
                  size: 9,
                  color:
                      AppColors.success,
                ),
              ),
            ],
          ),

          if (jobId.isNotEmpty &&
              workerId.isNotEmpty) ...[
            const SizedBox(
              height: 17,
            ),

            StreamBuilder<
                Map<String, dynamic>?>(
              stream:
                  widget.reviewService
                      .getReviewForJob(
                jobId,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      14,
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
                    child:
                        const Center(
                      child:
                          SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              AppColors.ink,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'CLIENT REVIEW STREAM ERROR: ${snapshot.error}',
                  );

                  return Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      14,
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
                    child: Text(
                      'Unable to load review status right now.',
                      textAlign:
                          TextAlign.center,
                      style:
                          AppText.body(
                        size:
                            10.5,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  );
                }

                final review =
                    snapshot.data;

                if (review != null) {
                  return _SubmittedReview(
                    review:
                        review,
                  );
                }

                return SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _submittingReview
                            ? null
                            : _openReviewDialog,
                    icon:
                        _submittingReview
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
                                LucideIcons.star,
                                size: 17,
                              ),
                    label:
                        Text(
                      _submittingReview
                          ? 'Submitting...'
                          : 'Rate Worker',
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
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmittedReview
    extends StatelessWidget {
  const _SubmittedReview({
    required this.review,
  });

  final Map<String, dynamic>
      review;

  @override
  Widget build(
    BuildContext context,
  ) {
    final stars =
        (review['stars']
                    as num?)
                ?.toInt() ??
            0;

    final comment =
        review['comment']
                ?.toString()
                .trim() ??
            '';

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.goldSoft,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.circleCheck,
                size: 16,
                color:
                    AppColors.success,
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  'Your review',
                  style:
                      AppText.heading(
                    size: 12.5,
                  ),
                ),
              ),

              Text(
                '$stars/5',
                style:
                    AppText.label(
                  size: 10,
                  color:
                      AppColors.ink,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children:
                List.generate(
              5,
              (
                index,
              ) {
                final active =
                    index <
                        stars;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 3,
                  ),
                  child: Icon(
                    active
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color:
                        active
                            ? AppColors.gold
                            : AppColors.muted,
                  ),
                );
              },
            ),
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(
              height: 9,
            ),

            Text(
              comment,
              style:
                  AppText.body(
                size: 11,
                color:
                    AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewDialog
    extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog>
      createState() =>
          _ReviewDialogState();
}

class _ReviewDialogState
    extends State<_ReviewDialog> {
  final TextEditingController
      _commentController =
      TextEditingController();

  int _stars = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a star rating.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final comment =
        _commentController.text
            .trim();

    if (comment.length >
        500) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Review cannot exceed 500 characters.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      _ReviewResult(
        stars:
            _stars,
        comment:
            comment,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor:
          AppColors.surface,
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      titlePadding:
          const EdgeInsets.fromLTRB(
        22,
        22,
        22,
        0,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        22,
        16,
        22,
        6,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ),
      title: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your worker',
            style:
                AppText.heading(
              size: 20,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'How was your experience with this worker?',
            style:
                AppText.body(
              size: 11.5,
              color:
                  AppColors.muted,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children:
                    List.generate(
                  5,
                  (
                    index,
                  ) {
                    final value =
                        index +
                            1;

                    final active =
                        value <=
                            _stars;

                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _stars =
                              value;
                        });
                      },
                      padding:
                          const EdgeInsets.all(
                        4,
                      ),
                      constraints:
                          const BoxConstraints(),
                      icon:
                          Icon(
                        active
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 35,
                        color:
                            active
                                ? AppColors.gold
                                : AppColors.muted,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Center(
              child: Text(
                _ratingText(
                  _stars,
                ),
                style:
                    AppText.label(
                  size: 10.5,
                  color:
                      _stars == 0
                          ? AppColors.muted
                          : AppColors.ink,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'Review',
              style:
                  AppText.heading(
                size: 13,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            TextField(
              controller:
                  _commentController,
              maxLines:
                  4,
              maxLength:
                  500,
              decoration:
                  InputDecoration(
                hintText:
                    'Write a short review (optional)',
                hintStyle:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.muted,
                ),
                filled:
                    true,
                fillColor:
                    AppColors.background,
                contentPadding:
                    const EdgeInsets.all(
                  14,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
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
                    15,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        AppColors.line,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        AppColors.ink,
                  ),
                ),
              ),
              style:
                  AppText.body(
                size: 12,
                color:
                    AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
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

        ElevatedButton.icon(
          onPressed:
              _submit,
          icon:
              const Icon(
            LucideIcons.send,
            size: 15,
          ),
          label:
              Text(
            'Submit Review',
            style:
                AppText.label(
              size: 11,
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
            elevation:
                0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewResult {
  const _ReviewResult({
    required this.stars,
    required this.comment,
  });

  final int stars;
  final String comment;
}

class _WorkerInfo
    extends StatelessWidget {
  const _WorkerInfo({
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
              .collection(
                'users',
              )
              .doc(
                workerId,
              )
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
              'Worker details unavailable',
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
              'No completed jobs',
              style:
                  AppText.heading(
                size: 19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Finished jobs will appear here.',
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
          'Unable to load job history.\n$message',
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

String _ratingText(
  int stars,
) {
  switch (stars) {
    case 1:
      return 'Poor';

    case 2:
      return 'Fair';

    case 3:
      return 'Good';

    case 4:
      return 'Very good';

    case 5:
      return 'Excellent';

    default:
      return 'Tap a star to rate';
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
