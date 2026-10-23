import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/premium_ui.dart';

class WorkerPublicReviewsScreen
    extends StatelessWidget {
  const WorkerPublicReviewsScreen({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  final String workerId;
  final String workerName;

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
              workerName:
                  workerName,
              onBack: () =>
                  Navigator.pop(
                context,
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                          'reviews',
                        )
                        .where(
                          'workerId',
                          isEqualTo:
                              workerId,
                        )
                        .snapshots(),
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
                    return const _MessageState(
                      icon:
                          LucideIcons
                              .triangleAlert,
                      title:
                          'Unable to load reviews',
                      message:
                          'Please try again in a moment.',
                    );
                  }

                  final reviews =
                      (snapshot.data?.docs ??
                              [])
                          .map(
                            (doc) =>
                                <String,
                                    dynamic>{
                              ...doc.data(),
                              'reviewId':
                                  doc.id,
                            },
                          )
                          .where(
                            (review) =>
                                review[
                                        'isHidden'] !=
                                    true,
                          )
                          .toList();

                  reviews.sort(
                    (a, b) {
                      final aCreated =
                          a['createdAt']
                              as Timestamp?;

                      final bCreated =
                          b['createdAt']
                              as Timestamp?;

                      if (aCreated ==
                              null &&
                          bCreated ==
                              null) {
                        return 0;
                      }

                      if (aCreated ==
                          null) {
                        return 1;
                      }

                      if (bCreated ==
                          null) {
                        return -1;
                      }

                      return bCreated
                          .compareTo(
                        aCreated,
                      );
                    },
                  );

                  if (reviews.isEmpty) {
                    return const _MessageState(
                      icon:
                          LucideIcons
                              .messageSquareText,
                      title:
                          'No visible reviews',
                      message:
                          'There are no public reviews to show right now.',
                    );
                  }

                  final ratingSum =
                      reviews.fold<int>(
                    0,
                    (
                      total,
                      review,
                    ) =>
                        total +
                        ((review['stars']
                                    as num?)
                                ?.toInt() ??
                            0),
                  );

                  final visibleAverage =
                      ratingSum /
                          reviews.length;

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
                      _SummaryCard(
                        average:
                            visibleAverage,
                        count:
                            reviews.length,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Client reviews',
                        style:
                            AppText.heading(
                          size: 18,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ...reviews.map(
                        (review) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom:
                                10,
                          ),
                          child:
                              _ReviewCard(
                            review:
                                review,
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
    required this.workerName,
    required this.onBack,
  });

  final String workerName;
  final VoidCallback onBack;

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
              onTap:
                  onBack,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child:
                  const SizedBox(
                width: 44,
                height: 44,
                child:
                    Center(
                  child:
                      Icon(
                    LucideIcons
                        .arrowLeft,
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
                  'Reviews',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                Text(
                  workerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
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
        ],
      ),
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

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
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child:
                const Icon(
              LucideIcons.star,
              color:
                  AppColors.gold,
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
                  average
                      .toStringAsFixed(
                    1,
                  ),
                  style:
                      AppText.heading(
                    size: 24,
                    color:
                        Colors.white,
                  ),
                ),
                Text(
                  count == 1
                      ? '1 visible review'
                      : '$count visible reviews',
                  style:
                      AppText.body(
                    size: 10,
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

class _ReviewCard
    extends StatelessWidget {
  const _ReviewCard({
    required this.review,
  });

  final Map<String, dynamic>
      review;

  @override
  Widget build(
    BuildContext context,
  ) {
    final stars =
        (review['stars'] as num?)
                ?.toInt() ??
            0;

    final comment =
        review['comment']
                ?.toString()
                .trim() ??
            '';

    final createdAt =
        review['createdAt'];

    String dateText = '';

    if (createdAt is Timestamp) {
      final date =
          createdAt.toDate();

      dateText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Container(
      padding:
          const EdgeInsets.all(
        16,
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
              Row(
                children:
                    List.generate(
                  5,
                  (index) =>
                      Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 2,
                    ),
                    child:
                        Icon(
                      LucideIcons.star,
                      size: 15,
                      color:
                          index <
                                  stars
                              ? AppColors.gold
                              : AppColors.line,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (dateText
                  .isNotEmpty)
                Text(
                  dateText,
                  style:
                      AppText.body(
                    size: 9,
                    color:
                        AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            comment.isEmpty
                ? 'No written comment.'
                : comment,
            style:
                AppText.body(
              size: 11.5,
              color:
                  AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState
    extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Container(
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
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    AppColors.muted,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style:
                    AppText.heading(
                  size: 17,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                message,
                textAlign:
                    TextAlign.center,
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
      ),
    );
  }
}
