import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxAttempts = 3;
  static const int lockDurationSeconds = 60;

  CollectionReference<Map<String, dynamic>> get _attempts =>
      _firestore.collection('login_attempts');

  Future<Map<String, dynamic>?> checkLock(String email) async {
    final doc = await _attempts.doc(email.toLowerCase()).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    final lockedUntil = data['lockedUntil'];

    if (lockedUntil == null) {
      return null;
    }

    final lockTime = (lockedUntil as Timestamp).toDate();

    if (DateTime.now().isBefore(lockTime)) {
      final remainingSeconds =
          lockTime.difference(DateTime.now()).inSeconds + 1;

      return {
        'locked': true,
        'remainingSeconds': remainingSeconds,
      };
    }

    await _attempts.doc(email.toLowerCase()).set({
      'failedAttempts': 0,
      'lockedUntil': null,
    });

    return null;
  }

  Future<int> recordFailedAttempt(String email) async {
    final docRef = _attempts.doc(email.toLowerCase());
    final doc = await docRef.get();

    int failedAttempts = 0;

    if (doc.exists) {
      final data = doc.data();

      if (data != null) {
        failedAttempts = (data['failedAttempts'] ?? 0) as int;
      }
    }

    failedAttempts++;

    if (failedAttempts >= maxAttempts) {
      final lockedUntil = DateTime.now().add(
        const Duration(seconds: lockDurationSeconds),
      );

      await docRef.set({
        'failedAttempts': failedAttempts,
        'lockedUntil': Timestamp.fromDate(lockedUntil),
      });

      return maxAttempts;
    }

    await docRef.set({
      'failedAttempts': failedAttempts,
      'lockedUntil': null,
    });

    return failedAttempts;
  }

  Future<void> resetAttempts(String email) async {
    await _attempts.doc(email.toLowerCase()).set({
      'failedAttempts': 0,
      'lockedUntil': null,
    });
  }
}