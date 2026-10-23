import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _users =>
          _firestore.collection('users');

  Stream<List<Map<String, dynamic>>>
      watchUsers() {
    return _users.snapshots().map(
      (snapshot) {
        final users =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'userId': doc.id,
            };
          },
        ).toList();

        users.sort(
          (a, b) {
            final aName =
                a['name']
                        ?.toString()
                        .toLowerCase() ??
                    '';

            final bName =
                b['name']
                        ?.toString()
                        .toLowerCase() ??
                    '';

            return aName.compareTo(
              bName,
            );
          },
        );

        return users;
      },
    );
  }

  Future<void> suspendUser({
    required String userId,
    required String userName,
    String reason = '',
  }) async {
    _ensureNotSelf(
      userId,
    );

    await _users.doc(userId).update({
      'accountStatus': 'suspended',
      'suspendedAt':
          FieldValue.serverTimestamp(),
      'suspendedBy':
          _auth.currentUser?.uid,
      'suspensionReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'user_suspended',
      targetId: userId,
      details: {
        'userName': userName,
        'reason': reason.trim(),
      },
    );
  }

  Future<void> unsuspendUser({
    required String userId,
    required String userName,
  }) async {
    _ensureNotSelf(
      userId,
    );

    await _users.doc(userId).update({
      'accountStatus': 'active',
      'suspendedAt':
          FieldValue.delete(),
      'suspendedBy':
          FieldValue.delete(),
      'suspensionReason':
          FieldValue.delete(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'user_unsuspended',
      targetId: userId,
      details: {
        'userName': userName,
      },
    );
  }

  Future<void> removeUser({
    required String userId,
    required String userName,
    String reason = '',
  }) async {
    _ensureNotSelf(
      userId,
    );

    await _users.doc(userId).update({
      'accountStatus': 'deleted',
      'deletedAt':
          FieldValue.serverTimestamp(),
      'deletedBy':
          _auth.currentUser?.uid,
      'deletionReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'user_removed',
      targetId: userId,
      details: {
        'userName': userName,
        'reason': reason.trim(),
      },
    );
  }

  Future<void> restoreUser({
    required String userId,
    required String userName,
  }) async {
    _ensureNotSelf(
      userId,
    );

    await _users.doc(userId).update({
      'accountStatus': 'active',
      'deletedAt':
          FieldValue.delete(),
      'deletedBy':
          FieldValue.delete(),
      'deletionReason':
          FieldValue.delete(),
      'suspendedAt':
          FieldValue.delete(),
      'suspendedBy':
          FieldValue.delete(),
      'suspensionReason':
          FieldValue.delete(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'user_restored',
      targetId: userId,
      details: {
        'userName': userName,
      },
    );
  }

  void _ensureNotSelf(
    String userId,
  ) {
    final currentUid =
        _auth.currentUser?.uid;

    if (currentUid == userId) {
      throw Exception(
        'You cannot moderate your own admin account.',
      );
    }
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetId,
    required Map<String, dynamic>
        details,
  }) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      return;
    }

    final ref =
        _firestore
            .collection(
              'admin_audit_logs',
            )
            .doc();

    await ref.set({
      'logId': ref.id,
      'adminId': admin.uid,
      'adminEmail':
          admin.email,
      'action': action,
      'targetType': 'user',
      'targetId': targetId,
      'details': details,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}
