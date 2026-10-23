import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/application_service.dart';
import '../services/chat_service.dart';
import '../services/job_service.dart';
import '../services/job_invitation_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/premium_ui.dart';

import 'client_dashboard_screen.dart';
import 'find_jobs_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'worker_active_jobs_screen.dart';
import 'worker_applications_screen.dart';
import 'worker_invitations_screen.dart';
import 'worker_job_history_screen.dart';
import 'worker_profile_screen.dart';


String _initialsFromName(
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

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({
    super.key,
  });

  void _open(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void _replace(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void _showModeSwitcher(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(
            12,
          ),
          padding: const EdgeInsets.fromLTRB(
            22,
            16,
            22,
            24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              28,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Text(
                  'Switch mode',
                  style: AppText.heading(
                    size: 22,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Choose how you want to use Sunday-Monday Close.',
                  style: AppText.body(
                    size: 12.5,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const _ModeOption(
                  icon: LucideIcons.wrench,
                  title: 'Worker',
                  subtitle: 'Current mode',
                  selected: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                _ModeOption(
                  icon: LucideIcons.briefcase,
                  title: 'Client',
                  subtitle:
                      'Post jobs and hire people',
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _replace(
                      context,
                      const ClientDashboardScreen(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notificationService =
        NotificationService();

    final profileService =
        ProfileService();

    return Scaffold(
      backgroundColor:
          AppColors.background,

      bottomNavigationBar:
          _WorkerBottomNavigation(
        currentIndex: 0,
        onHome: () {},
        onWorkboard: () {
          _replace(
            context,
            const WorkerWorkboardScreen(),
          );
        },
        onDiscover: () {
          _replace(
            context,
            const WorkerDiscoverScreen(),
          );
        },
        onMessages: () {
          _open(
            context,
            const MessagesScreen(),
          );
        },
        onProfile: () {
          _open(
            context,
            const WorkerProfileScreen(),
          );
        },
      ),

      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StreamBuilder<
                  Map<String, dynamic>?>(
                stream:
                    profileService
                        .getProfileStream(),
                builder: (
                  context,
                  profileSnapshot,
                ) {
                  final profile =
                      profileSnapshot.data;

                  final authUser =
                      FirebaseAuth
                          .instance
                          .currentUser;

                  final savedName =
                      profile?['name']
                              ?.toString()
                              .trim() ??
                          '';

                  final fallbackName =
                      authUser
                              ?.displayName
                              ?.trim() ??
                          '';

                  final name =
                      savedName.isNotEmpty
                          ? savedName
                          : fallbackName.isNotEmpty
                              ? fallbackName
                              : 'Worker';

                  final savedPhotoUrl =
                      profile?['photoUrl']
                              ?.toString()
                              .trim() ??
                          '';

                  final authPhotoUrl =
                      authUser
                              ?.photoURL
                              ?.trim() ??
                          '';

                  final photoUrl =
                      savedPhotoUrl.isNotEmpty
                          ? savedPhotoUrl
                          : authPhotoUrl;

                  return StreamBuilder<int>(
                    stream:
                        notificationService
                            .getUnreadCount(),
                    initialData: 0,
                    builder: (
                      context,
                      snapshot,
                    ) {
                      return _WorkerHeader(
                        unreadCount:
                            snapshot.data ?? 0,
                        photoUrl:
                            photoUrl,
                        initials:
                            _initialsFromName(
                          name,
                        ),
                        onNotifications: () {
                          _open(
                            context,
                            const NotificationsScreen(),
                          );
                        },
                        onSwitch: () {
                          _showModeSwitcher(
                            context,
                          );
                        },
                        onProfile: () {
                          _open(
                            context,
                            const WorkerProfileScreen(),
                          );
                        },
                        onDiscover: () {
                          _replace(
                            context,
                            const WorkerDiscoverScreen(),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                36,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    const PremiumSectionHeader(
                      title: 'At a glance',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _WorkerStatsPanel(
                      onOpenWorkboard: () {
                        _replace(
                          context,
                          const WorkerWorkboardScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Recommended for you',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _DiscoveryPreview(
                      onTap: () {
                        _replace(
                          context,
                          const WorkerDiscoverScreen(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// WORKBOARD SCREEN
// =====================================================

class WorkerWorkboardScreen
    extends StatelessWidget {
  const WorkerWorkboardScreen({
    super.key,
  });

  void _open(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void _replace(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
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

      bottomNavigationBar:
          _WorkerBottomNavigation(
        currentIndex: 1,
        onHome: () {
          _replace(
            context,
            const WorkerDashboardScreen(),
          );
        },
        onWorkboard: () {},
        onDiscover: () {
          _replace(
            context,
            const WorkerDiscoverScreen(),
          );
        },
        onMessages: () {
          _open(
            context,
            const MessagesScreen(),
          );
        },
        onProfile: () {
          _open(
            context,
            const WorkerProfileScreen(),
          );
        },
      ),

      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: _SimpleHero(
                eyebrow:
                    'WORK MANAGEMENT',
                title:
                    'Your workboard',
                subtitle:
                    'Manage everything from application to completed work.',
                icon:
                    LucideIcons.briefcaseBusiness,
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                36,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    const PremiumSectionHeader(
                      title:
                          'Work pipeline',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons.briefcase,
                      title:
                          'Applications',
                      subtitle:
                          'Track jobs you applied for',
                      onTap: () {
                        _open(
                          context,
                          const WorkerApplicationsScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons.mail,
                      title:
                          'Invitations',
                      subtitle:
                          'Direct offers from clients',
                      onTap: () {
                        _open(
                          context,
                          const WorkerInvitationsScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons
                              .briefcaseBusiness,
                      title:
                          'Active work',
                      subtitle:
                          'Assigned and ongoing jobs',
                      onTap: () {
                        _open(
                          context,
                          const WorkerActiveJobsScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons.history,
                      title:
                          'Work history',
                      subtitle:
                          'Completed jobs and previous work',
                      onTap: () {
                        _open(
                          context,
                          const WorkerJobHistoryScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.dark,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                      child: Row(
                        children: [
                          const PremiumIconBox(
                            icon:
                                LucideIcons
                                    .sparkles,
                            dark: true,
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
                                  'Looking for more work?',
                                  style:
                                      AppText.heading(
                                    color:
                                        Colors.white,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Open Discover to find new opportunities.',
                                  style:
                                      AppText.body(
                                    color:
                                        Colors.white60,
                                    size: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _replace(
                                context,
                                const WorkerDiscoverScreen(),
                              );
                            },
                            icon: const Icon(
                              LucideIcons
                                  .arrowUpRight,
                              color:
                                  AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// DISCOVER SCREEN
// =====================================================

class WorkerDiscoverScreen
    extends StatelessWidget {
  const WorkerDiscoverScreen({
    super.key,
  });

  void _open(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void _replace(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
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

      bottomNavigationBar:
          _WorkerBottomNavigation(
        currentIndex: 2,
        onHome: () {
          _replace(
            context,
            const WorkerDashboardScreen(),
          );
        },
        onWorkboard: () {
          _replace(
            context,
            const WorkerWorkboardScreen(),
          );
        },
        onDiscover: () {},
        onMessages: () {
          _open(
            context,
            const MessagesScreen(),
          );
        },
        onProfile: () {
          _open(
            context,
            const WorkerProfileScreen(),
          );
        },
      ),

      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: _SimpleHero(
                eyebrow:
                    'SMART DISCOVERY',
                title:
                    'Find your next opportunity',
                subtitle:
                    'Browse open jobs or use smart matching to find stronger opportunities.',
                icon:
                    LucideIcons.sparkles,
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                36,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    const PremiumSectionHeader(
                      title:
                          'Discover jobs',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _DiscoverFeatureCard(
                      icon:
                          LucideIcons.sparkles,
                      title:
                          'Best matches',
                      badge:
                          'SMART',
                      description:
                          'Jobs selected using your skills, availability, location, rating and experience.',
                      onTap: () {
                        _open(
                          context,
                          const FindJobsScreen(
                            bestMatchesOnly:
                                true,
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _DiscoverFeatureCard(
                      icon:
                          LucideIcons.search,
                      title:
                          'Browse all jobs',
                      badge:
                          'ALL JOBS',
                      description:
                          'Explore every open opportunity and choose the work that fits you.',
                      onTap: () {
                        _open(
                          context,
                          const FindJobsScreen(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// BOTTOM NAVIGATION
// =====================================================

class _WorkerBottomNavigation
    extends StatelessWidget {
  const _WorkerBottomNavigation({
    required this.currentIndex,
    required this.onHome,
    required this.onWorkboard,
    required this.onDiscover,
    required this.onMessages,
    required this.onProfile,
  });

  final int currentIndex;
  final VoidCallback onHome;
  final VoidCallback onWorkboard;
  final VoidCallback onDiscover;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  @override
  Widget build(
    BuildContext context,
  ) {
    final itemWidth =
        MediaQuery.of(context).size.width /
            5;

    final chatService =
        ChatService();

    return Stack(
      children: [
        PremiumBottomNav(
          currentIndex:
              currentIndex,
        ),

        _NavTap(
          left: 0,
          width: itemWidth,
          onTap: onHome,
        ),

        _NavTap(
          left: itemWidth,
          width: itemWidth,
          onTap: onWorkboard,
        ),

        _NavTap(
          left: itemWidth * 2,
          width: itemWidth,
          onTap: onDiscover,
        ),

        Positioned(
          left: itemWidth * 3,
          top: 0,
          bottom: 0,
          width: itemWidth,
          child: StreamBuilder<int>(
            stream: chatService
                .getTotalUnreadCount(),
            initialData: 0,
            builder: (
              context,
              snapshot,
            ) {
              final count =
                  snapshot.data ?? 0;

              return Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Positioned.fill(
                    child: Material(
                      color:
                          Colors.transparent,
                      child: InkWell(
                        onTap:
                            onMessages,
                        splashColor:
                            Colors.transparent,
                        highlightColor:
                            Colors.transparent,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 5,
                      child:
                          _UnreadBadge(
                        count: count,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        _NavTap(
          left: itemWidth * 4,
          width: itemWidth,
          onTap: onProfile,
        ),
      ],
    );
  }
}

class _NavTap extends StatelessWidget {
  const _NavTap({
    required this.left,
    required this.width,
    required this.onTap,
  });

  final double left;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor:
              Colors.transparent,
          highlightColor:
              Colors.transparent,
        ),
      ),
    );
  }
}

// =====================================================
// HOME HEADER
// =====================================================

class _WorkerHeader extends StatelessWidget {
  const _WorkerHeader({
    required this.unreadCount,
    required this.photoUrl,
    required this.initials,
    required this.onNotifications,
    required this.onSwitch,
    required this.onProfile,
    required this.onDiscover,
  });

  final int unreadCount;
  final String photoUrl;
  final String initials;
  final VoidCallback onNotifications;
  final VoidCallback onSwitch;
  final VoidCallback onProfile;
  final VoidCallback onDiscover;

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
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        22,
      ),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 30,
            offset:
                const Offset(
              0,
              15,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color:
                    Colors.transparent,
                child: InkWell(
                  onTap: onProfile,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                  child: Container(
                    width: 39,
                    height: 39,
                    clipBehavior:
                        Clip.antiAlias,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white
                              .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
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
                                      initials,
                                      style:
                                          AppText.label(
                                        color:
                                            AppColors.gold,
                                        size:
                                            11,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Text(
                                initials,
                                style:
                                    AppText.label(
                                  color:
                                      AppColors.gold,
                                  size:
                                      11,
                                ),
                              ),
                  ),
                ),
              ),

              const Spacer(),

              Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Material(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      13,
                    ),
                    child: InkWell(
                      onTap:
                          onNotifications,
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                      child:
                          const SizedBox(
                        width: 43,
                        height: 43,
                        child: Icon(
                          LucideIcons.bell,
                          color:
                              Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  if (unreadCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child:
                          _UnreadBadge(
                        count:
                            unreadCount,
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width: 9,
              ),

              PremiumModeChip(
                label: 'Worker',
                onTap: onSwitch,
              ),
            ],
          ),

          const SizedBox(
            height: 38,
          ),

          Text(
            'Your next opportunity',
            style: AppText.body(
              color:
                  Colors.white54,
              size: 13,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Work that fits\nyour time.',
            style: AppText.display(
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Manage your work and discover opportunities matched to your profile.',
            style: AppText.body(
              color:
                  Colors.white60,
              size: 12.5,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Material(
            color: AppColors.gold,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            child: InkWell(
              onTap: onDiscover,
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      size: 18,
                      color:
                          AppColors.ink,
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Text(
                      'Discover jobs',
                      style:
                          AppText.label(
                        size: 12.5,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    const Icon(
                      LucideIcons
                          .arrowUpRight,
                      size: 16,
                      color:
                          AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HOME WORKBOARD PREVIEW
// =====================================================

class _WorkerStatsPanel
    extends StatelessWidget {
  const _WorkerStatsPanel({
    required this.onOpenWorkboard,
  });

  final VoidCallback onOpenWorkboard;

  @override
  Widget build(
    BuildContext context,
  ) {
    final applicationService =
        ApplicationService();

    final jobService =
        JobService();

    final invitationService =
        JobInvitationService();

    return StreamBuilder<
        List<Map<String, dynamic>>>(
      stream:
          applicationService
              .getMyApplications(),
      builder: (
        context,
        applicationSnapshot,
      ) {
        final applications =
            applicationSnapshot.data ??
                [];

        return StreamBuilder<
            List<Map<String, dynamic>>>(
          stream:
              jobService
                  .getWorkerActiveJobs(),
          builder: (
            context,
            activeSnapshot,
          ) {
            final activeJobs =
                activeSnapshot.data ??
                    [];

            return StreamBuilder<
                List<
                    Map<String, dynamic>>>(
              stream:
                  jobService
                      .getWorkerCompletedJobs(),
              builder: (
                context,
                completedSnapshot,
              ) {
                final completedJobs =
                    completedSnapshot.data ??
                        [];

                return StreamBuilder<
                    List<
                        Map<String,
                            dynamic>>>(
                  stream:
                      invitationService
                          .getWorkerInvitations(),
                  builder: (
                    context,
                    inviteSnapshot,
                  ) {
                    final invitations =
                        inviteSnapshot.data ??
                            [];

                    final pendingInvites =
                        invitations
                            .where(
                              (item) =>
                                  item['status']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'pending',
                            )
                            .length;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  _WorkerStatCard(
                                icon:
                                    LucideIcons
                                        .send,
                                value:
                                    applications
                                        .length,
                                label:
                                    'Applications',
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  _WorkerStatCard(
                                icon:
                                    LucideIcons
                                        .briefcaseBusiness,
                                value:
                                    activeJobs
                                        .length,
                                label:
                                    'Active',
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  _WorkerStatCard(
                                icon:
                                    LucideIcons
                                        .circleCheck,
                                value:
                                    completedJobs
                                        .length,
                                label:
                                    'Completed',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Material(
                          color:
                              AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          child: InkWell(
                            onTap:
                                onOpenWorkboard,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            child: Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                16,
                                14,
                                14,
                                14,
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
                                    width: 36,
                                    height: 36,
                                    alignment:
                                        Alignment.center,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          AppColors.goldSoft,
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      LucideIcons
                                          .mailOpen,
                                      size: 16,
                                      color:
                                          AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 11,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Workboard',
                                          style:
                                              AppText.heading(
                                            size: 13.5,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Text(
                                          pendingInvites >
                                                  0
                                              ? '$pendingInvites pending ${pendingInvites == 1 ? 'invitation' : 'invitations'}'
                                              : 'Applications, invitations and active work',
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
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WorkerStatCard
    extends StatelessWidget {
  const _WorkerStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
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
              size: 19,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          FittedBox(
            fit:
                BoxFit.scaleDown,
            child: Text(
              label,
              style:
                  AppText.body(
                size: 8.5,
                color:
                    AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DISCOVERY PREVIEW
// =====================================================

class _DiscoveryPreview
    extends StatelessWidget {
  const _DiscoveryPreview({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _DiscoverFeatureCard(
      icon:
          LucideIcons.sparkles,
      title:
          'Smart job discovery',
      badge:
          'MATCHING',
      description:
          'Find opportunities using your skills, availability, location, rating and experience.',
      onTap: onTap,
    );
  }
}

// =====================================================
// HERO
// =====================================================

class _SimpleHero
    extends StatelessWidget {
  const _SimpleHero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

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
        22,
      ),
      decoration:
          BoxDecoration(
        color: AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          PremiumIconBox(
            icon: icon,
            dark: true,
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  eyebrow,
                  style:
                      AppText.label(
                    color:
                        AppColors.gold,
                    size: 9,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  title,
                  style:
                      AppText.heading(
                    color:
                        Colors.white,
                    size: 21,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  subtitle,
                  style:
                      AppText.body(
                    color:
                        Colors.white60,
                    size: 11.5,
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

// =====================================================
// DISCOVERY FEATURE CARD
// =====================================================

class _DiscoverFeatureCard
    extends StatelessWidget {
  const _DiscoverFeatureCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String badge;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        24,
      ),
      child: InkWell(
        onTap: onTap,
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
            border: Border.all(
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

                  const Spacer(),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 6,
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
                    child: Text(
                      badge,
                      style:
                          AppText.label(
                        size: 8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                title,
                style:
                    AppText.heading(
                  size: 17,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                description,
                style:
                    AppText.body(
                  size: 11.5,
                  color:
                      AppColors.muted,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              const Align(
                alignment:
                    Alignment
                        .centerRight,
                child: Icon(
                  LucideIcons
                      .arrowUpRight,
                  size: 18,
                  color:
                      AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// BADGE
// =====================================================

class _UnreadBadge
    extends StatelessWidget {
  const _UnreadBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            AppColors.gold,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              AppColors.dark,
          width: 2,
        ),
      ),
      child: Text(
        count > 99
            ? '99+'
            : count.toString(),
        style: AppText.label(
          size: 7.5,
          color:
              AppColors.ink,
        ),
      ),
    );
  }
}

// =====================================================
// MODE OPTION
// =====================================================

class _ModeOption
    extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected
          ? AppColors.goldSoft
          : AppColors.background,
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
        child: Padding(
          padding:
              const EdgeInsets.all(
            15,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    AppColors.ink,
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
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

              Icon(
                selected
                    ? LucideIcons
                        .circleCheck
                    : LucideIcons
                        .chevronRight,
                size: 18,
                color: selected
                    ? AppColors
                        .success
                    : AppColors
                        .muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}