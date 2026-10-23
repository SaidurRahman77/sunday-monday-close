import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/premium_ui.dart';
import 'login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
  });

  @override
  State<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends State<AccountSettingsScreen> {
  bool _sendingPasswordReset = false;
  bool _sendingVerification = false;
  bool _loggingOut = false;

  User? get _user =>
      FirebaseAuth.instance.currentUser;

  Future<void> _sendPasswordReset() async {
    if (_sendingPasswordReset) {
      return;
    }

    final email =
        _user?.email?.trim() ?? '';

    if (email.isEmpty) {
      _showMessage(
        'No email address is available for this account.',
      );
      return;
    }

    setState(() {
      _sendingPasswordReset = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password reset link sent to $email.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _authMessage(
          e,
          fallback:
              'Unable to send password reset email.',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to send password reset email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingPasswordReset = false;
        });
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_sendingVerification) {
      return;
    }

    final user =
        _user;

    if (user == null) {
      _showMessage(
        'You are not signed in.',
      );
      return;
    }

    await user.reload();

    final refreshedUser =
        FirebaseAuth.instance.currentUser;

    if (refreshedUser == null) {
      return;
    }

    if (refreshedUser.emailVerified) {
      if (mounted) {
        setState(() {});
      }

      _showMessage(
        'Your email is already verified.',
      );
      return;
    }

    setState(() {
      _sendingVerification = true;
    });

    try {
      await refreshedUser
          .sendEmailVerification();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Verification email sent.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _authMessage(
          e,
          fallback:
              'Unable to send verification email.',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to send verification email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingVerification = false;
        });
      }
    }
  }

  Future<void> _refreshAccount() async {
    try {
      await _user?.reload();

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to refresh account information.',
      );
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors.surface,
          surfaceTintColor:
              Colors.transparent,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
          title: Text(
            'Log out?',
            style:
                AppText.heading(
              size:
                  19,
            ),
          ),
          content: Text(
            'You will need to sign in again to access your account.',
            style:
                AppText.body(
              size:
                  12,
              color:
                  AppColors.muted,
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
              child: const Text(
                'Cancel',
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
                  ElevatedButton.styleFrom(
                elevation:
                    0,
                backgroundColor:
                    AppColors.ink,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Log out',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {
      _loggingOut = true;
    });

    try {
      await FirebaseAuth.instance
          .signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (
          route,
        ) =>
            false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loggingOut = false;
      });

      _showMessage(
        'Unable to log out. Please try again.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    final email =
        user?.email?.trim() ?? '';

    final verified =
        user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
            ),

            Expanded(
              child:
                  SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _AccountCard(
                      email:
                          email,
                      verified:
                          verified,
                    ),

                    const SizedBox(
                      height:
                          28,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Security',
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    _SettingsTile(
                      icon:
                          LucideIcons.keyRound,
                      title:
                          'Change password',
                      subtitle:
                          'Receive a secure password reset link by email',
                      loading:
                          _sendingPasswordReset,
                      onTap:
                          _sendingPasswordReset
                              ? null
                              : _sendPasswordReset,
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    _SettingsTile(
                      icon:
                          verified
                              ? LucideIcons
                                  .badgeCheck
                              : LucideIcons
                                  .mailCheck,
                      title:
                          verified
                              ? 'Email verified'
                              : 'Verify email',
                      subtitle:
                          verified
                              ? 'Your account email has been verified'
                              : 'Send a new verification email',
                      loading:
                          _sendingVerification,
                      onTap:
                          verified ||
                                  _sendingVerification
                              ? null
                              : _sendVerificationEmail,
                    ),

                    const SizedBox(
                      height:
                          10,
                    ),

                    _SettingsTile(
                      icon:
                          LucideIcons.refreshCw,
                      title:
                          'Refresh account',
                      subtitle:
                          'Check the latest verification status',
                      onTap:
                          _refreshAccount,
                    ),

                    const SizedBox(
                      height:
                          30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'About',
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    const _InfoCard(),

                    const SizedBox(
                      height:
                          30,
                    ),

                    const PremiumSectionHeader(
                      title:
                          'Session',
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    _SettingsTile(
                      icon:
                          LucideIcons.logOut,
                      title:
                          'Log out',
                      subtitle:
                          'Sign out from this device',
                      danger:
                          true,
                      loading:
                          _loggingOut,
                      onTap:
                          _loggingOut
                              ? null
                              : _logout,
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

class _SettingsHeader
    extends StatelessWidget {
  const _SettingsHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        18,
        14,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
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
                width:
                    44,
                height:
                    44,
                child: Center(
                  child: Icon(
                    LucideIcons
                        .arrowLeft,
                    size:
                        20,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Account settings',
                  style:
                      AppText.heading(
                    size:
                        19,
                  ),
                ),
                Text(
                  'Security and account information',
                  style:
                      AppText.body(
                    size:
                        10.5,
                    color:
                        AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          const PremiumIconBox(
            icon:
                LucideIcons.settings,
          ),
        ],
      ),
    );
  }
}

class _AccountCard
    extends StatelessWidget {
  const _AccountCard({
    required this.email,
    required this.verified,
  });

  final String email;
  final bool verified;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
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
      child: Row(
        children: [
          Container(
            width:
                54,
            height:
                54,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child:
                const Icon(
              LucideIcons.userRound,
              color:
                  AppColors.ink,
              size:
                  22,
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  email.isEmpty
                      ? 'Signed in account'
                      : email,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      AppText.heading(
                    size:
                        14,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Row(
                  children: [
                    Icon(
                      verified
                          ? LucideIcons
                              .circleCheck
                          : LucideIcons
                              .circleAlert,
                      size:
                          13,
                      color:
                          verified
                              ? AppColors.gold
                              : Colors.white54,
                    ),

                    const SizedBox(
                      width:
                          5,
                    ),

                    Text(
                      verified
                          ? 'Verified account'
                          : 'Verification required',
                      style:
                          AppText.body(
                        size:
                            10.5,
                        color:
                            Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile
    extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.loading = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;

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
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            16,
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
                width:
                    44,
                height:
                    44,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      danger
                          ? AppColors
                              .background
                          : AppColors
                              .goldSoft,
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  size:
                      18,
                  color:
                      danger
                          ? Colors.redAccent
                          : AppColors.ink,
                ),
              ),

              const SizedBox(
                width:
                    13,
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
                        size:
                            13.5,
                        color:
                            danger
                                ? Colors.redAccent
                                : AppColors.ink,
                      ),
                    ),

                    const SizedBox(
                      height:
                          3,
                    ),

                    Text(
                      subtitle,
                      style:
                          AppText.body(
                        size:
                            10.5,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              if (loading)
                const SizedBox(
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
              else if (onTap != null)
                const Icon(
                  LucideIcons
                      .chevronRight,
                  size:
                      18,
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

class _InfoCard
    extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
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
          Text(
            'Sunday-Monday Close',
            style:
                AppText.heading(
              size:
                  14,
            ),
          ),

          const SizedBox(
            height:
                5,
          ),

          Text(
            'A service marketplace connecting clients with skilled workers.',
            style:
                AppText.body(
              size:
                  11,
              color:
                  AppColors.muted,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  10,
              vertical:
                  6,
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
            child: Text(
              'VERSION 1.0',
              style:
                  AppText.label(
                size:
                    8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _authMessage(
  FirebaseAuthException error, {
  required String fallback,
}) {
  switch (error.code) {
    case 'invalid-email':
      return 'The account email is invalid.';

    case 'too-many-requests':
      return 'Too many requests. Please try again later.';

    case 'network-request-failed':
      return 'Please check your internet connection.';

    case 'user-not-found':
      return 'Account could not be found.';

    default:
      return fallback;
  }
}