import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/application_service.dart';
import '../services/chat_service.dart';
import '../services/job_service.dart';
import '../services/profile_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/report_dialog.dart';

import 'chat_screen.dart';

class FindJobsScreen extends StatelessWidget {
  const FindJobsScreen({
    super.key,
    this.bestMatchesOnly = false,
  });

  final bool bestMatchesOnly;

  @override
  Widget build(BuildContext context) {
    final jobService = JobService();
    final profileService = ProfileService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FindJobsHeader(
              bestMatchesOnly: bestMatchesOnly,
            ),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: profileService.getProfileStream(),
                builder: (
                  context,
                  profileSnapshot,
                ) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _LoadingState();
                  }

                  final profile = profileSnapshot.data;

                  final rawWorker =
                      profile?['workerProfile'];

                  final workerProfile =
                      rawWorker is Map
                          ? Map<String, dynamic>.from(
                              rawWorker,
                            )
                          : <String, dynamic>{};

                  final profileReady =
                      profile?['workerProfileComplete'] ==
                          true;

                  return StreamBuilder<
                      List<Map<String, dynamic>>>(
                    stream: jobService.getOpenJobs(),
                    builder: (
                      context,
                      jobSnapshot,
                    ) {
                      if (jobSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const _LoadingState();
                      }

                      if (jobSnapshot.hasError) {
                        return _ErrorState(
                          message:
                              jobSnapshot.error.toString(),
                        );
                      }

                      final jobs =
                          jobSnapshot.data ?? [];

                      if (jobs.isEmpty) {
                        return _EmptyJobsState(
                          bestMatchesOnly:
                              bestMatchesOnly,
                        );
                      }

                      final matchedJobs =
                          jobs.map(
                        (job) {
                          final match =
                              _calculateMatch(
                            job: job,
                            profile: profile,
                            workerProfile:
                                workerProfile,
                          );

                          return _MatchedJob(
                            job: job,
                            match: match,
                          );
                        },
                      ).toList();

                      matchedJobs.sort(
                        (a, b) {
                          final score =
                              b.match.total.compareTo(
                            a.match.total,
                          );

                          if (score != 0) {
                            return score;
                          }

                          final aTime =
                              a.job['createdAt']
                                  as Timestamp?;

                          final bTime =
                              b.job['createdAt']
                                  as Timestamp?;

                          if (aTime == null &&
                              bTime == null) {
                            return 0;
                          }

                          if (aTime == null) {
                            return 1;
                          }

                          if (bTime == null) {
                            return -1;
                          }

                          return bTime.compareTo(
                            aTime,
                          );
                        },
                      );

                      final visibleJobs =
                          bestMatchesOnly
                              ? matchedJobs
                                  .where(
                                    (item) =>
                                        item.match.total >=
                                            60 &&
                                        item.match.available,
                                  )
                                  .toList()
                              : matchedJobs;

                      if (visibleJobs.isEmpty) {
                        return _EmptyJobsState(
                          bestMatchesOnly:
                              bestMatchesOnly,
                        );
                      }

                      return ListView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          22,
                          20,
                          40,
                        ),
                        children: [
                          if (!profileReady)
                            const _ProfileWarning(),

                          if (!profileReady)
                            const SizedBox(
                              height: 16,
                            ),

                          _ResultSummary(
                            count:
                                visibleJobs.length,
                            bestMatchesOnly:
                                bestMatchesOnly,
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          ...visibleJobs.map(
                            (item) => Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 14,
                              ),
                              child: _JobCard(
                                job: item.job,
                                match: item.match,
                              ),
                            ),
                          ),
                        ],
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
}

class _FindJobsHeader extends StatelessWidget {
  const _FindJobsHeader({
    required this.bestMatchesOnly,
  });

  final bool bestMatchesOnly;

  @override
  Widget build(BuildContext context) {
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
                Navigator.pop(context);
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
                  bestMatchesOnly
                      ? 'Best matches'
                      : 'Find jobs',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  bestMatchesOnly
                      ? 'Strong opportunities selected for your profile'
                      : 'Browse all open opportunities',
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
            child: Icon(
              bestMatchesOnly
                  ? LucideIcons.sparkles
                  : LucideIcons.search,
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

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.count,
    required this.bestMatchesOnly,
  });

