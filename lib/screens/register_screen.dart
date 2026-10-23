import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final AuthService _authService =
      AuthService();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  bool _isStrongPassword(
    String password,
  ) {
    if (password.length < 6) {
      return false;
    }

    final hasLetter =
        RegExp(
      r'[A-Za-z]',
    ).hasMatch(password);

    final hasNumber =
        RegExp(
      r'[0-9]',
    ).hasMatch(password);

    final hasSpecialCharacter =
        RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]',
    ).hasMatch(password);

    return hasLetter &&
        hasNumber &&
        hasSpecialCharacter;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final name =
        _nameController.text.trim();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    if (name.isEmpty) {
      _showMessage(
        'Please enter your name.',
      );
      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please enter a password.',
      );
      return;
    }

    if (!_isStrongPassword(password)) {
      _showMessage(
        'Password must be at least 6 characters and include a letter, number, and special character.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Please confirm your password.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool accountCreated = false;

    try {
      await _authService.register(
        email: email,
        password: password,
      );

      accountCreated = true;

      await _authService.updateDisplayName(
        name,
      );

      await _authService
          .sendVerificationEmail();

      await _authService.logout();

      if (!mounted) return;

      await _showVerificationSuccessDialog(
        email,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (accountCreated) {
        try {
          await _authService.logout();
        } catch (_) {}
      }

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account already exists with this email. '
              'If it is not verified yet, use "Resend verification email".';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'Password must be at least 6 characters and include a letter, number, and special character.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password registration is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          if (accountCreated) {
            message =
                'Your account was created, but Firebase temporarily blocked '
                'the verification email because of too many requests. '
                'Please wait a while, then use "Resend verification email".';
          } else {
            message =
                'Too many requests. Please wait a while and try again.';
          }
          break;

        default:
          if (accountCreated) {
            message =
                'Your account was created, but the verification email could '
                'not be sent. Please use "Resend verification email".';
          } else {
            message =
                e.message ??
                'Unable to create account. Please try again.';
          }
      }

      _showMessage(
        message,
      );
    } catch (e) {
      if (accountCreated) {
        try {
          await _authService.logout();
        } catch (_) {}
      }

      if (!mounted) return;

      _showMessage(
        accountCreated
            ? 'Your account was created, but the verification email could '
                'not be sent. Please use "Resend verification email".'
            : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    FocusScope.of(context).unfocus();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    if (email.isEmpty) {
      _showMessage(
        'Enter your email first.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Enter your password to resend verification.',
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final sent =
          await _authService
              .resendVerificationEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (sent) {
        _showMessage(
          'Verification email sent. Please check your inbox and spam folder.',
        );
      } else {
        _showMessage(
          'This email is already verified. You can log in now.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message =
              'Incorrect email or password.';
          break;

        case 'user-not-found':
          message =
              'No account was found with this email.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'too-many-requests':
          message =
              'Too many verification requests. Please wait a while and try again.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              e.message ??
              'Unable to resend verification email.';
      }

      _showMessage(
        message,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to resend verification email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void>
      _showVerificationSuccessDialog(
    String email,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFF172033,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color:
                    Color(
                  0xFFF59E0B,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Verify your email',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Account created successfully.\n\n'
            'A verification email was sent to:\n$email\n\n'
            'Open the email and verify your address. '
            'You will not be able to log in until verification is complete.',
            style:
                const TextStyle(
              color:
                  Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    const Color(
                  0xFFF59E0B,
                ),
                foregroundColor:
                    Colors.black,
              ),
              child:
                  const Text(
                'Back to Log In',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText:
          hint,
      hintStyle:
          const TextStyle(
        color:
            Colors.white54,
      ),
      prefixIcon:
          Icon(
        icon,
        color:
            Colors.white54,
      ),
      suffixIcon:
          suffixIcon,
      filled:
          true,
      fillColor:
          Colors.white.withValues(
        alpha: 0.08,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFF59E0B,
          ),
        ),
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final busy =
        _isLoading ||
        _isResending;

    return Scaffold(
      body: Container(
        width:
            double.infinity,
        height:
            double.infinity,
        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(
                0xFF0F172A,
              ),
              Color(
                0xFF111827,
              ),
              Color(
                0xFF1F2937,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              28,
              28,
              28,
              36,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 68,
                  color:
                      Color(
                    0xFFF59E0B,
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Create Account',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Create your account, then verify your email before logging in.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize:
                        14.5,
                    height:
                        1.5,
                  ),
                ),

                const SizedBox(
                  height: 36,
                ),

                TextField(
                  controller:
                      _nameController,
                  enabled:
                      !busy,
                  textCapitalization:
                      TextCapitalization.words,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    hint:
                        'Full name',
                    icon:
                        Icons.person_outline,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      _emailController,
                  enabled:
                      !busy,
                  keyboardType:
                      TextInputType.emailAddress,
                  autocorrect:
                      false,
                  textCapitalization:
                      TextCapitalization.none,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    hint:
                        'Email address',
                    icon:
                        Icons.email_outlined,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      _passwordController,
                  enabled:
                      !busy,
                  obscureText:
                      _hidePassword,
                  autocorrect:
                      false,
                  enableSuggestions:
                      false,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    hint:
                        'Password',
                    icon:
                        Icons.lock_outline,
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _hidePassword =
                              !_hidePassword;
                        });
                      },
                      icon:
                          Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color:
                            Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Password must be at least 6 characters and include a letter, number, and special character.',
                    style:
                        TextStyle(
                      color:
                          Colors.white60,
                      fontSize:
                          11,
                      height:
                          1.4,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                TextField(
                  controller:
                      _confirmPasswordController,
                  enabled:
                      !busy,
                  obscureText:
                      _hideConfirmPassword,
                  autocorrect:
                      false,
                  enableSuggestions:
                      false,
                  onSubmitted: (_) {
                    if (!busy) {
                      _register();
                    }
                  },
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                  ),
                  decoration:
                      _inputDecoration(
                    hint:
                        'Confirm password',
                    icon:
                        Icons.lock_reset_outlined,
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _hideConfirmPassword =
                              !_hideConfirmPassword;
                        });
                      },
                      icon:
                          Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color:
                            Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      54,
                  child:
                      ElevatedButton(
                    onPressed:
                        busy
                            ? null
                            : _register,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFF59E0B,
                      ),
                      foregroundColor:
                          Colors.black,
                      disabledBackgroundColor:
                          const Color(
                        0xFFB7791F,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                                width:
                                    22,
                                height:
                                    22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.5,
                                  color:
                                      Colors.black,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      52,
                  child:
                      OutlinedButton(
                    onPressed:
                        busy
                            ? null
                            : _resendVerification,
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.white,
                      side:
                          BorderSide(
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.20,
                        ),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                        _isResending
                            ? const SizedBox(
                                width:
                                    21,
                                height:
                                    21,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'Resend Verification Email',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style:
                          TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),

                    TextButton(
                      onPressed:
                          busy
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                      child:
                          const Text(
                        'Log In',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}