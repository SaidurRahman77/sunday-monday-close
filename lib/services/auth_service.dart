import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // --------------------------------------------------
  // CURRENT USER
  // --------------------------------------------------

  User? get currentUser =>
      _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // --------------------------------------------------
  // REGISTER
  // --------------------------------------------------

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // --------------------------------------------------
  // EMAIL VERIFICATION
  // --------------------------------------------------

  Future<void> sendVerificationEmail() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message:
            'No signed-in user found.',
      );
    }

    await user.reload();

    final refreshedUser =
        _auth.currentUser;

    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message:
            'No signed-in user found.',
      );
    }

    if (refreshedUser.emailVerified) {
      return;
    }

    await refreshedUser
        .sendEmailVerification();
  }

  Future<bool> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user =
          _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message:
              'Unable to load account.',
        );
      }

      await user.reload();

      final refreshedUser =
          _auth.currentUser;

      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message:
              'Unable to load account.',
        );
      }

      if (refreshedUser.emailVerified) {
        return false;
      }

      await refreshedUser
          .sendEmailVerification();

      return true;
    } finally {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    }
  }

  Future<bool> isEmailVerified() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    return _auth.currentUser
            ?.emailVerified ??
        false;
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> reloadCurrentUser() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    await user.reload();
  }

  // --------------------------------------------------
  // PROFILE NAME
  // --------------------------------------------------

  Future<void> updateDisplayName(
    String name,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message:
            'No signed-in user found.',
      );
    }

    await user.updateDisplayName(
      name.trim(),
    );

    await user.reload();
  }

  // --------------------------------------------------
  // PASSWORD RESET
  // --------------------------------------------------

  Future<void> resetPassword(
    String email,
  ) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> logout() async {
    await _auth.signOut();
  }
}