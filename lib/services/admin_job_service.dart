import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminJobService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _jobs =>
          _firestore.collection('jobs');

  Stream<List<Map<String, dynamic>>> watchJobs() {
    return _jobs.snapshots().map(
      (snapshot) {
        final jobs =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'jobId': doc.id,
            };
          },
        ).toList();

        jobs.sort(
          (a, b) {
            final aCreated =
                a['createdAt'] as Timestamp?;

            final bCreated =
                b['createdAt'] as Timestamp?;

            if (aCreated == null &&
                bCreated == null) {
              return 0;
            }

            if (aCreated == null) {
              return 1;
            }

            if (bCreated == null) {
              return -1;
            }

            return bCreated.compareTo(
              aCreated,
            );
          },
        );

        return jobs;
      },
    );
  }

  Future<void> closeJob({
    required String jobId,
    required String jobTitle,
    String reason = '',
  }) async {
    final ref =
        _jobs.doc(jobId);

    final snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw Exception(
        'This job no longer exists.',
      );
    }

    final data =
        snapshot.data();

    final status =
        data?['status']
            ?.toString()
            .toLowerCase() ??
            '';

    if (status != 'open') {
      throw Exception(
        'Only open jobs can be closed.',
      );
    }

    await ref.update({
      'status': 'closed',
      'closedAt':
          FieldValue.serverTimestamp(),
      'closedByAdminId':
          _auth.currentUser?.uid,
      'adminCloseReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'job_closed',
      targetId: jobId,
      details: {
        'title': jobTitle,
        'reason': reason.trim(),
      },
    );
  }

  Future<void> cancelJob({
    required String jobId,
    required String jobTitle,
    String reason = '',
  }) async {
    final ref =
        _jobs.doc(jobId);

    final snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw Exception(
        'This job no longer exists.',
      );
    }

    final data =
        snapshot.data();

    final status =
        data?['status']
            ?.toString()
            .toLowerCase() ??
            '';

    if (status == 'completed' ||
        status == 'cancelled') {
      throw Exception(
        'This job cannot be cancelled in its current status.',
      );
    }

    await ref.update({
      'status': 'cancelled',
      'cancelledAt':
          FieldValue.serverTimestamp(),
      'cancelledByAdminId':
          _auth.currentUser?.uid,
      'adminCancelReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: 'job_cancelled',
      targetId: jobId,
      details: {
        'title': jobTitle,
        'previousStatus': status,
        'reason': reason.trim(),
      },
    );
  }

  Future<void> removeJob({
    required String jobId,
    required String jobTitle,
    String reason = '',
  }) async {
    final ref =
        _jobs.doc(jobId);

    final snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw Exception(
        'This job no longer exists.',
      );
    }

    final data =
        snapshot.data() ??
            <String, dynamic>{};

    await _writeAuditLog(
      action: 'job_removed',
      targetId: jobId,
      details: {
        'title': jobTitle,
        'status':
            data['status']?.toString() ?? '',
        'clientId':
            data['clientId']?.toString() ?? '',
        'reason': reason.trim(),
      },
    );

    await ref.delete();
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetId,
    required Map<String, dynamic> details,
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
      'adminEmail': admin.email,
      'action': action,
      'targetType': 'job',
      'targetId': targetId,
      'details': details,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}
