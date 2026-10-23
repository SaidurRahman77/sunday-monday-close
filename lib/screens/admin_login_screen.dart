import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_service.dart';
import '../widgets/premium_ui.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
  });

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final AdminService _adminService =
      AdminService();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  bool _validEmail(
    String value,
  ) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(
      value.trim(),
    );
  }

  Future<void> _login() async {
    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    if (!_validEmail(email)) {
      _showMessage(
        'Enter a valid admin email.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Enter your password.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _adminService.login(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AdminDashboardScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Admin login failed.';

      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          message =
              'Incorrect email or password.';
          break;

        case 'user-disabled':
          message =
              'This account is disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Try again later.';
          break;

        case 'network-request-failed':
          message =
              'Check your internet connection.';
          break;

        default:
          message =
              e.message ??
                  message;
      }

      _showMessage(
        message,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final text =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showMessage(
        text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
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
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            30,
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
                      onTap:
                          _loading
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      child:
                          Container(
                        width: 42,
                        height: 42,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          border:
                              Border.all(
                            color:
                                AppColors.line,
                          ),
                        ),
                        child:
                            const Icon(
                          LucideIcons
                              .arrowLeft,
                          size: 18,
                          color:
                              AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 11,
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
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons
                              .shieldCheck,
                          size: 13,
                          color:
                              AppColors.ink,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          'ADMIN',
                          style:
                              AppText.label(
                            size: 9,
                            color:
                                AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 56,
              ),

              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.dark,
                  borderRadius:
                      BorderRadius.circular(
                    19,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons
                      .shieldCheck,
                  color:
                      AppColors.gold,
                  size: 25,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              Text(
                'Admin access',
                style:
                    AppText.display(
                  size: 34,
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Text(
                'Sign in with an approved administrator account.',
                style:
                    AppText.body(
                  size: 13.5,
                ),
              ),

              const SizedBox(
                height: 34,
              ),

              _AdminField(
                controller:
                    _emailController,
                label: 'Email',
                hint:
                    'admin@example.com',
                icon:
                    LucideIcons.mail,
                keyboardType:
                    TextInputType
                        .emailAddress,
                enabled:
                    !_loading,
              ),

              const SizedBox(
                height: 14,
              ),

              _AdminField(
                controller:
                    _passwordController,
                label: 'Password',
                hint:
                    'Enter password',
                icon:
                    LucideIcons.lockKeyhole,
                obscureText:
                    _hidePassword,
                enabled:
                    !_loading,
                suffix:
                    IconButton(
                  onPressed:
                      _loading
                          ? null
                          : () {
                              setState(
                                () {
                                  _hidePassword =
                                      !_hidePassword;
                                },
                              );
                            },
                  icon: Icon(
                    _hidePassword
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                    size: 18,
                    color:
                        AppColors.muted,
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : _login,
                  style:
                      ElevatedButton
                          .styleFrom(
                    elevation: 0,
                    backgroundColor:
                        AppColors.dark,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const Icon(
                                  LucideIcons
                                      .logIn,
                                  size: 17,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'Enter Admin Panel',
                                  style:
                                      AppText.label(
                                    size: 11,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons
                          .shieldAlert,
                      size: 17,
                      color:
                          AppColors.gold,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        'Only accounts approved in the admin registry can enter this area.',
                        style:
                            AppText.body(
                          size: 11,
                          color:
                              AppColors.muted,
                        ),
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

class _AdminField
    extends StatelessWidget {
  const _AdminField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController
      controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType?
      keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style:
              AppText.label(
            size: 8.5,
            color:
                AppColors.muted,
          ),
        ),
        const SizedBox(
          height: 7,
        ),
        TextField(
          controller:
              controller,
          enabled: enabled,
          keyboardType:
              keyboardType,
          obscureText:
              obscureText,
          autocorrect: false,
          enableSuggestions:
              !obscureText,
          style:
              AppText.body(
            size: 13,
            color:
                AppColors.ink,
          ),
          decoration:
              InputDecoration(
            hintText: hint,
            hintStyle:
                AppText.body(
              size: 12,
              color:
                  AppColors.muted,
            ),
            prefixIcon:
                Icon(
              icon,
              size: 18,
              color:
                  AppColors.muted,
            ),
            suffixIcon:
                suffix,
            filled: true,
            fillColor:
                AppColors.surface,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  BorderSide(
                color:
                    AppColors.line,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  BorderSide(
                color:
                    AppColors.line,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              borderSide:
                  const BorderSide(
                color:
                    AppColors.gold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
