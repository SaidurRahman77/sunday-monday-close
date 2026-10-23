import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountStatusService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<String> getCurrentStatus() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return 'signed_out';
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!snapshot.exists) {
      return 'active';
    }

    final data =
        snapshot.data();

    final status =
        data?['accountStatus']
            ?.toString()
            .trim()
            .toLowerCase();

    if (status == null ||
        status.isEmpty) {
      return 'active';
    }

    return status;
  }

  Future<bool> canUseApp() async {
    return await getCurrentStatus() ==
        'active';
  }
}
