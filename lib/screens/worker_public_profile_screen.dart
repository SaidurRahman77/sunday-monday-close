import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/chat_service.dart';
import '../services/job_invitation_service.dart';
import '../services/review_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/report_dialog.dart';
import 'chat_screen.dart';
import 'worker_public_reviews_screen.dart';

class WorkerPublicProfileScreen extends StatelessWidget {
  const WorkerPublicProfileScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    this.applicationStatus,
    this.onAccept,
    this.onReject,
  });

  final String workerId;
  final String workerName;
  final String? applicationStatus;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;

  bool get _canMessage {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    return currentUser.uid != workerId;
  }

  bool get _canInvite {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    if (currentUser.uid == workerId) {
      return false;
    }

    if (applicationStatus != null) {
      return false;
    }

    return true;
  }

  void _showMessageSheet(
    BuildContext context, {
    required String workerName,
    required String photoUrl,
  }) {
    final parentContext =
        context;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _MessageWorkerSheet(
          workerId: workerId,
          workerName: workerName,
          photoUrl: photoUrl,
          jobsService:
              JobInvitationService(),
          chatService:
              ChatService(),
          parentContext:
              parentContext,
        );
      },
    );
  }

  void _showInviteSheet(
    BuildContext context, {
    required String workerName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _InviteToJobSheet(
          workerId: workerId,
          workerName: workerName,
          service: JobInvitationService(),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final reviewService =
        ReviewService();

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: FirebaseFirestore
              .instance
              .collection('users')
              .doc(workerId)
              .snapshots(),
          builder: (
            context,
            profileSnapshot,
          ) {
            if (profileSnapshot
                        .connectionState ==
                    ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const _LoadingState();
            }

            if (profileSnapshot.hasError) {
              return _ErrorState(
                message:
                    profileSnapshot.error
                        .toString(),
              );
            }

            final data =
                profileSnapshot.data?.data();

            if (data == null) {
              return const _ErrorState(
                message:
                    'Worker profile not found.',
              );
            }

            final rawWorkerProfile =
                data['workerProfile'];

            final workerProfile =
                rawWorkerProfile is Map
                    ? Map<String, dynamic>.from(
                        rawWorkerProfile,
                      )
                    : <String, dynamic>{};

            final rawName =
                data['name']
                        ?.toString()
                        .trim() ??
                    '';

            final name =
                rawName.isNotEmpty
                    ? rawName
                    : workerName;

            final email =
                data['email']
                        ?.toString()
                        .trim() ??
                    '';

            final phone =
                data['phone']
                        ?.toString()
                        .trim() ??
                    '';

            final location =
                data['location']
                        ?.toString()
                        .trim() ??
                    '';

            final bio =
                data['bio']
                        ?.toString()
                        .trim() ??
                    '';

            final photoUrl =
                data['photoUrl']
                        ?.toString()
                        .trim() ??
                    '';

            final experienceYears =
                (workerProfile[
                            'experienceYears']
                        as num?)
                    ?.toInt() ??
                0;

            final rating =
                (workerProfile['rating']
                            as num?)
                        ?.toDouble() ??
                    0.0;

            final reviewCount =
                (workerProfile[
                            'reviewCount']
                        as num?)
                    ?.toInt() ??
                0;

            final acceptingValue =
                workerProfile[
                    'acceptingJobs'];

            final oldAvailableValue =
                workerProfile[
                    'isAvailable'];

            final acceptingJobs =
                acceptingValue is bool
                    ? acceptingValue
                    : oldAvailableValue
                            is bool
                        ? oldAvailableValue
                        : false;

            final skills =
                _stringList(
              workerProfile['skills'],
            );

            final categories =
                _stringList(
              workerProfile['categories'],
            );

            final availability =
                _availabilityMap(
              workerProfile[
                  'availability'],
            );

            return Column(
              children: [
                _ProfileHeader(
                  workerName: name,
                ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      22,
                      20,
                      40,
                    ),
                    children: [
                      _HeroCard(
                        name: name,
                        photoUrl: photoUrl,
                        location: location,
                        experienceYears:
                            experienceYears,
                        acceptingJobs:
                            acceptingJobs,
                        rating: rating,
                        reviewCount:
                            reviewCount,
                      ),

                      if (_canMessage) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        _MessageActionCard(
                          workerName: name,
                          onTap: () {
                            _showMessageSheet(
                              context,
                              workerName: name,
                              photoUrl: photoUrl,
                            );
                          },
                        ),
                      ],

                      if (_canInvite) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        _InviteActionCard(
                          workerName: name,
                          acceptingJobs:
                              acceptingJobs,
                          onTap:
                              acceptingJobs
                                  ? () {
                                      _showInviteSheet(
                                        context,
                                        workerName:
                                            name,
                                      );
                                    }
                                  : null,
                        ),
                      ],

                      if (_canMessage) ...[
                        const SizedBox(
                          height: 10,
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
                                    'user',
                                targetId:
                                    workerId,
                                targetTitle:
                                    name,
                                targetOwnerId:
                                    workerId,
                              );

                              if (!context
                                  .mounted) {
                                return;
                              }

                              if (submitted) {
                                ScaffoldMessenger.of(
                                  context,
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
                              LucideIcons
                                  .flag,
                              size:
                                  17,
                            ),
                            label:
                                Text(
                              'Report Worker',
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
                      ],

                      const SizedBox(
                        height: 22,
                      ),

                      _SectionCard(
                        title: 'About',
                        icon:
                            LucideIcons
                                .userRound,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon:
                                  LucideIcons
                                      .mail,
                              label:
                                  'Email',
                              value:
                                  email.isEmpty
                                      ? 'Not provided'
                                      : email,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            _InfoRow(
                              icon:
                                  LucideIcons
                                      .phone,
                              label:
                                  'Phone',
                              value:
                                  phone.isEmpty
                                      ? 'Not provided'
                                      : phone,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            _InfoRow(
                              icon:
                                  LucideIcons
                                      .mapPin,
                              label:
                                  'Location',
                              value:
                                  location.isEmpty
                                      ? 'Not provided'
                                      : location,
                            ),
                            if (bio
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 16,
                              ),
                              const Divider(
                                height: 1,
                                color:
                                    AppColors
                                        .line,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Align(
                                alignment:
                                    Alignment
                                        .centerLeft,
                                child: Text(
                                  bio,
                                  style:
                                      AppText.body(
                                    size: 12,
                                    color:
                                        AppColors
                                            .inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _SectionCard(
                        title: 'Skills',
                        icon:
                            LucideIcons
                                .wrench,
                        child: _Tags(
                          values: skills,
                          emptyText:
                              'No skills added yet.',
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _SectionCard(
                        title:
                            'Work categories',
                        icon:
                            LucideIcons
                                .layoutGrid,
                        child: _Tags(
                          values:
                              categories,
                          emptyText:
                              'No categories selected yet.',
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _SectionCard(
                        title:
                            'Weekly availability',
                        icon:
                            LucideIcons
                                .calendarClock,
                        child:
                            _AvailabilityList(
                          availability:
                              availability,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      StreamBuilder<
                          List<
                              Map<String,
                                  dynamic>>>(
                        stream:
                            reviewService
                                .getWorkerReviews(
                          workerId:
                              workerId,
                        ),
                        builder: (
                          context,
                          reviewSnapshot,
                        ) {
                          final reviews =
                              (reviewSnapshot
                                          .data ??
                                      [])
                                  .where(
                                    (review) =>
                                        review[
                                                'isHidden'] !=
                                            true,
                                  )
                                  .toList();

                          return _SectionCard(
                            title:
                                'Client reviews',
                            icon:
                                LucideIcons.star,
                            trailing:
                                reviewCount > 0
                                    ? TextButton(
                                        onPressed:
                                            () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  WorkerPublicReviewsScreen(
                                                workerId:
                                                    workerId,
                                                workerName:
                                                    name,
                                              ),
                                            ),
                                          );
                                        },
                                        child:
                                            Text(
                                          'View all',
                                          style:
                                              AppText.label(
                                            size:
                                                10,
                                            color:
                                                AppColors.ink,
                                          ),
                                        ),
                                      )
                                    : null,
                            child:
                                _ReviewsPreview(
                              reviews:
                                  reviews,
                              rating:
                                  rating,
                              reviewCount:
                                  reviewCount,
                            ),
                          );
                        },
                      ),

                      if (applicationStatus !=
                          null) ...[
                        const SizedBox(
                          height: 18,
                        ),
                        _ApplicationActions(
                          status:
                              applicationStatus ??
                                  'pending',
                          onAccept:
                              onAccept,
                          onReject:
                              onReject,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageActionCard
    extends StatelessWidget {
  const _MessageActionCard({
    required this.workerName,
    required this.onTap,
  });

  final String workerName;
  final VoidCallback onTap;

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
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons
                        .messageCircle,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Message worker',
                      style:
                          AppText.heading(
                        size: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Choose one of your open jobs and start a conversation with $workerName before hiring.',
                      maxLines: 3,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(
                LucideIcons
                    .messageCircle,
                size: 16,
              ),
              label: Text(
                'Choose a job to message',
                style:
                    AppText.label(
                  size: 11.5,
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
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageWorkerSheet
    extends StatefulWidget {
  const _MessageWorkerSheet({
    required this.workerId,
    required this.workerName,
    required this.photoUrl,
    required this.jobsService,
    required this.chatService,
    required this.parentContext,
  });

  final String workerId;
  final String workerName;
  final String photoUrl;
  final JobInvitationService jobsService;
  final ChatService chatService;
  final BuildContext parentContext;

  @override
  State<_MessageWorkerSheet>
      createState() =>
          _MessageWorkerSheetState();
}

class _MessageWorkerSheetState
    extends State<_MessageWorkerSheet> {
  late Future<
      List<Map<String, dynamic>>>
      _jobsFuture;

  String? _selectedJobId;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();

    _jobsFuture =
        widget.jobsService
            .getMyOpenJobs();
  }

  Future<void> _openChat(
    List<Map<String, dynamic>>
        jobs,
  ) async {
    if (_openingChat ||
        _selectedJobId == null) {
      return;
    }

    final selectedJob =
        jobs.firstWhere(
      (job) =>
          job['jobId']
              ?.toString() ==
          _selectedJobId,
    );

    final jobTitle =
        selectedJob['title']
                ?.toString()
                .trim() ??
            'Job';

    setState(() {
      _openingChat = true;
    });

    try {
      final conversation =
          await widget.chatService
              .ensureConversation(
        jobId:
            _selectedJobId!,
        workerId:
            widget.workerId,
      );

      final conversationId =
          conversation[
                  'conversationId']
              ?.toString()
              .trim() ??
          '';

      final conversationJobTitle =
          conversation['jobTitle']
                  ?.toString()
                  .trim() ??
              '';

      if (conversationId.isEmpty) {
        throw Exception(
          'Unable to open conversation.',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 120,
        ),
      );

      if (!widget.parentContext
          .mounted) {
        return;
      }

      await Navigator.push(
        widget.parentContext,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(
            conversationId:
                conversationId,
            jobTitle:
                conversationJobTitle
                        .isNotEmpty
                    ? conversationJobTitle
                    : jobTitle,
            otherUserName:
                widget.workerName,
            otherUserPhotoUrl:
                widget.photoUrl,
          ),
        ),
      );
   } catch (error) {
  if (!mounted) {
    if (widget.parentContext.mounted) {
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(
              error,
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }

    return;
  }

  setState(() {
    _openingChat = false;
  });

  if (!widget.parentContext.mounted) {
    return;
  }

  ScaffoldMessenger.of(
    widget.parentContext,
  ).showSnackBar(
    SnackBar(
      content: Text(
        _friendlyError(
          error,
        ),
      ),
      behavior:
          SnackBarBehavior.floating,
    ),
  );
}
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottomPadding =
        MediaQuery.of(
          context,
        ).viewInsets.bottom;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        10,
        30,
        10,
        10,
      ),
      padding:
          EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + bottomPadding,
      ),
      constraints:
          BoxConstraints(
        maxHeight:
            MediaQuery.of(
                  context,
                ).size.height *
                0.82,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
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
                  10,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons
                        .messageCircle,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Message worker',
                      style:
                          AppText.heading(
                        size: 20,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      widget.workerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.body(
                        size: 11,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _openingChat
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },
                icon: const Icon(
                  LucideIcons.x,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Select one of your open jobs',
            style:
                AppText.heading(
              size: 14,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'The conversation will stay linked to the selected job.',
            style:
                AppText.body(
              size: 10,
              color:
                  AppColors.muted,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Flexible(
            child: FutureBuilder<
                List<
                    Map<String,
                        dynamic>>>(
              future:
                  _jobsFuture,
              builder: (
                context,
                jobSnapshot,
              ) {
                if (jobSnapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(
                        30,
                      ),
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors
                                .ink,
                      ),
                    ),
                  );
                }

                if (jobSnapshot.hasError) {
                  return _InviteSheetMessage(
                    icon:
                        LucideIcons
                            .triangleAlert,
                    title:
                        'Unable to load jobs',
                    message:
                        jobSnapshot.error
                            .toString(),
                  );
                }

                final jobs =
                    jobSnapshot.data ??
                        [];

                if (jobs.isEmpty) {
                  return const _InviteSheetMessage(
                    icon:
                        LucideIcons
                            .briefcase,
                    title:
                        'No open jobs',
                    message:
                        'Post a job first, then you can start a job-specific conversation with this worker.',
                  );
                }

                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Flexible(
                      child:
                          ListView.separated(
                        shrinkWrap: true,
                        itemCount:
                            jobs.length,
                        separatorBuilder:
                            (
                          context,
                          index,
                        ) =>
                                const SizedBox(
                          height: 9,
                        ),
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final job =
                              jobs[index];

                          final jobId =
                              job['jobId']
                                      ?.toString() ??
                                  '';

                          final selected =
                              _selectedJobId ==
                                  jobId;

                          return _MessageJobSelectionTile(
                            job: job,
                            selected:
                                selected,
                            onTap:
                                _openingChat
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _selectedJobId =
                                                jobId;
                                          },
                                        );
                                      },
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _openingChat ||
                                    _selectedJobId ==
                                        null
                                ? null
                                : () {
                                    _openChat(
                                      jobs,
                                    );
                                  },
                        icon:
                            _openingChat
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons
                                        .messageCircle,
                                    size: 16,
                                  ),
                        label: Text(
                          _openingChat
                              ? 'Opening chat...'
                              : 'Open chat',
                          style:
                              AppText.label(
                            size: 11.5,
                            color:
                                Colors.white,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .ink,
                          foregroundColor:
                              Colors
                                  .white,
                          disabledBackgroundColor:
                              AppColors
                                  .line,
                          disabledForegroundColor:
                              AppColors
                                  .muted,
                          elevation: 0,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
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
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageJobSelectionTile
    extends StatelessWidget {
  const _MessageJobSelectionTile({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic>
      job;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        job['title']
                ?.toString()
                .trim() ??
            'Untitled job';

    final category =
        job['category']
                ?.toString()
                .trim() ??
            'Job';

    final location =
        job['location']
                ?.toString()
                .trim() ??
            '';

    final budget =
        job['budget'];

    final budgetText =
        budget == null
            ? ''
            : budget.toString();

    return Material(
      color:
          selected
              ? AppColors
                  .goldSoft
              : AppColors
                  .surface,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
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
              18,
            ),
            border: Border.all(
              color:
                  selected
                      ? AppColors.gold
                      : AppColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? AppColors.ink
                          : AppColors
                              .background,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  selected
                      ? LucideIcons
                          .messageCircle
                      : LucideIcons
                          .briefcase,
                  size: 16,
                  color:
                      selected
                          ? Colors.white
                          : AppColors
                              .ink,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      category,
                      style:
                          AppText.body(
                        size: 9.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                    if (location
                            .isNotEmpty ||
                        budgetText
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        [
                          if (location
                              .isNotEmpty)
                            location,
                          if (budgetText
                              .isNotEmpty)
                            'Budget: $budgetText',
                        ].join(
                          ' • ',
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppText.body(
                          size: 9,
                          color:
                              AppColors
                                  .muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? AppColors.ink
                          : AppColors
                              .background,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  selected
                      ? 'SELECTED'
                      : 'SELECT',
                  style:
                      AppText.label(
                    size: 7.5,
                    color:
                        selected
                            ? Colors
                                .white
                            : AppColors
                                .ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteActionCard
    extends StatelessWidget {
  const _InviteActionCard({
    required this.workerName,
    required this.acceptingJobs,
    required this.onTap,
  });

  final String workerName;
  final bool acceptingJobs;
  final VoidCallback? onTap;

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
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons.send,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Invite to a job',
                      style:
                          AppText.heading(
                        size: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      acceptingJobs
                          ? 'Choose which open job you want to invite $workerName to.'
                          : '$workerName is not accepting jobs right now.',
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(
                LucideIcons.send,
                size: 16,
              ),
              label: Text(
                acceptingJobs
                    ? 'Choose a job'
                    : 'Not available',
                style:
                    AppText.label(
                  size: 11.5,
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
                    AppColors.line,
                disabledForegroundColor:
                    AppColors.muted,
                elevation: 0,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteToJobSheet
    extends StatefulWidget {
  const _InviteToJobSheet({
    required this.workerId,
    required this.workerName,
    required this.service,
  });

  final String workerId;
  final String workerName;
  final JobInvitationService service;

  @override
  State<_InviteToJobSheet>
      createState() =>
          _InviteToJobSheetState();
}

class _InviteToJobSheetState
    extends State<_InviteToJobSheet> {
  late Future<
      List<Map<String, dynamic>>>
      _jobsFuture;

  String? _selectedJobId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _jobsFuture =
        widget.service
            .getMyOpenJobs();
  }

  Future<void> _sendInvite(
    List<Map<String, dynamic>>
        jobs,
  ) async {
    if (_sending ||
        _selectedJobId == null) {
      return;
    }

    final selectedJob =
        jobs.firstWhere(
      (job) =>
          job['jobId']
              ?.toString() ==
          _selectedJobId,
    );

    final title =
        selectedJob['title']
                ?.toString() ??
            'Job';

    final confirmed =
        await showDialog<bool>(
              context: context,
              builder:
                  (dialogContext) {
                return AlertDialog(
                  backgroundColor:
                      AppColors
                          .surface,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),
                  ),
                  title: Text(
                    'Send invitation?',
                    style:
                        AppText.heading(
                      size: 18,
                    ),
                  ),
                  content: Text(
                    'Invite ${widget.workerName} to "$title"?',
                    style:
                        AppText.body(
                      size: 12,
                      color:
                          AppColors
                              .inkSoft,
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
                        style:
                            AppText.label(
                          size: 10.5,
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
                            AppColors
                                .ink,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                      ),
                      child: Text(
                        'Send invite',
                        style:
                            AppText.label(
                          size: 10.5,
                          color:
                              Colors
                                  .white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;

    if (!confirmed ||
        !mounted) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await widget.service
          .inviteWorker(
        workerId:
            widget.workerId,
        jobId:
            _selectedJobId!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedJobId =
            null;
        _sending = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Invitation sent to ${widget.workerName}.',
          ),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottomPadding =
        MediaQuery.of(
          context,
        ).viewInsets.bottom;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        10,
        30,
        10,
        10,
      ),
      padding:
          EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + bottomPadding,
      ),
      constraints:
          BoxConstraints(
        maxHeight:
            MediaQuery.of(
                  context,
                ).size.height *
                0.82,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
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
                  10,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons.send,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Invite to a job',
                      style:
                          AppText.heading(
                        size: 20,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      widget.workerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.body(
                        size: 11,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _sending
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },
                icon: const Icon(
                  LucideIcons.x,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Select one of your open jobs',
            style:
                AppText.heading(
              size: 14,
            ),
          ),
          const SizedBox(
            height: 10,
          ),

          Flexible(
            child: FutureBuilder<
                List<
                    Map<String,
                        dynamic>>>(
              future:
                  _jobsFuture,
              builder: (
                context,
                jobSnapshot,
              ) {
                if (jobSnapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(
                        30,
                      ),
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors
                                .ink,
                      ),
                    ),
                  );
                }

                if (jobSnapshot.hasError) {
                  return _InviteSheetMessage(
                    icon:
                        LucideIcons
                            .triangleAlert,
                    title:
                        'Unable to load jobs',
                    message:
                        jobSnapshot.error
                            .toString(),
                  );
                }

                final jobs =
                    jobSnapshot.data ??
                        [];

                if (jobs.isEmpty) {
                  return const _InviteSheetMessage(
                    icon:
                        LucideIcons
                            .briefcase,
                    title:
                        'No open jobs',
                    message:
                        'Post a job first, then you can invite this worker.',
                  );
                }

                return StreamBuilder<
                    Map<String, String>>(
                  stream: widget.service
                      .getInvitationStatusesForWorker(
                    workerId:
                        widget.workerId,
                  ),
                  initialData:
                      const {},
                  builder: (
                    context,
                    statusSnapshot,
                  ) {
                    final statuses =
                        statusSnapshot
                                .data ??
                            {};

                    return Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Flexible(
                          child:
                              ListView.separated(
                            shrinkWrap:
                                true,
                            itemCount:
                                jobs.length,
                            separatorBuilder:
                                (
                              context,
                              index,
                            ) =>
                                    const SizedBox(
                              height: 9,
                            ),
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final job =
                                  jobs[index];

                              final jobId =
                                  job['jobId']
                                          ?.toString() ??
                                      '';

                              final status =
                                  statuses[
                                      jobId];

                              final normalizedStatus =
                                  status
                                          ?.toLowerCase() ??
                                      '';

                              final invited =
                                  normalizedStatus ==
                                      'pending';

                              final rejected =
                                  normalizedStatus ==
                                      'rejected';

                              final selected =
                                  _selectedJobId ==
                                      jobId;

                              return _JobSelectionTile(
                                job:
                                    job,
                                selected:
                                    selected,
                                invitationStatus:
                                    normalizedStatus,
                                onTap:
                                    _sending ||
                                            invited
                                        ? null
                                        : () {
                                            setState(
                                              () {
                                                _selectedJobId =
                                                    jobId;
                                              },
                                            );
                                          },
                                buttonText:
                                    invited
                                        ? 'INVITED'
                                        : rejected
                                            ? 'INVITE AGAIN'
                                            : 'INVITE',
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _sending ||
                                        _selectedJobId ==
                                            null
                                    ? null
                                    : () {
                                        _sendInvite(
                                          jobs,
                                        );
                                      },
                            icon:
                                _sending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        LucideIcons
                                            .send,
                                        size: 16,
                                      ),
                            label: Text(
                              _sending
                                  ? 'Sending...'
                                  : 'Send invitation',
                              style:
                                  AppText.label(
                                size: 11.5,
                                color:
                                    Colors.white,
                              ),
                            ),
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  AppColors
                                      .ink,
                              foregroundColor:
                                  Colors
                                      .white,
                              disabledBackgroundColor:
                                  AppColors
                                      .line,
                              disabledForegroundColor:
                                  AppColors
                                      .muted,
                              elevation: 0,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 15,
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
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSelectionTile
    extends StatelessWidget {
  const _JobSelectionTile({
    required this.job,
    required this.selected,
    required this.invitationStatus,
    required this.buttonText,
    required this.onTap,
  });

  final Map<String, dynamic>
      job;
  final bool selected;
  final String invitationStatus;
  final String buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        job['title']
                ?.toString()
                .trim() ??
            'Untitled job';

    final category =
        job['category']
                ?.toString()
                .trim() ??
            'Job';

    final location =
        job['location']
                ?.toString()
                .trim() ??
            '';

    final budget =
        job['budget'];

    final budgetText =
        budget == null
            ? ''
            : budget.toString();

    final invited =
        invitationStatus ==
            'pending';

    final rejected =
        invitationStatus ==
            'rejected';

    return Material(
      color:
          invited
              ? AppColors
                  .goldSoft
              : selected
                  ? AppColors
                      .goldSoft
                  : AppColors
                      .surface,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
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
              18,
            ),
            border: Border.all(
              color:
                  invited ||
                          selected
                      ? AppColors.gold
                      : AppColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      invited ||
                              selected
                          ? AppColors.ink
                          : AppColors
                              .background,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  invited
                      ? LucideIcons
                          .sendHorizontal
                      : LucideIcons
                          .briefcase,
                  size: 16,
                  color:
                      invited ||
                              selected
                          ? Colors.white
                          : AppColors
                              .ink,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      category,
                      style:
                          AppText.body(
                        size: 9.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                    if (location
                            .isNotEmpty ||
                        budgetText
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        [
                          if (location
                              .isNotEmpty)
                            location,
                          if (budgetText
                              .isNotEmpty)
                            'Budget: $budgetText',
                        ].join(
                          ' • ',
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppText.body(
                          size: 9,
                          color:
                              AppColors
                                  .muted,
                        ),
                      ),
                    ],
                    if (rejected) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Previous invitation declined',
                        style:
                            AppText.body(
                          size: 8.5,
                          color:
                              AppColors
                                  .muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      invited
                          ? AppColors
                              .ink
                          : rejected
                              ? AppColors
                                  .background
                              : selected
                                  ? AppColors
                                      .ink
                                  : AppColors
                                      .background,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    if (invited) ...[
                      const Icon(
                        LucideIcons
                            .check,
                        size: 11,
                        color:
                            Colors.white,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                    ],
                    Text(
                      buttonText,
                      style:
                          AppText.label(
                        size: 7.5,
                        color:
                            invited ||
                                    selected
                                ? Colors
                                    .white
                                : AppColors
                                    .ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteSheetMessage
    extends StatelessWidget {
  const _InviteSheetMessage({
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
    return Container(
      width: double.infinity,
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
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Column(
        children: [
          PremiumIconBox(
            icon: icon,
          ),
          const SizedBox(
            height: 13,
          ),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                AppText.heading(
              size: 15,
            ),
          ),
          const SizedBox(
            height: 5,
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
    );
  }
}

class _ProfileHeader
    extends StatelessWidget {
  const _ProfileHeader({
    required this.workerName,
  });

  final String workerName;

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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Worker profile',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  workerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppText.body(
                    size: 11,
                    color:
                        AppColors
                            .muted,
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
              LucideIcons
                  .userRoundSearch,
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

class _HeroCard
    extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.photoUrl,
    required this.location,
    required this.experienceYears,
    required this.acceptingJobs,
    required this.rating,
    required this.reviewCount,
  });

  final String name;
  final String photoUrl;
  final String location;
  final int experienceYears;
  final bool acceptingJobs;
  final double rating;
  final int reviewCount;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                clipBehavior:
                    Clip.antiAlias,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    20,
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
                                child: Text(
                                  _initials(
                                    name,
                                  ),
                                  style:
                                      AppText.display(
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          )
                        : Text(
                            _initials(
                              name,
                            ),
                            style:
                                AppText.display(
                              size: 20,
                            ),
                          ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 19,
                        color:
                            Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Icon(
                          acceptingJobs
                              ? LucideIcons
                                  .circleCheck
                              : LucideIcons
                                  .circlePause,
                          size: 13,
                          color:
                              acceptingJobs
                                  ? AppColors
                                      .gold
                                  : Colors
                                      .white54,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          acceptingJobs
                              ? 'Accepting jobs'
                              : 'Not accepting jobs',
                          style:
                              AppText.body(
                            size: 10.5,
                            color:
                                Colors
                                    .white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 22,
          ),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(
                  icon:
                      LucideIcons.star,
                  value:
                      reviewCount == 0
                          ? 'New'
                          : rating
                              .toStringAsFixed(
                                1,
                              ),
                  label:
                      reviewCount == 1
                          ? '1 review'
                          : '$reviewCount reviews',
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: _DarkMetric(
                  icon:
                      LucideIcons
                          .briefcaseBusiness,
                  value:
                      '$experienceYears',
                  label:
                      experienceYears ==
                              1
                          ? 'year experience'
                          : 'years experience',
                ),
              ),
            ],
          ),
          if (location
              .isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color:
                      Colors.white54,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    location,
                    style:
                        AppText.body(
                      size: 10.5,
                      color:
                          Colors
                              .white60,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkMetric
    extends StatelessWidget {
  const _DarkMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white
                .withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                AppColors.gold,
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            value,
            style:
                AppText.heading(
              size: 17,
              color:
                  Colors.white,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                AppText.body(
              size: 8.5,
              color:
                  Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

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
            children: [
              PremiumIconBox(
                icon: icon,
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Text(
                  title,
                  style:
                      AppText.heading(
                    size: 15,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color:
              AppColors.muted,
        ),
        const SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 68,
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
              size: 11,
              color:
                  AppColors
                      .inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tags
    extends StatelessWidget {
  const _Tags({
    required this.values,
    required this.emptyText,
  });

  final List<String> values;
  final String emptyText;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (values.isEmpty) {
      return Text(
        emptyText,
        style:
            AppText.body(
          size: 11,
          color:
              AppColors.muted,
        ),
      );
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children:
          values.map(
        (value) {
          return Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .background,
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: Text(
              value,
              style:
                  AppText.label(
                size: 8.5,
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _AvailabilityList
    extends StatelessWidget {
  const _AvailabilityList({
    required this.availability,
  });

  final Map<String,
          List<Map<String, int>>>
      availability;

  @override
  Widget build(
    BuildContext context,
  ) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final hasAny =
        days.any(
      (day) =>
          (availability[day] ??
                  [])
              .isNotEmpty,
    );

    if (!hasAny) {
      return Text(
        'No weekly availability added.',
        style:
            AppText.body(
          size: 11,
          color:
              AppColors.muted,
        ),
      );
    }

    return Column(
      children:
          days.map(
        (day) {
          final slots =
              availability[day] ??
                  [];

          if (slots.isEmpty) {
            return const SizedBox
                .shrink();
          }

          return Padding(
            padding:
                const EdgeInsets
                    .only(
              bottom: 11,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    _capitalize(
                      day,
                    ),
                    style:
                        AppText.label(
                      size: 9.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        slots.map(
                      (slot) {
                        final start =
                            slot[
                                    'startMinutes'] ??
                                0;

                        final end =
                            slot[
                                    'endMinutes'] ??
                                0;

                        return Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                9,
                            vertical:
                                6,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors
                                    .goldSoft,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${_formatMinutes(start)} – ${_formatMinutes(end)}',
                            style:
                                AppText.body(
                              size: 8.5,
                              color:
                                  AppColors
                                      .inkSoft,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }
}

class _ReviewsPreview
    extends StatelessWidget {
  const _ReviewsPreview({
    required this.reviews,
    required this.rating,
    required this.reviewCount,
  });

  final List<Map<String, dynamic>>
      reviews;
  final double rating;
  final int reviewCount;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (reviewCount == 0 ||
        reviews.isEmpty) {
      return Text(
        'No client reviews yet.',
        style:
            AppText.body(
          size: 11,
          color:
              AppColors.muted,
        ),
      );
    }

    final recent =
        reviews.take(2).toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              size: 20,
              color:
                  AppColors.gold,
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              rating.toStringAsFixed(
                1,
              ),
              style:
                  AppText.heading(
                size: 16,
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              'from $reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
              style:
                  AppText.body(
                size: 9.5,
                color:
                    AppColors
                        .muted,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 14,
        ),
        ...recent.map(
          (review) {
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

            final jobTitle =
                review['jobTitle']
                        ?.toString()
                        .trim() ??
                    'Completed job';

            return Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 12,
              ),
              child: Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  13,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .background,
                  borderRadius:
                      BorderRadius
                          .circular(
                    16,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            jobTitle,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                AppText
                                    .heading(
                              size: 11.5,
                            ),
                          ),
                        ),
                        Text(
                          '$stars/5',
                          style:
                              AppText.label(
                            size: 9,
                            color:
                                AppColors
                                    .gold,
                          ),
                        ),
                      ],
                    ),
                    if (comment
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        comment,
                        maxLines: 3,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppText.body(
                          size: 10.5,
                          color:
                              AppColors
                                  .inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ApplicationActions
    extends StatefulWidget {
  const _ApplicationActions({
    required this.status,
    this.onAccept,
    this.onReject,
  });

  final String status;
  final Future<void> Function()?
      onAccept;
  final Future<void> Function()?
      onReject;

  @override
  State<_ApplicationActions>
      createState() =>
          _ApplicationActionsState();
}

class _ApplicationActionsState
    extends State<_ApplicationActions> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function()? action,
  ) async {
    if (action == null ||
        _busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();
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
    final status =
        widget.status
            .toLowerCase();

    if (status != 'pending') {
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
        child: Text(
          status == 'accepted'
              ? 'This worker has already been selected.'
              : 'This application is no longer pending.',
          textAlign:
              TextAlign.center,
          style:
              AppText.body(
            size: 10.5,
            color:
                AppColors.muted,
          ),
        ),
      );
    }

    if (_busy) {
      return const Center(
        child:
            CircularProgressIndicator(
          strokeWidth: 2.2,
          color:
              AppColors.ink,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              OutlinedButton.icon(
            onPressed:
                widget.onReject ==
                        null
                    ? null
                    : () {
                        _run(
                          widget
                              .onReject,
                        );
                      },
            icon: const Icon(
              LucideIcons.x,
              size: 16,
            ),
            label: Text(
              'Reject',
              style:
                  AppText.label(
                size: 11.5,
              ),
            ),
            style:
                OutlinedButton
                    .styleFrom(
              foregroundColor:
                  AppColors
                      .inkSoft,
              side:
                  const BorderSide(
                color:
                    AppColors.line,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 14,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
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
          child:
              ElevatedButton.icon(
            onPressed:
                widget.onAccept ==
                        null
                    ? null
                    : () {
                        _run(
                          widget
                              .onAccept,
                        );
                      },
            icon: const Icon(
              LucideIcons.check,
              size: 16,
            ),
            label: Text(
              'Accept',
              style:
                  AppText.label(
                size: 11.5,
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
              elevation: 0,
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 14,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState
    extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(
    BuildContext context,
  ) {
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
          'Unable to load worker profile.\n$message',
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

List<String> _stringList(
  dynamic raw,
) {
  if (raw is! List) {
    return [];
  }

  return raw
      .map(
        (item) =>
            item.toString().trim(),
      )
      .where(
        (item) =>
            item.isNotEmpty,
      )
      .toList();
}

Map<String,
        List<Map<String, int>>>
    _availabilityMap(
  dynamic raw,
) {
  final result = <String,
      List<Map<String, int>>>{};

  if (raw is! Map) {
    return result;
  }

  for (final entry
      in raw.entries) {
    final day =
        entry.key.toString();

    final slots =
        <Map<String, int>>[];

    final rawSlots =
        entry.value;

    if (rawSlots is List) {
      for (final rawSlot
          in rawSlots) {
        if (rawSlot is Map) {
          final start =
              rawSlot[
                  'startMinutes'];

          final end =
              rawSlot[
                  'endMinutes'];

          if (start is num &&
              end is num) {
            slots.add({
              'startMinutes':
                  start.toInt(),
              'endMinutes':
                  end.toInt(),
            });
          }
        }
      }
    }

    slots.sort(
      (a, b) =>
          (a['startMinutes'] ??
                  0)
              .compareTo(
        b['startMinutes'] ?? 0,
      ),
    );

    result[day] =
        slots;
  }

  return result;
}

String _formatMinutes(
  int minutes,
) {
  if (minutes >= 1440) {
    return '12:00 AM';
  }

  if (minutes < 0) {
    minutes = 0;
  }

  final hour24 =
      minutes ~/ 60;

  final minute =
      minutes % 60;

  final period =
      hour24 >= 12
          ? 'PM'
          : 'AM';

  var hour12 =
      hour24 % 12;

  if (hour12 == 0) {
    hour12 = 12;
  }

  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

String _capitalize(
  String value,
) {
  if (value.isEmpty) {
    return value;
  }

  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _initials(
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

String _friendlyError(
  Object error,
) {
  var text =
      error.toString();

  if (text.startsWith(
    'Bad state: ',
  )) {
    text =
        text.substring(
      'Bad state: '.length,
    );
  }

  if (text.startsWith(
    'Invalid argument(s): ',
  )) {
    text =
        text.substring(
      'Invalid argument(s): '
          .length,
    );
  }

  if (text.contains(
    'permission-denied',
  )) {
    return 'Permission denied. Check Firestore rules.';
  }

  return text;
}