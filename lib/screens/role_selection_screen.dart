import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/premium_ui.dart';
import 'client_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _openClient(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientDashboardScreen(),
      ),
    );
  }

  void _openWorker(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkerDashboardScreen(),
      ),
    );
  }

  void _showUserManual(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(
            22,
            14,
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
                        20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.bookOpen,
                        size: 19,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick User Guide',
                            style: AppText.heading(
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose how you want to use the app.',
                            style: AppText.body(
                              size: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _ManualSection(
                  icon: LucideIcons.briefcase,
                  title: 'Client',
                  steps: const [
                    'Post a job.',
                    'Choose a worker.',
                    'Manage the work.',
                    'Complete and review.',
                  ],
                ),

                const SizedBox(height: 12),

                _ManualSection(
                  icon: LucideIcons.wrench,
                  title: 'Worker',
                  steps: const [
                    'Complete your profile.',
                    'Find or receive jobs.',
                    'Apply and get hired.',
                    'Finish work and earn ratings.',
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.repeat2,
                        size: 16,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'You can switch between Client and Worker mode anytime.',
                          style: AppText.body(
                            size: 10.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                          15,
                        ),
                      ),
                    ),
                    child: Text(
                      'Got it',
                      style: AppText.label(
                        size: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tooltip(
                    message: 'User guide',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showUserManual(
                            context,
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration:
                              BoxDecoration(
                            color: AppColors.ink,
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          alignment:
                              Alignment.center,
                          child: Text(
                            'SM',
                            style:
                                GoogleFonts.manrope(
                              color:
                                  AppColors.gold,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 11),

                  Text(
                    'SUNDAY—MONDAY',
                    style: AppText.label(
                      size: 11,
                      color: AppColors.ink,
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      _showUserManual(
                        context,
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleHelp,
                          size: 14,
                          color:
                              AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Guide',
                          style: AppText.label(
                            size: 8.5,
                            color:
                                AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 62),

              Text(
                'How do you want\nto continue?',
                style: AppText.display(
                  size: 36,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'One account. Two ways to get things done.',
                style: AppText.body(
                  size: 14.5,
                ),
              ),

              const SizedBox(height: 46),

              _RoleOption(
                number: '01',
                icon: LucideIcons.briefcase,
                title: 'Client',
                subtitle:
                    'Post work, discover capable people and manage every job in one place.',
                onTap: () {
                  _openClient(
                    context,
                  );
                },
              ),

              const SizedBox(height: 14),

              _RoleOption(
                number: '02',
                icon: LucideIcons.wrench,
                title: 'Worker',
                subtitle:
                    'Find local opportunities that match your skills, time and location.',
                onTap: () {
                  _openWorker(
                    context,
                  );
                },
              ),

              const SizedBox(height: 34),

              Row(
                children: [
                  const Icon(
                    LucideIcons.repeat2,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'You can switch between Client and Worker mode anytime.',
                      style: AppText.body(
                        size: 12,
                        color: AppColors.muted,
                      ),
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
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.heading(
                    size: 15,
                  ),
                ),

                const SizedBox(height: 8),

                ...List.generate(
                  steps.length,
                  (index) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 5,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}.',
                            style: AppText.label(
                              size: 9,
                              color:
                                  AppColors.gold,
                            ),
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          Expanded(
                            child: Text(
                              steps[index],
                              style: AppText.body(
                                size: 10.5,
                                color:
                                    AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOption({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        26,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          26,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            22,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              26,
            ),
            border: Border.all(
              color: AppColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.025,
                ),
                blurRadius: 26,
                offset:
                    const Offset(
                  0,
                  12,
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
                  Text(
                    number,
                    style: AppText.label(
                      color:
                          AppColors.gold,
                      size: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.background,
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.arrowUpRight,
                      size: 17,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              PremiumIconBox(
                icon: icon,
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: AppText.heading(
                  size: 24,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                style: AppText.body(
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}