  final int count;
  final bool bestMatchesOnly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                bestMatchesOnly
                    ? '$count best ${count == 1 ? 'match' : 'matches'}'
                    : '$count open ${count == 1 ? 'job' : 'jobs'}',
                style:
                    AppText.heading(
                  size: 18,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                bestMatchesOnly
                    ? 'Only 60%+ matches with a fitting schedule.'
                    : 'All open jobs, ranked by match score.',
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
          child: Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 13,
                color:
                    AppColors.ink,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                bestMatchesOnly
                    ? 'BEST'
                    : 'RANKED',
                style:
                    AppText.label(
                  size: 8.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileWarning extends StatelessWidget {
  const _ProfileWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 18,
            color:
                AppColors.ink,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Text(
              'Complete your worker profile for accurate skills, availability and location matching.',
              style:
                  AppText.body(
                size: 11.5,
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

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.match,
  });

  final Map<String, dynamic> job;
  final _MatchBreakdown match;

  @override
  Widget build(BuildContext context) {
    final title =
        job['title']?.toString() ??
            'Untitled job';

    final category =
        job['category']?.toString() ??
            'Job';

    final location =
        job['location']?.toString() ??
            'Location not specified';

    final startTime =
        job['startTime']?.toString() ??
            '';

    final duration =
        (job['durationHours']
                    as num?)
                ?.toInt() ??
            0;

    final budget =
        (job['budget']
                    as num?)
                ?.toDouble() ??
            0;

    final workDate =
        job['workDate']
            as Timestamp?;

    final dateText =
        workDate == null
            ? 'Date not specified'
            : _formatDate(
                workDate.toDate(),
              );

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
            job,
            match,
          );
        },
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            18,
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
                    width: 10,
                  ),

                  _MatchBadge(
                    score:
                        match.total,
                  ),
                ],
              ),

              const SizedBox(
                height: 17,
              ),

              _InfoRow(
                icon:
                    LucideIcons.mapPin,
                value:
                    location,
              ),

              const SizedBox(
                height: 8,
              ),

              _InfoRow(
                icon:
                    LucideIcons.calendar,
                value:
                    '$dateText • $startTime',
              ),

              const SizedBox(
                height: 8,
              ),

              _InfoRow(
                icon:
                    LucideIcons.clock3,
                value:
                    '$duration ${duration == 1 ? 'hour' : 'hours'}',
              ),

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
                    '৳${_money(budget)}',
                    style:
                        AppText.heading(
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    match.available
                        ? 'Schedule fits'
                        : 'Schedule conflict',
                    style:
                        AppText.label(
                      size: 9,
                      color:
                          match.available
                              ? AppColors.success
                              : AppColors.muted,
                    ),
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 17,
                    color:
                        AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({
    required this.score,
  });

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
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
      child: Column(
        children: [
          Text(
            '$score%',
            style:
                AppText.heading(
              size: 13,
            ),
          ),
          Text(
            'MATCH',
            style:
                AppText.label(
              size: 6.5,
              color:
                  AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            value,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
          CircularProgressIndicator(
        strokeWidth: 2,
        color:
            AppColors.ink,
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState({
    required this.bestMatchesOnly,
  });

  final bool bestMatchesOnly;

  @override
  Widget build(BuildContext context) {
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
            PremiumIconBox(
              icon:
                  bestMatchesOnly
                      ? LucideIcons.sparkles
                      : LucideIcons.search,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              bestMatchesOnly
                  ? 'No strong matches yet'
                  : 'No open jobs',
              style:
                  AppText.heading(
                size: 19,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              bestMatchesOnly
                  ? 'Complete your profile and availability, or check again when new jobs are posted.'
                  : 'New opportunities will appear here when clients post jobs.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Text(
          'Unable to load jobs.\n$message',
          textAlign:
              TextAlign.center,
          style:
              AppText.body(
            size: 12,
          ),
        ),
      ),
    );
  }
}

class _MatchedJob {
  const _MatchedJob({
    required this.job,
    required this.match,
  });

  final Map<String, dynamic> job;
  final _MatchBreakdown match;
}

class _MatchBreakdown {
  const _MatchBreakdown({
    required this.skills,
    required this.availability,
    required this.location,
    required this.rating,
    required this.experience,
    required this.available,
  });

  final int skills;
  final int availability;
  final int location;
  final int rating;
  final int experience;
  final bool available;

  int get total =>
      skills +
      availability +
      location +
      rating +
      experience;
}

_MatchBreakdown _calculateMatch({
  required Map<String, dynamic> job,
  required Map<String, dynamic>? profile,
  required Map<String, dynamic>
      workerProfile,
}) {
  final skillScore =
      _calculateSkillScore(
    job,
    workerProfile,
  );

  final availabilityMatched =
      _matchesAvailability(
    job,
    workerProfile,
  );

  final availabilityScore =
      availabilityMatched
          ? 25
          : 0;

  final locationScore =
      _calculateLocationScore(
    job['location']
            ?.toString() ??
        '',
    profile?['location']
            ?.toString() ??
        '',
  );

  final ratingScore =
      _calculateRatingScore(
    workerProfile,
  );

  final experienceScore =
      _calculateExperienceScore(
    workerProfile,
  );

  return _MatchBreakdown(
    skills:
        skillScore,
    availability:
        availabilityScore,
    location:
        locationScore,
    rating:
        ratingScore,
    experience:
        experienceScore,
    available:
        availabilityMatched,
  );
}

int _calculateSkillScore(
  Map<String, dynamic> job,
  Map<String, dynamic> worker,
) {
  final rawRequired =
      job['requiredSkills'];

  final requiredSkills =
      rawRequired is List
          ? rawRequired
              .map(
                (item) => _normalize(
                  item.toString(),
                ),
              )
              .where(
                (item) =>
                    item.isNotEmpty,
              )
              .toSet()
          : <String>{};

  final rawWorkerSkills =
      worker['skills'];

  final workerSkills =
      rawWorkerSkills is List
          ? rawWorkerSkills
              .map(
                (item) => _normalize(
                  item.toString(),
                ),
              )
              .where(
                (item) =>
                    item.isNotEmpty,
              )
              .toSet()
          : <String>{};

  final jobCategory =
      _normalize(
    job['category']
            ?.toString() ??
        '',
  );

  final rawCategories =
      worker['categories'];

  final workerCategories =
      rawCategories is List
          ? rawCategories
              .map(
                (item) => _normalize(
                  item.toString(),
                ),
              )
              .toSet()
          : <String>{};

  double skillRatio = 0;

  if (requiredSkills.isEmpty) {
    skillRatio =
        workerCategories.contains(
          jobCategory,
        )
            ? 1
            : 0;
  } else {
    int matches = 0;

    for (final required
        in requiredSkills) {
      final matched =
          workerSkills.any(
        (workerSkill) =>
            workerSkill == required ||
            workerSkill.contains(
              required,
            ) ||
            required.contains(
              workerSkill,
            ),
      );

      if (matched) {
        matches++;
      }
    }

    final directSkillRatio =
        matches /
            requiredSkills.length;

    final categoryRatio =
        workerCategories.contains(
          jobCategory,
        )
            ? 1.0
            : 0.0;

    skillRatio =
        directSkillRatio * 0.75 +
            categoryRatio * 0.25;
  }

  return (40 *
          skillRatio.clamp(
            0.0,
            1.0,
          ))
      .round();
}

bool _matchesAvailability(
  Map<String, dynamic> job,
  Map<String, dynamic> worker,
) {
  final accepting =
      worker['acceptingJobs'];

  final oldAvailable =
      worker['isAvailable'];

  final acceptingJobs =
      accepting is bool
          ? accepting
          : oldAvailable is bool
              ? oldAvailable
              : false;

  if (!acceptingJobs) {
    return false;
  }

  final workTimestamp =
      job['workDate'];

  if (workTimestamp
      is! Timestamp) {
    return false;
  }

  final jobDate =
      workTimestamp.toDate();

  final weekday =
      _weekdayName(
    jobDate.weekday,
  );

  final rawAvailability =
      worker['availability'];

  if (rawAvailability
      is! Map) {
    return false;
  }

  final rawSlots =
      rawAvailability[weekday];

  if (rawSlots is! List ||
      rawSlots.isEmpty) {
    return false;
  }

  final startTime =
      job['startTime']
              ?.toString() ??
          '';

  final jobStart =
      _parseTimeToMinutes(
    startTime,
  );

  if (jobStart == null) {
    return false;
  }

  final durationHours =
      (job['durationHours']
                  as num?)
              ?.toDouble() ??
          0;

  if (durationHours <= 0) {
    return false;
  }

  final jobEnd =
      jobStart +
          (durationHours * 60)
              .round();

  for (final rawSlot
      in rawSlots) {
    if (rawSlot is! Map) {
      continue;
    }

    final start =
        rawSlot['startMinutes'];

    final end =
        rawSlot['endMinutes'];

    if (start is num &&
        end is num) {
      final slotStart =
          start.toInt();

      final slotEnd =
          end.toInt();

      if (jobStart >=
              slotStart &&
          jobEnd <=
              slotEnd) {
        return true;
      }
    }
  }

  return false;
}

int _calculateLocationScore(
  String jobLocation,
  String workerLocation,
) {
  final job =
      _normalize(
    jobLocation,
  );

  final worker =
      _normalize(
    workerLocation,
  );

  if (job.isEmpty ||
      worker.isEmpty) {
    return 0;
  }

  if (job == worker ||
      job.contains(worker) ||
      worker.contains(job)) {
    return 15;
  }

  final jobWords =
      job
          .split(' ')
          .where(
            (word) =>
                word.length > 2,
          )
          .toSet();

  final workerWords =
      worker
          .split(' ')
          .where(
            (word) =>
                word.length > 2,
          )
          .toSet();

  if (jobWords.isEmpty ||
      workerWords.isEmpty) {
    return 0;
  }

  final common =
      jobWords
          .intersection(
            workerWords,
          )
          .length;

  final maxWords =
      max(
    jobWords.length,
    workerWords.length,
  );

  final ratio =
      common / maxWords;

  return (15 *
          ratio.clamp(
            0.0,
            1.0,
          ))
      .round();
}

int _calculateRatingScore(
  Map<String, dynamic> worker,
) {
  final rating =
      (worker['rating']
                  as num?)
              ?.toDouble() ??
          0;

  final reviews =
      (worker['reviewCount']
                  as num?)
              ?.toInt() ??
          0;

  if (reviews == 0) {
    return 5;
  }

  final ratio =
      (rating / 5).clamp(
    0.0,
    1.0,
  );

  return (10 * ratio)
      .round();
}

int _calculateExperienceScore(
  Map<String, dynamic> worker,
) {
  final years =
      (worker['experienceYears']
                  as num?)
              ?.toDouble() ??
          0;

  final ratio =
      (years / 5).clamp(
    0.0,
    1.0,
  );

  return (10 * ratio)
      .round();
}

String _normalize(
  String value,
) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(
        RegExp(
          r'[^a-z0-9]+',
        ),
        ' ',
      )
      .replaceAll(
        RegExp(
          r'\s+',
        ),
        ' ',
      )
      .trim();
}

String _weekdayName(
  int weekday,
) {
  switch (weekday) {
    case DateTime.monday:
      return 'monday';

    case DateTime.tuesday:
      return 'tuesday';

    case DateTime.wednesday:
      return 'wednesday';

    case DateTime.thursday:
      return 'thursday';

    case DateTime.friday:
      return 'friday';

    case DateTime.saturday:
      return 'saturday';

    case DateTime.sunday:
      return 'sunday';

    default:
      return '';
  }
}

int? _parseTimeToMinutes(
  String value,
) {
  final text =
      value
          .trim()
          .toUpperCase();

  if (text.isEmpty) {
    return null;
  }

  final twelveHour =
      RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  ).firstMatch(
    text,
  );

  if (twelveHour != null) {
    int hour =
        int.parse(
      twelveHour.group(1)!,
    );

    final minute =
        int.parse(
      twelveHour.group(2)!,
    );

    final period =
        twelveHour.group(3)!;

    if (hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    if (period == 'AM') {
      if (hour == 12) {
        hour = 0;
      }
    } else {
      if (hour != 12) {
        hour += 12;
      }
    }

    return hour * 60 +
        minute;
  }

  final twentyFourHour =
      RegExp(
    r'^(\d{1,2}):(\d{2})$',
  ).firstMatch(
    text,
  );

  if (twentyFourHour != null) {
    final hour =
        int.parse(
      twentyFourHour.group(1)!,
    );

    final minute =
        int.parse(
      twentyFourHour.group(2)!,
    );

    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return hour * 60 +
        minute;
  }

  return null;
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

String _money(
  double amount,
) {
  if (amount ==
      amount.roundToDouble()) {
    return amount
        .toInt()
        .toString();
  }

  return amount
      .toStringAsFixed(
    2,
  );
}

String _cleanError(
  Object error,
) {
  final text =
      error.toString();

  if (text.startsWith(
    'Exception: ',
  )) {
    return text.substring(
      11,
    );
  }

  if (text.contains(
    'permission-denied',
  )) {
    return 'Permission denied. Please try again.';
  }

  return text;
}

Future<void> _showJobDetails(
  BuildContext context,
  Map<String, dynamic> job,
  _MatchBreakdown match,
) async {
  final applicationService =
      ApplicationService();

  final chatService =
      ChatService();

  final rootContext =
      context;

  final jobId =
      job['jobId']
              ?.toString()
              .trim() ??
          '';

  final clientId =
      job['clientId']
              ?.toString()
              .trim() ??
          '';

  if (jobId.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to identify this job.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );

    return;
  }

  bool alreadyApplied = false;

  try {
    alreadyApplied =
        await applicationService
            .hasApplied(
      jobId,
    );
  } catch (_) {
    alreadyApplied = false;
  }

  if (!context.mounted) {
    return;
  }

  final title =
      job['title']
              ?.toString() ??
          'Untitled job';

  final category =
      job['category']
              ?.toString() ??
          'Job';

  final description =
      job['description']
              ?.toString() ??
          'No description provided.';

  final location =
      job['location']
              ?.toString() ??
          'Not specified';

  final clientEmail =
      job['clientEmail']
              ?.toString()
              .trim() ??
          '';

  final fallbackClientName =
      job['clientName']
              ?.toString()
              .trim() ??
          '';

  final jobStatus =
      job['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
          'open';

  final budget =
      (job['budget'] as num?)
              ?.toDouble() ??
          0;

  final start =
      job['startTime']
              ?.toString() ??
          '';

  final duration =
      (job['durationHours']
                  as num?)
              ?.toInt() ??
          0;

  final rawSkills =
      job['requiredSkills'];

  final skills =
      rawSkills is List
          ? rawSkills
              .map(
                (item) =>
                    item.toString(),
              )
              .toList()
          : <String>[];

  final timestamp =
      job['workDate'];

  final date =
      timestamp is Timestamp
          ? _formatDate(
              timestamp.toDate(),
            )
          : 'Not specified';

  await showModalBottomSheet(
    context: context,
    isScrollControlled:
        true,
    backgroundColor:
        Colors.transparent,
    builder: (
      sheetContext,
    ) {
      bool applied =
          alreadyApplied;

      bool applying =
          false;

      bool openingChat =
          false;

      return StatefulBuilder(
        builder: (
          context,
          setSheetState,
        ) {
          Future<void>
              messageClient() async {
            if (openingChat) {
              return;
            }

            if (clientId.isEmpty) {
              ScaffoldMessenger.of(
                rootContext,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Unable to identify the client.',
                  ),
                  behavior:
                      SnackBarBehavior
                          .floating,
                ),
              );

              return;
            }

            setSheetState(
              () {
                openingChat = true;
              },
            );

            try {
              final conversation =
                  await chatService
                      .ensureConversation(
                jobId:
                    jobId,
              );

              String clientName =
                  fallbackClientName.isNotEmpty
                      ? fallbackClientName
                      : 'Client';

              String clientPhotoUrl =
                  '';

              try {
                final clientSnapshot =
                    await FirebaseFirestore
                        .instance
                        .collection(
                          'users',
                        )
                        .doc(
                          clientId,
                        )
                        .get();

                final clientData =
                    clientSnapshot
                        .data();

                final savedName =
                    clientData?['name']
                            ?.toString()
                            .trim() ??
                        '';

                final savedPhotoUrl =
                    clientData?['photoUrl']
                            ?.toString()
                            .trim() ??
                        '';

                if (savedName
                    .isNotEmpty) {
                  clientName =
                      savedName;
                } else if (clientEmail
                    .isNotEmpty) {
                  clientName =
                      clientEmail;
                }

                if (savedPhotoUrl
                    .isNotEmpty) {
                  clientPhotoUrl =
                      savedPhotoUrl;
                }
              } catch (_) {
                if (clientName ==
                        'Client' &&
                    clientEmail
                        .isNotEmpty) {
                  clientName =
                      clientEmail;
                }
              }

              if (!rootContext
                  .mounted) {
                return;
              }

              Navigator.pop(
                sheetContext,
              );

              await Navigator.push(
                rootContext,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(
                    conversationId:
                        conversation[
                                'conversationId']
                            .toString(),
                    jobTitle:
                        conversation[
                                'jobTitle']
                            .toString(),
                    otherUserName:
                        clientName,
                    otherUserPhotoUrl:
                        clientPhotoUrl,
                  ),
                ),
              );
            } catch (error) {
              if (!rootContext
                  .mounted) {
                return;
              }

              if (context.mounted) {
                setSheetState(
                  () {
                    openingChat =
                        false;
                  },
                );
              }

              ScaffoldMessenger.of(
                rootContext,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    _cleanError(
                      error,
                    ),
                  ),
                  behavior:
                      SnackBarBehavior
                          .floating,
                ),
              );
            }
          }

          Future<void>
              apply() async {
            if (applying ||
                applied) {
              return;
            }

            setSheetState(
              () {
                applying = true;
              },
            );

            try {
              final exists =
                  await applicationService
                      .hasApplied(
                jobId,
              );

              if (exists) {
                if (context.mounted) {
                  setSheetState(
                    () {
                      applied = true;
                      applying = false;
                    },
                  );
                }

                return;
              }

              await applicationService
                  .applyToJob(
                jobId:
                    jobId,
                matchScore:
                    match.total,
              );

              if (!context.mounted) {
                return;
              }

              setSheetState(
                () {
                  applied = true;
                  applying = false;
                },
              );

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Application submitted successfully.',
                  ),
                  behavior:
                      SnackBarBehavior
                          .floating,
                ),
              );
            } catch (e) {
              if (!context.mounted) {
                return;
              }

              setSheetState(
                () {
                  applying = false;
                },
              );

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    _cleanError(
                      e,
                    ),
                  ),
                  behavior:
                      SnackBarBehavior
                          .floating,
                ),
              );
            }
          }

          return DraggableScrollableSheet(
            initialChildSize:
                0.88,
            minChildSize:
                0.55,
            maxChildSize:
                0.95,
            builder: (
              context,
              controller,
            ) {
              return Container(
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.background,
                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(
                      28,
                    ),
                  ),
                ),
                child: ListView(
                  controller:
                      controller,
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    20,
                    12,
                    20,
                    36,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width:
                            38,
                        height:
                            4,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .line,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          22,
                    ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    category
                                        .toUpperCase(),
                                    style:
                                        AppText.label(
                                      size:
                                          9,
                                      color:
                                          AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width:
                                        8,
                                  ),
                                  _JobStatusChip(
                                    status:
                                        jobStatus,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    7,
                              ),

                              Text(
                                title,
                                style:
                                    AppText.heading(
                                  size:
                                      23,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width:
                              12,
                        ),

                        _MatchBadge(
                          score:
                              match.total,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          20,
                    ),

                    _ClientOverviewCard(
                      clientId:
                          clientId,
                      fallbackName:
                          fallbackClientName,
                      fallbackEmail:
                          clientEmail,
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    Text(
                      'Job overview',
                      style:
                          AppText.heading(
                        size:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    _DetailCard(
                      icon:
                          LucideIcons
                              .mapPin,
                      title:
                          'Location',
                      value:
                          location,
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    _DetailCard(
                      icon:
                          LucideIcons
                              .calendar,
                      title:
                          'Schedule',
                      value:
                          '$date • $start • '
                          '$duration '
                          '${duration == 1 ? 'hour' : 'hours'}',
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    _DetailCard(
                      icon:
                          LucideIcons
                              .briefcase,
                      title:
                          'Budget',
                      value:
                          '৳${_money(budget)}',
                    ),

                    const SizedBox(
                      height:
                          26,
                    ),

                    Text(
                      'Match breakdown',
                      style:
                          AppText.heading(
                        size:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    _ScoreRow(
                      label:
                          'Skills',
                      score:
                          match.skills,
                      maximum:
                          40,
                    ),

                    _ScoreRow(
                      label:
                          'Availability',
                      score:
                          match.availability,
                      maximum:
                          25,
                    ),

                    _ScoreRow(
                      label:
                          'Location',
                      score:
                          match.location,
                      maximum:
                          15,
                    ),

                    _ScoreRow(
                      label:
                          'Rating',
                      score:
                          match.rating,
                      maximum:
                          10,
                    ),

                    _ScoreRow(
                      label:
                          'Experience',
                      score:
                          match.experience,
                      maximum:
                          10,
                    ),

                    const SizedBox(
                      height:
                          26,
                    ),

                    Text(
                      'Required skills',
                      style:
                          AppText.heading(
                        size:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    if (skills.isEmpty)
                      Text(
                        'No specific skills listed.',
                        style:
                            AppText.body(
                          size:
                              12,
                          color:
                              AppColors.muted,
                        ),
                      )
                    else
                      Wrap(
                        spacing:
                            7,
                        runSpacing:
                            7,
                        children:
                            skills.map(
                          (
                            skill,
                          ) {
                            return Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    10,
                                vertical:
                                    7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    AppColors
                                        .goldSoft,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  30,
                                ),
                              ),
                              child:
                                  Text(
                                skill,
                                style:
                                    AppText.label(
                                  size:
                                      9,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                    const SizedBox(
                      height:
                          26,
                    ),

                    Text(
                      'Job description',
                      style:
                          AppText.heading(
                        size:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height:
                          9,
                    ),

                    Text(
                      description,
                      style:
                          AppText.body(
                        size:
                            12.5,
                        color:
                            AppColors
                                .inkSoft,
                      ),
                    ),

                    const SizedBox(
                      height:
                          28,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        15,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            match.available
                                ? AppColors
                                    .goldSoft
                                : AppColors
                                    .surface,
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                        border:
                            Border.all(
                          color:
                              AppColors
                                  .line,
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          Icon(
                            match.available
                                ? LucideIcons
                                    .circleCheck
                                : LucideIcons
                                    .clock3,
                            size:
                                17,
                            color:
                                match.available
                                    ? AppColors
                                        .success
                                    : AppColors
                                        .gold,
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Expanded(
                            child:
                                Text(
                              match.available
                                  ? 'This job fits your saved availability.'
                                  : 'This job conflicts with your saved availability. You can still apply if you are able to work at this time.',
                              style:
                                  AppText.body(
                                size:
                                    11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          18,
                    ),

                    // --------------------------------
                    // MESSAGE CLIENT
                    // --------------------------------

                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          52,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            openingChat
                                ? null
                                : messageClient,
                        icon:
                            openingChat
                                ? const SizedBox(
                                    width:
                                        18,
                                    height:
                                        18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          AppColors.ink,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons
                                        .messageCircle,
                                    size:
                                        18,
                                  ),
                        label:
                            Text(
                          openingChat
                              ? 'Opening Chat...'
                              : 'Message Client',
                          style:
                              AppText.label(
                            size:
                                12,
                          ),
                        ),
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
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          50,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            () async {
                          final submitted =
                              await showReportDialog(
                            context,
                            targetType:
                                'job',
                            targetId:
                                jobId,
                            targetTitle:
                                title,
                            targetOwnerId:
                                clientId,
                          );

                          if (!rootContext
                              .mounted) {
                            return;
                          }

                          if (submitted) {
                            ScaffoldMessenger.of(
                              rootContext,
                            ).showSnackBar(
                              const SnackBar(
                                content:
                                    Text(
                                  'Report submitted for admin review.',
                                ),
                                behavior:
                                    SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon:
                            const Icon(
                          LucideIcons.flag,
                          size:
                              17,
                        ),
                        label:
                            Text(
                          'Report Job',
                          style:
                              AppText.label(
                            size:
                                11.5,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.inkSoft,
                          side:
                              const BorderSide(
                            color:
                                AppColors.line,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    // --------------------------------
                    // APPLY
                    // --------------------------------

                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          54,
                      child:
                          ElevatedButton(
                        onPressed:
                            applied ||
                                    applying
                                ? null
                                : apply,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              applied
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .ink,
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              applied
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .inkSoft,
                          disabledForegroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                            applying
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        applied
                                            ? LucideIcons
                                                .circleCheck
                                            : LucideIcons
                                                .send,
                                        size:
                                            18,
                                      ),
                                      const SizedBox(
                                        width:
                                            9,
                                      ),
                                      Text(
                                        applied
                                            ? 'Applied'
                                            : 'Apply Now',
                                        style:
                                            AppText.label(
                                          color:
                                              Colors.white,
                                          size:
                                              12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),

                    if (applied) ...[
                      const SizedBox(
                        height:
                            10,
                      ),
                      Center(
                        child: Text(
                          'Your application is pending review.',
                          style:
                              AppText.body(
                            size:
                                10.5,
                            color:
                                AppColors
                                    .muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}


class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized =
        status.trim().toLowerCase();

    final isOpen =
        normalized.isEmpty ||
            normalized == 'open';

    final label =
        isOpen
            ? 'OPEN'
            : normalized
                .replaceAll('_', ' ')
                .toUpperCase();

    final color =
        isOpen
            ? AppColors.success
            : AppColors.muted;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(
              color: color,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            label,
            style:
                AppText.label(
              size: 7.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientOverviewCard
    extends StatelessWidget {
  const _ClientOverviewCard({
    required this.clientId,
    required this.fallbackName,
    required this.fallbackEmail,
  });

  final String clientId;
  final String fallbackName;
  final String fallbackEmail;

  @override
  Widget build(BuildContext context) {
    if (clientId.isEmpty) {
      return _buildCard(
        name:
            fallbackName.isNotEmpty
                ? fallbackName
                : 'Client',
        email:
            fallbackEmail,
        photoUrl:
            '',
      );
    }

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(clientId)
              .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        final data =
            snapshot.data?.data();

        final liveName =
            data?['name']
                    ?.toString()
                    .trim() ??
                '';

        final liveEmail =
            data?['email']
                    ?.toString()
                    .trim() ??
                '';

        final photoUrl =
            data?['photoUrl']
                    ?.toString()
                    .trim() ??
                '';

        final name =
            liveName.isNotEmpty
                ? liveName
                : fallbackName.isNotEmpty
                    ? fallbackName
                    : 'Client';

        final email =
            liveEmail.isNotEmpty
                ? liveEmail
                : fallbackEmail;

        return _buildCard(
          name: name,
          email: email,
          photoUrl: photoUrl,
        );
      },
    );
  }

  Widget _buildCard({
    required String name,
    required String email,
    required String photoUrl,
  }) {
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
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
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
            width: 46,
            height: 46,
            clipBehavior:
                Clip.antiAlias,
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
                photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        width:
                            double.infinity,
                        height:
                            double.infinity,
                        fit:
                            BoxFit.cover,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Center(
                            child:
                                Text(
                              _jobInitials(
                                name,
                              ),
                              style:
                                  AppText.heading(
                                size:
                                    13,
                              ),
                            ),
                          );
                        },
                      )
                    : Text(
                        _jobInitials(
                          name,
                        ),
                        style:
                            AppText.heading(
                          size:
                              13,
                        ),
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
                  'POSTED BY',
                  style:
                      AppText.label(
                    size:
                        7.5,
                    color:
                        AppColors.muted,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      AppText.heading(
                    size:
                        14,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        AppText.body(
                      size:
                          9.5,
                      color:
                          AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          const Icon(
            LucideIcons.badgeCheck,
            size: 17,
            color:
                AppColors.gold,
          ),
        ],
      ),
    );
  }
}

String _jobInitials(
  String name,
) {
  final parts =
      name
          .trim()
          .split(
            RegExp(
              r'\s+',
            ),
          )
          .where(
            (part) =>
                part.isNotEmpty,
          )
          .toList();

  if (parts.isEmpty) {
    return 'C';
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          17,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                AppColors.gold,
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
                  title.toUpperCase(),
                  style:
                      AppText.label(
                    size: 7.5,
                    color:
                        AppColors.muted,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      AppText.heading(
                    size: 12.5,
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.maximum,
  });

  final String label;
  final int score;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final ratio =
        maximum == 0
            ? 0.0
            : score / maximum;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  AppText.body(
                size: 11,
              ),
            ),
          ),

          Expanded(
            child:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
              child:
                  LinearProgressIndicator(
                value:
                    ratio.clamp(
                  0.0,
                  1.0,
                ),
                minHeight:
                    6,
                backgroundColor:
                    AppColors.line,
                color:
                    AppColors.gold,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            width: 42,
            child: Text(
              '$score/$maximum',
              textAlign:
                  TextAlign.right,
              style:
                  AppText.label(
                size: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}