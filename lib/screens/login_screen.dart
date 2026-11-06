import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_status_service.dart';
import '../services/auth_service.dart';
import '../services/login_security_service.dart';
import '../services/platform_settings_service.dart';
import 'admin_login_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';

import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final AccountStatusService _accountStatusService =
      AccountStatusService();

  final LoginSecurityService _securityService =
      LoginSecurityService();

  final PlatformSettingsService _platformSettingsService =
      PlatformSettingsService();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settings =
          await _platformSettingsService.getSettings();

      if (settings['maintenanceMode'] == true) {
        if (!mounted) return;

        final message =
            settings['maintenanceMessage']
                    ?.toString()
                    .trim() ??
                '';

        _showMessage(
          message.isEmpty
              ? 'The platform is temporarily unavailable for maintenance.'
              : message,
        );

        return;
      }

      // Check whether login is temporarily locked
      final lockInfo =
          await _securityService.checkLock(email);

      if (lockInfo != null &&
          lockInfo['locked'] == true) {
        final remainingSeconds =
            lockInfo['remainingSeconds'] as int;

        if (!mounted) return;

        _showMessage(
          'Too many failed attempts. '
          'Try again in $remainingSeconds seconds.',
        );

        return;
      }

      // Firebase login
      await _authService.login(
        email: email,
        password: password,
      );

      // Reload latest Firebase user information
      await _authService.reloadCurrentUser();

      final user = _authService.currentUser;

      if (user == null) {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'Unable to log in.',
        );

        return;
      }

      // Only verified users can continue
      if (!user.emailVerified) {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'Your email is not verified. '
          'Please verify your email before logging in.',
        );

        return;
      }

      // --------------------------------------------------
      // ENSURE FIRESTORE USER DOCUMENT EXISTS
      // --------------------------------------------------

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        await userRef.set({
          'uid': user.uid,
          'name': user.displayName?.trim() ?? '',
          'email': user.email?.trim() ?? email,
          'accountStatus': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Keep basic Auth info synced without overwriting
        // existing client/worker profile information.
        await userRef.set({
          'uid': user.uid,
          'email': user.email?.trim() ?? email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Block suspended or removed accounts.
      final accountStatus =
          await _accountStatusService.getCurrentStatus();

      if (accountStatus == 'suspended') {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'This account has been suspended. '
          'Please contact support or an administrator.',
        );

        return;
      }

      if (accountStatus == 'deleted') {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'This account has been removed and cannot be used.',
        );

        return;
      }

      // Login successful, reset failed attempt counter
      await _securityService.resetAttempts(email);

      // Start a new 15-minute background session.
      await SessionService.startSession();

      if (!mounted) return;

      // Go to role selection screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'invalid-email':
          _showMessage(
            'Please enter a valid email address.',
          );
          break;

        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          final attempts =
              await _securityService.recordFailedAttempt(
            email,
          );

          if (!mounted) return;

          if (attempts >=
              LoginSecurityService.maxAttempts) {
            _showMessage(
              '3 failed attempts. '
              'Login is blocked for 1 minute.',
            );
          } else {
            final remaining =
                LoginSecurityService.maxAttempts -
                    attempts;

            _showMessage(
              'Incorrect email or password. '
              '$remaining attempt(s) remaining.',
            );
          }

          break;

        case 'user-disabled':
          _showMessage(
            'This account has been disabled.',
          );
          break;

        case 'too-many-requests':
          _showMessage(
            'Too many attempts. '
            'Please try again later.',
          );
          break;

        case 'network-request-failed':
          _showMessage(
            'Network error. '
            'Please check your internet connection.',
          );
          break;

        default:
          _showMessage(
            e.message ??
                'Login failed. Please try again.',
          );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF1F2937),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      size: 42,
                      color: Color(0xFFF59E0B),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Sunday-Monday Close',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Turn your free time into opportunity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 45),

                  TextField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction:
                        TextInputAction.next,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor:
                          Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) {
                        _login();
                      }
                    },
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.white54,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword =
                                !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white54,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _login,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFF59E0B),
                        foregroundColor:
                            Colors.black,
                        disabledBackgroundColor:
                            const Color(0xFFF59E0B)
                                .withValues(
                          alpha: 0.55,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                try {
                                  final allowed =
                                      await _platformSettingsService
                                          .areRegistrationsAllowed();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (!allowed) {
                                    _showMessage(
                                      'New registrations are currently disabled.',
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                } catch (_) {
                                  if (!mounted) {
                                    return;
                                  }

                                  _showMessage(
                                    'Unable to check registration availability.',
                                  );
                                }
                              },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color:
                                Color(0xFFF59E0B),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminLoginScreen(),
                              ),
                            );
                          },
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Admin Access',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}