import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_service.dart';
import '../widgets/premium_ui.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_category_management_screen.dart';
import 'admin_job_management_screen.dart';
import 'admin_moderation_screens.dart';
import 'admin_platform_settings_screen.dart';
import 'admin_user_management_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen
    extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
  });

  Future<void> _logout(
    BuildContext context,
  ) async {
    await AdminService().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final service =
        AdminService();

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child:
            CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  _AdminHeader(
                onLogout: () =>
                    _logout(
                  context,
                ),
              ),
            ),

            SliverPadding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                28,
                20,
                36,
              ),
              sliver:
                  SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    const PremiumSectionHeader(
                      title:
                          'Platform overview',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      mainAxisSpacing:
                          10,
                      crossAxisSpacing:
                          10,
                      childAspectRatio:
                          1.22,
                      children: [
                        _LiveStatCard(
                          stream:
                              service
                                  .watchUserCount(),
                          icon:
                              LucideIcons
                                  .users,
                          label:
                              'Users',
                        ),
                        _LiveStatCard(
                          stream:
                              service
                                  .watchJobCount(),
                          icon:
                              LucideIcons
                                  .briefcaseBusiness,
                          label:
                              'Jobs',
                        ),
                        _LiveStatCard(
                          stream:
                              service
                                  .watchOpenJobCount(),
                          icon:
                              LucideIcons
                                  .radioTower,
                          label:
                              'Open jobs',
                        ),
                        _LiveStatCard(
                          stream:
                              service
                                  .watchCompletedJobCount(),
                          icon:
                              LucideIcons
                                  .circleCheck,
                          label:
                              'Completed',
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Management',
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons.users,
                      title:
                          'Users',
                      subtitle:
                          'Search, review, suspend or remove accounts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminUserManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons
                              .briefcaseBusiness,
                      title:
                          'Jobs',
                      subtitle:
                          'View, close or remove platform jobs',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminJobManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons
                              .layoutGrid,
                      title:
                          'Categories',
                      subtitle:
                          'Add, edit, disable or remove categories',
                      trailing:
                          _LiveMiniCount(
                        stream:
                            service
                                .watchCategoryCount(),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminCategoryManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons.star,
                      title:
                          'Reviews',
                      subtitle:
                          'Moderate inappropriate reviews',
                      trailing:
                          _LiveMiniCount(
                        stream:
                            service
                                .watchReviewCount(),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminReviewManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons
                              .messageSquareWarning,
                      title:
                          'Reports',
                      subtitle:
                          'Review complaints and moderation reports',
                      trailing:
                          _LiveMiniCount(
                        stream:
                            service
                                .watchReportCount(),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminReportsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons
                              .settings2,
                      title:
                          'Platform settings',
                      subtitle:
                          'Manage configurable system options',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminPlatformSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _AdminActionTile(
                      icon:
                          LucideIcons
                              .scrollText,
                      title:
                          'Audit logs',
                      subtitle:
                          'Track important administrator actions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminAuditLogsScreen(),
                          ),
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

class _AdminHeader
    extends StatelessWidget {
  const _AdminHeader({
    required this.onLogout,
  });

  final VoidCallback onLogout;

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
        18,
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
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.10,
            ),
            blurRadius: 28,
            offset:
                const Offset(
              0,
              14,
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
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons
                      .shieldCheck,
                  size: 19,
                  color:
                      AppColors.gold,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN CONTROL',
                      style:
                          AppText.label(
                        size: 8,
                        color:
                            AppColors.gold,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Sunday—Monday',
                      style:
                          AppText.heading(
                        size: 15,
                        color:
                            Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip:
                    'Log out',
                onPressed:
                    onLogout,
                icon:
                    const Icon(
                  LucideIcons
                      .logOut,
                  size: 18,
                  color:
                      Colors.white70,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 28,
          ),

          Text(
            'Admin dashboard',
            style:
                AppText.display(
              size: 30,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'Monitor the platform and manage core system data.',
            style:
                AppText.body(
              size: 12,
              color:
                  Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStatCard
    extends StatelessWidget {
  const _LiveStatCard({
    required this.stream,
    required this.icon,
    required this.label,
  });

  final Stream<int> stream;
  final IconData icon;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<int>(
      stream: stream,
      initialData: 0,
      builder: (
        context,
        snapshot,
      ) {
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
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
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
                    Icon(
                  icon,
                  size: 16,
                  color:
                      AppColors.ink,
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${snapshot.data ?? 0}',
                    style:
                        AppText.heading(
                      size: 25,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    label,
                    style:
                        AppText.body(
                      size: 10,
                      color:
                          AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveMiniCount
    extends StatelessWidget {
  const _LiveMiniCount({
    required this.stream,
  });

  final Stream<int> stream;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<int>(
      stream: stream,
      initialData: 0,
      builder: (
        context,
        snapshot,
      ) {
        return Container(
          constraints:
              const BoxConstraints(
            minWidth: 30,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          alignment:
              Alignment.center,
          decoration:
              BoxDecoration(
            color:
                AppColors.goldSoft,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            '${snapshot.data ?? 0}',
            style:
                AppText.label(
              size: 8,
              color:
                  AppColors.ink,
            ),
          ),
        );
      },
    );
  }
}

class _AdminActionTile
    extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          20,
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
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.background,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  size: 17,
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
                      title,
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
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
              const SizedBox(
                width: 8,
              ),
              ?trailing,
              const SizedBox(
                width: 7,
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
    );
  }
}
