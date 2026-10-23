import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final snapshot = await _firestore
        .collection('admins')
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    return data?['active'] == true;
  }

  Future<Map<String, dynamic>?> getCurrentAdminProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection('admins')
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      await _auth.signOut();
      throw Exception('Unable to sign in.');
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      await _auth.signOut();
      throw Exception('Unable to sign in.');
    }

    if (!refreshedUser.emailVerified) {
      await _auth.signOut();
      throw Exception(
        'Admin email is not verified.',
      );
    }

    final isAdmin = await isCurrentUserAdmin();

    if (!isAdmin) {
      await _auth.signOut();
      throw Exception(
        'This account does not have admin access.',
      );
    }

    return refreshedUser;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<int> watchUserCount() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchJobCount() {
    return _firestore
        .collection('jobs')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchOpenJobCount() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchCompletedJobCount() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchCategoryCount() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchReviewCount() {
    return _firestore
        .collection('reviews')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchReportCount() {
    return _firestore
        .collection('reports')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
