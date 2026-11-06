
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';

import 'services/auth_service.dart';
import 'services/account_status_service.dart';
import 'services/session_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState>
    scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Sunday Monday Close',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate>
    with WidgetsBindingObserver {

  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isCheckingResume = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _restoreSession();
  }

  void _finishLoading(bool authenticated) {
    if (!mounted) return;

    setState(() {
      _isAuthenticated = authenticated;
      _isLoading = false;
    });
  }

  // Check the saved session when the application starts.
  Future<void> _restoreSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await SessionService.clearSession();
        _finishLoading(false);
        return;
      }

      final isValid =
          await SessionService.validateAndResume();

      if (!isValid) {
        await _authService.logout();
        _finishLoading(false);
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null ||
          !currentUser.emailVerified) {
        await _authService.logout();
        _finishLoading(false);
        return;
      }

      // Check whether the account has been suspended or deleted.
      try {
        final status =
            await AccountStatusService().getCurrentStatus();

        if (status == 'suspended' || status == 'deleted') {
          await _authService.logout();
          _finishLoading(false);
          return;
        }
      } catch (_) {
        // Keep the locally valid session if status
        // cannot be checked because of a network issue.
      }

      _finishLoading(true);

    } catch (e) {
      await _authService.logout();
      _finishLoading(false);
    }
  }

  // Monitor application background and foreground states.
  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {

      SessionService.markBackgrounded();

    } else if (state == AppLifecycleState.resumed) {

      _checkSessionOnResume();
    }
  }

  // Validate the session when the user returns to the app.
  Future<void> _checkSessionOnResume() async {
    if (_isCheckingResume || _isLoading) return;

    _isCheckingResume = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (_isAuthenticated) {
          await _redirectToLogin();
        }
        return;
      }

      final isValid =
          await SessionService.validateAndResume();

      if (!isValid || !user.emailVerified) {
        await _authService.logout();
        await _redirectToLogin();
      }

    } catch (e) {
      debugPrint('Session validation error: $e');

    } finally {
      _isCheckingResume = false;
    }
  }

  // Redirect to login after session expiration.
  Future<void> _redirectToLogin() async {
    if (!mounted) return;

    setState(() {
      _isAuthenticated = false;
    });

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const RoleSelectionScreen();
    }

    return const LoginScreen();
  }
}
