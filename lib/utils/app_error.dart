import 'package:firebase_auth/firebase_auth.dart';

class AppError {
  const AppError._();

  static String message(
    Object error, {
    String fallback =
        'Something went wrong. Please try again.',
  }) {
    if (error is FirebaseAuthException) {
      return _authError(
        error,
        fallback,
      );
    }

    if (error is FirebaseException) {
      return _firebaseError(
        error,
        fallback,
      );
    }

    final raw =
        error.toString();

    final clean =
        raw
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim();

    if (clean.isEmpty) {
      return fallback;
    }

    if (_looksTechnical(
      clean,
    )) {
      return fallback;
    }

    return clean;
  }

  static String _firebaseError(
    FirebaseException error,
    String fallback,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The request took too long. Please try again.';

      case 'cancelled':
        return 'The request was cancelled. Please try again.';

      case 'already-exists':
        return 'This action has already been completed.';

      case 'not-found':
        return 'The requested information could not be found.';

      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';

      case 'failed-precondition':
        return 'This action cannot be completed right now.';

      case 'aborted':
        return 'The information changed while processing. Please try again.';

      case 'network-request-failed':
        return 'Please check your internet connection and try again.';

      default:
        return fallback;
    }
  }

  static String _authError(
    FirebaseAuthException error,
    String fallback,
  ) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';

      case 'too-many-requests':
        return 'Too many requests. Please try again later.';

      case 'requires-recent-login':
        return 'For security, please log in again before continuing.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'Account could not be found.';

      case 'invalid-credential':
      case 'wrong-password':
        return 'Your account credentials are no longer valid. Please log in again.';

      case 'invalid-email':
        return 'The account email address is invalid.';

      default:
        return fallback;
    }
  }

  static bool _looksTechnical(
    String text,
  ) {
    final lower =
        text.toLowerCase();

    return lower.contains(
          'firebaseexception',
        ) ||
        lower.contains(
          'cloud_firestore/',
        ) ||
        lower.contains(
          'firebase_auth/',
        ) ||
        lower.contains(
          'platformexception',
        ) ||
        lower.contains(
          'stack trace',
        ) ||
        lower.contains(
          '[firebase',
        );
  }
}