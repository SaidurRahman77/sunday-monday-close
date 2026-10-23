import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/chat_service.dart';
import '../services/job_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/premium_ui.dart';

import 'client_active_jobs_screen.dart';
import 'client_job_history_screen.dart';
import 'client_profile_screen.dart';
import 'find_workers_screen.dart';
import 'messages_screen.dart';
import 'my_jobs_screen.dart';
import 'notifications_screen.dart';
import 'post_job_screen.dart';
import 'worker_dashboard_screen.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({
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

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }

    return 'Good night';
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
                  icon: LucideIcons.briefcase,
                  title: 'Client',
                  subtitle: 'Current mode',
                  selected: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                _ModeOption(
                  icon: LucideIcons.wrench,
                  title: 'Worker',
                  subtitle:
                      'Find jobs and earn',
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _replace(
                      context,
                      const WorkerDashboardScreen(),
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

  String _initialsFromName(
    String name,
  ) {
    final value =
        name.trim();

    if (value.isEmpty) {
      return 'U';
    }

    final parts =
        value
            .split(
              RegExp(r'\s+'),
            )
            .where(
              (part) =>
                  part.isNotEmpty,
            )
            .toList();

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

  @override
  Widget build(
    BuildContext context,
  ) {
    final profileService =
        ProfileService();

    final jobService =
        JobService();

    final notificationService =
        NotificationService();

    return Scaffold(
      backgroundColor:
          AppColors.background,

      bottomNavigationBar:
          _ClientBottomNavigation(
        currentIndex: 0,
        onHome: () {},
        onWorkboard: () {
          _replace(
            context,
            const ClientWorkboardScreen(),
          );
        },
        onDiscover: () {
          _replace(
            context,
            const ClientDiscoverScreen(),
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
            const ClientProfileScreen(),
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
                stream: profileService
                    .getProfileStream(),
                builder: (
                  context,
                  profileSnapshot,
                ) {
                  final profile =
                      profileSnapshot.data;

                  final authUser =
                      FirebaseAuth.instance
                          .currentUser;

                  final savedName =
                      profile?['name']
                          ?.toString()
                          .trim();

                  final authName =
                      authUser?.displayName
                          ?.trim();

                  String name = '';

                  if (savedName != null &&
                      savedName.isNotEmpty) {
                    name = savedName;
                  } else if (
                      authName != null &&
                          authName.isNotEmpty) {
                    name = authName;
                  }

                  final savedPhoto =
                      profile?['photoUrl']
                          ?.toString()
                          .trim();

                  final authPhoto =
                      authUser?.photoURL
                          ?.trim();

                  String photoUrl = '';

                  if (savedPhoto != null &&
                      savedPhoto.isNotEmpty) {
                    photoUrl =
                        savedPhoto;
                  } else if (
                      authPhoto != null &&
                          authPhoto.isNotEmpty) {
                    photoUrl =
                        authPhoto;
                  }

                  return StreamBuilder<int>(
                    stream:
                        notificationService
                            .getUnreadCount(),
                    initialData: 0,
                    builder: (
                      context,
                      notificationSnapshot,
                    ) {
                      return _ClientHeader(
                        greeting:
                            _getGreeting(),
                        name: name,
                        photoUrl:
                            photoUrl,
                        initials:
                            _initialsFromName(
                          name,
                        ),
                        unreadCount:
                            notificationSnapshot
                                    .data ??
                                0,
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
                            const ClientProfileScreen(),
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

                    StreamBuilder<
                        List<
                            Map<String,
                                dynamic>>>(
                      stream:
                          jobService
                              .getMyJobs(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        final jobs =
                            snapshot.data ?? [];

                        int open = 0;
                        int active = 0;
                        int completed = 0;

                        for (final job
                            in jobs) {
                          final status =
                              job['status']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';

                          if (status ==
                              'open') {
                            open++;
                          } else if (
                              status ==
                                      'assigned' ||
                                  status ==
                                      'in_progress') {
                            active++;
                          } else if (
                              status ==
                                  'completed') {
                            completed++;
                          }
                        }

                        return _ClientFocusCard(
                          open: open,
                          active: active,
                          completed:
                              completed,
                          onTap: () {
                            _replace(
                              context,
                              const ClientWorkboardScreen(),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Recent activity',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    StreamBuilder<
                        List<
                            Map<String,
                                dynamic>>>(
                      stream:
                          jobService
                              .getMyJobs(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot
                                .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const _LoadingCard();
                        }

                        final jobs =
                            snapshot.data ?? [];

                        if (jobs.isEmpty) {
                          return _EmptyActivity(
                            onPostJob: () {
                              _open(
                                context,
                                const PostJobScreen(),
                              );
                            },
                          );
                        }

                        return _RecentJobCard(
                          job:
                              jobs.first,
                          onTap: () {
                            _open(
                              context,
                              const MyJobsScreen(),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Discover talent',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _DiscoverPreview(
                      onTap: () {
                        _replace(
                          context,
                          const ClientDiscoverScreen(),
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
// CLIENT WORKBOARD
// =====================================================

class ClientWorkboardScreen
    extends StatelessWidget {
  const ClientWorkboardScreen({
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
    final jobService =
        JobService();

    return Scaffold(
      backgroundColor:
          AppColors.background,

      bottomNavigationBar:
          _ClientBottomNavigation(
        currentIndex: 1,
        onHome: () {
          _replace(
            context,
            const ClientDashboardScreen(),
          );
        },
        onWorkboard: () {},
        onDiscover: () {
          _replace(
            context,
            const ClientDiscoverScreen(),
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
            const ClientProfileScreen(),
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
                    'JOB MANAGEMENT',
                title:
                    'Your workboard',
                subtitle:
                    'Manage your posted jobs from open to completed.',
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
                    StreamBuilder<
                        List<
                            Map<String,
                                dynamic>>>(
                      stream:
                          jobService
                              .getMyJobs(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        final jobs =
                            snapshot.data ?? [];

                        int open = 0;
                        int active = 0;
                        int completed = 0;

                        for (final job
                            in jobs) {
                          final status =
                              job['status']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';

                          if (status ==
                              'open') {
                            open++;
                          } else if (
                              status ==
                                      'assigned' ||
                                  status ==
                                      'in_progress') {
                            active++;
                          } else if (
                              status ==
                                  'completed') {
                            completed++;
                          }
                        }

                        return _WorkboardStats(
                          open: open,
                          active: active,
                          completed:
                              completed,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Manage jobs',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons.briefcase,
                      title:
                          'All jobs',
                      subtitle:
                          'View and manage every job you posted',
                      onTap: () {
                        _open(
                          context,
                          const MyJobsScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    PremiumActionTile(
                      icon:
                          LucideIcons.clock,
                      title:
                          'Ongoing work',
                      subtitle:
                          'Assigned and in-progress jobs',
                      onTap: () {
                        _open(
                          context,
                          const ClientActiveJobsScreen(),
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
                          'Job history',
                      subtitle:
                          'Completed jobs and reviews',
                      onTap: () {
                        _open(
                          context,
                          const ClientJobHistoryScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Material(
                      color:
                          AppColors.dark,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      child: InkWell(
                        onTap: () async {
                          await _openPostJob(
                            context,
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            20,
                          ),
                          child: Row(
                            children: [
                              const PremiumIconBox(
                                icon:
                                    LucideIcons.plus,
                                dark:
                                    true,
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
                                      'Post a new job',
                                      style:
                                          AppText
                                              .heading(
                                        color:
                                            Colors
                                                .white,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'Create a new opportunity for workers.',
                                      style:
                                          AppText
                                              .body(
                                        color:
                                            Colors
                                                .white60,
                                        size: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons
                                    .arrowUpRight,
                                color:
                                    AppColors.gold,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
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

  Future<void> _openPostJob(
    BuildContext context,
  ) async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PostJobScreen(),
      ),
    );

    if (result == true &&
        context.mounted) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Job posted successfully.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// =====================================================
// CLIENT DISCOVER
// =====================================================

class ClientDiscoverScreen
    extends StatelessWidget {
  const ClientDiscoverScreen({
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
          _ClientBottomNavigation(
        currentIndex: 2,
        onHome: () {
          _replace(
            context,
            const ClientDashboardScreen(),
          );
        },
        onWorkboard: () {
          _replace(
            context,
            const ClientWorkboardScreen(),
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
            const ClientProfileScreen(),
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
                    'TALENT DISCOVERY',
                title:
                    'Find the right worker',
                subtitle:
                    'Explore skilled workers, check profiles and invite the right person.',
                icon:
                    LucideIcons.users,
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
                          'Discover workers',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _DiscoverFeatureCard(
                      icon:
                          LucideIcons.users,
                      title:
                          'Browse skilled workers',
                      badge:
                          'DISCOVER',
                      description:
                          'Search workers by skill, category, experience and availability.',
                      onTap: () {
                        _open(
                          context,
                          const FindWorkersScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _DiscoverFeatureCard(
                      icon:
                          LucideIcons.messageCircle,
                      title:
                          'Connect before hiring',
                      badge:
                          'CHAT',
                      description:
                          'View worker profiles, start a conversation and invite them to a job.',
                      onTap: () {
                        _open(
                          context,
                          const FindWorkersScreen(),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _DiscoverFeatureCard(
                      icon:
                          LucideIcons.star,
                      title:
                          'Choose with confidence',
                      badge:
                          'PROFILES',
                      description:
                          'Compare experience, ratings and completed work before inviting.',
                      onTap: () {
                        _open(
                          context,
                          const FindWorkersScreen(),
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
// CLIENT BOTTOM NAV
// =====================================================

class _ClientBottomNavigation
    extends StatelessWidget {
  const _ClientBottomNavigation({
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
          onTap:
              onWorkboard,
        ),

        _NavTap(
          left: itemWidth * 2,
          width: itemWidth,
          onTap:
              onDiscover,
        ),

        Positioned(
          left: itemWidth * 3,
          top: 0,
          bottom: 0,
          width: itemWidth,
          child:
              StreamBuilder<int>(
            stream:
                chatService
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
        color: Colors.transparent,
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
// CLIENT HEADER
// =====================================================

class _ClientHeader extends StatelessWidget {
  const _ClientHeader({
    required this.greeting,
    required this.name,
    required this.photoUrl,
    required this.initials,
    required this.unreadCount,
    required this.onNotifications,
    required this.onSwitch,
    required this.onProfile,
  });

  final String greeting;
  final String name;
  final String photoUrl;
  final String initials;
  final int unreadCount;

  final VoidCallback onNotifications;
  final VoidCallback onSwitch;
  final VoidCallback onProfile;

  @override
  Widget build(
    BuildContext context,
  ) {
    final greetingText =
        name.isEmpty
            ? greeting
            : '$greeting, $name';

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
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap:
                    onProfile,
                child: Container(
                  width: 43,
                  height: 43,
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
                      14,
                    ),
                    border:
                        Border.all(
                      color:
                          Colors.white
                              .withValues(
                        alpha: 0.12,
                      ),
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
                                return Text(
                                  initials,
                                  style:
                                      AppText.label(
                                    size: 11,
                                    color:
                                        AppColors
                                            .ink,
                                  ),
                                );
                              },
                            )
                          : Text(
                              initials,
                              style:
                                  AppText.label(
                                size: 11,
                                color:
                                    AppColors
                                        .ink,
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
                        BorderRadius.circular(
                      13,
                    ),
                    child: InkWell(
                      onTap:
                          onNotifications,
                      borderRadius:
                          BorderRadius.circular(
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
                label: 'Client',
                onTap: onSwitch,
              ),
            ],
          ),

          const SizedBox(
            height: 38,
          ),

          Text(
            greetingText,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
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
            'What do you need\ndone today?',
            style: AppText.display(
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Manage your jobs or discover skilled workers ready to help.',
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
              onTap: () async {
                final result =
                    await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PostJobScreen(),
                  ),
                );

                if (result == true &&
                    context.mounted) {
                  ScaffoldMessenger
                          .of(context)
                      .hideCurrentSnackBar();

                  ScaffoldMessenger
                          .of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Job posted successfully.',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                }
              },
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 18,
                      color:
                          AppColors.ink,
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Text(
                      'Post a new job',
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

class _ClientFocusCard
    extends StatelessWidget {
  const _ClientFocusCard({
    required this.open,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  final int open;
  final int active;
  final int completed;
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
            children: [
              Row(
                children: [
                  const PremiumIconBox(
                    icon:
                        LucideIcons
                            .briefcaseBusiness,
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
                          'Workboard',
                          style:
                              AppText.heading(
                            size: 16,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          'Your complete job pipeline',
                          style:
                              AppText.body(
                            size: 11.5,
                            color:
                                AppColors
                                    .muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons
                        .chevronRight,
                    color:
                        AppColors.muted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  _MiniStat(
                    value:
                        open.toString(),
                    label: 'Open',
                  ),
                  const _MiniDivider(),
                  _MiniStat(
                    value:
                        active.toString(),
                    label: 'Active',
                  ),
                  const _MiniDivider(),
                  _MiniStat(
                    value:
                        completed.toString(),
                    label:
                        'Completed',
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

class _WorkboardStats
    extends StatelessWidget {
  const _WorkboardStats({
    required this.open,
    required this.active,
    required this.completed,
  });

  final int open;
  final int active;
  final int completed;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Row(
        children: [
          _MiniStat(
            value:
                open.toString(),
            label: 'Open',
          ),
          const _MiniDivider(),
          _MiniStat(
            value:
                active.toString(),
            label: 'Active',
          ),
          const _MiniDivider(),
          _MiniStat(
            value:
                completed.toString(),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}

class _MiniStat
    extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppText.heading(
              size: 22,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            style: AppText.body(
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

class _MiniDivider
    extends StatelessWidget {
  const _MiniDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 1,
      height: 36,
      color:
          AppColors.line,
    );
  }
}

// =====================================================
// RECENT ACTIVITY
// =====================================================

class _RecentJobCard
    extends StatelessWidget {
  const _RecentJobCard({
    required this.job,
    required this.onTap,
  });

  final Map<String, dynamic>
      job;

  final VoidCallback onTap;

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

    final status =
        job['status']
                ?.toString() ??
            'open';

    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          22,
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
              22,
            ),
            border: Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Row(
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons
                        .briefcase,
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
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '$category  •  ${_statusText(status)}',
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
              const Icon(
                LucideIcons
                    .chevronRight,
                size: 18,
                color:
                    AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusText(
    String status,
  ) {
    switch (
        status.toLowerCase()) {
      case 'open':
        return 'Open';

      case 'assigned':
        return 'Assigned';

      case 'in_progress':
        return 'In progress';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }
}

class _EmptyActivity
    extends StatelessWidget {
  const _EmptyActivity({
    required this.onPostJob,
  });

  final VoidCallback onPostJob;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap: onPostJob,
        borderRadius:
            BorderRadius.circular(
          22,
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
              22,
            ),
            border: Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Row(
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons.plus,
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
                      'Post your first job',
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Your recent activity will appear here.',
                      style:
                          AppText.body(
                        size: 11.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons
                    .arrowUpRight,
                size: 18,
                color:
                    AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard
    extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 90,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              AppColors.line,
        ),
      ),
      child:
          const SizedBox(
        width: 20,
        height: 20,
        child:
            CircularProgressIndicator(
          strokeWidth: 2,
          color:
              AppColors.ink,
        ),
      ),
    );
  }
}

// =====================================================
// DISCOVERY
// =====================================================

class _DiscoverPreview
    extends StatelessWidget {
  const _DiscoverPreview({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _DiscoverFeatureCard(
      icon:
          LucideIcons.users,
      title:
          'Find skilled workers',
      badge:
          'DISCOVER',
      description:
          'Explore profiles, compare experience and connect before hiring.',
      onTap: onTap,
    );
  }
}

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
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
                    Alignment.centerRight,
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
// SIMPLE HERO
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
        color:
            AppColors.dark,
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