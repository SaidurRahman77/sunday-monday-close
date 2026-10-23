import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppColors {
  static const background = Color(0xFFF5F3EE);
  static const surface = Color(0xFFFFFEFB);
  static const ink = Color(0xFF17191D);
  static const inkSoft = Color(0xFF5F636B);
  static const muted = Color(0xFF95989F);

  static const dark = Color(0xFF15171A);
  static const dark2 = Color(0xFF22252A);

  static const gold = Color(0xFFC99A4A);
  static const goldSoft = Color(0xFFF0E3CA);

  static const line = Color(0xFFE5E1D9);
  static const success = Color(0xFF47755B);
}

class AppText {
  static TextStyle display({
    Color color = AppColors.ink,
    double size = 32,
  }) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1.2,
    );
  }

  static TextStyle heading({
    Color color = AppColors.ink,
    double size = 20,
  }) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.4,
    );
  }

  static TextStyle body({
    Color color = AppColors.inkSoft,
    double size = 14,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.55,
    );
  }

  static TextStyle label({
    Color color = AppColors.ink,
    double size = 12,
  }) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }
}

class PremiumIconBox extends StatelessWidget {
  final IconData icon;
  final bool dark;

  const PremiumIconBox({
    super.key,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(
                alpha: 0.08,
              )
            : AppColors.goldSoft,
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(
                  alpha: 0.08,
                )
              : const Color(
                  0xFFE3D2B3,
                ),
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: dark
            ? Colors.white
            : AppColors.ink,
      ),
    );
  }
}

class PremiumSectionHeader
    extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppText.heading(
              size: 18,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.inkSoft,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
            ),
            child: Text(
              action!,
              style: AppText.label(
                color:
                    AppColors.inkSoft,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class PremiumBottomNav
    extends StatelessWidget {
  final int currentIndex;

  const PremiumBottomNav({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        LucideIcons.home,
        'Home',
      ),
      (
        LucideIcons.briefcaseBusiness,
        'Workboard',
      ),
      (
        LucideIcons.search,
        'Discover',
      ),
      (
        LucideIcons.messageCircle,
        'Messages',
      ),
      (
        LucideIcons.user,
        'Profile',
      ),
    ];

    return Container(
      decoration:
          const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.line,
            width: 0.7,
          ),
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        5,
        10,
        5,
        12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(
            items.length,
            (index) {
              final selected =
                  index ==
                      currentIndex;

              return Expanded(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds:
                            180,
                      ),
                      width: 40,
                      height: 32,
                      decoration:
                          BoxDecoration(
                        color: selected
                            ? AppColors
                                .ink
                            : Colors
                                .transparent,
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child: Icon(
                        items[index]
                            .$1,
                        size: 18,
                        color: selected
                            ? Colors
                                .white
                            : AppColors
                                .muted,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      height: 15,
                      child: FittedBox(
                        fit: BoxFit
                            .scaleDown,
                        child: Text(
                          items[index]
                              .$2,
                          maxLines: 1,
                          style:
                              AppText
                                  .label(
                            size: 9.2,
                            color:
                                selected
                                    ? AppColors
                                        .ink
                                    : AppColors
                                        .muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PremiumModeChip
    extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const PremiumModeChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          40,
        ),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            8,
            10,
            8,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white.withValues(
              alpha: 0.07,
            ),
            borderRadius:
                BorderRadius.circular(
              40,
            ),
            border: Border.all(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style:
                    AppText.label(
                  color:
                      Colors.white,
                  size: 10.5,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              const Icon(
                LucideIcons.repeat2,
                color:
                    AppColors.gold,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumActionTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const PremiumActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            17,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Row(
            children: [
              PremiumIconBox(
                icon: icon,
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
                      style:
                          AppText.heading(
                        size: 14.5,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
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

class PremiumStat
    extends StatelessWidget {
  final String value;
  final String label;

  const PremiumStat({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.heading(
              size: 24,
              color:
                  Colors.white,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            style: AppText.body(
              color:
                  Colors.white54,
              size: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}