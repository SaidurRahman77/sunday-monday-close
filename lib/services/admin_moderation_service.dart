import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminModerationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> watchReviews() {
    return _firestore
        .collection('reviews')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return <String, dynamic>{
          ...doc.data(),
          'reviewId': doc.id,
        };
      }).toList();

      items.sort((a, b) {
        final aCreated = a['createdAt'] as Timestamp?;
        final bCreated = b['createdAt'] as Timestamp?;

        if (aCreated == null && bCreated == null) {
          return 0;
        }

        if (aCreated == null) {
          return 1;
        }

        if (bCreated == null) {
          return -1;
        }

        return bCreated.compareTo(aCreated);
      });

      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> watchReports() {
    return _firestore
        .collection('reports')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return <String, dynamic>{
          ...doc.data(),
          'reportId': doc.id,
        };
      }).toList();

      items.sort((a, b) {
        final aCreated = a['createdAt'] as Timestamp?;
        final bCreated = b['createdAt'] as Timestamp?;

        if (aCreated == null && bCreated == null) {
          return 0;
        }

        if (aCreated == null) {
          return 1;
        }

        if (bCreated == null) {
          return -1;
        }

        return bCreated.compareTo(aCreated);
      });

      return items;
    });
  }

  Future<void> setReviewHidden({
    required String reviewId,
    required bool hidden,
    String reason = '',
  }) async {
    final ref =
        _firestore.collection('reviews').doc(reviewId);

    await ref.update({
      'isHidden': hidden,
      'moderationReason': hidden ? reason.trim() : FieldValue.delete(),
      'hiddenAt': hidden
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'hiddenBy': hidden
          ? _auth.currentUser?.uid
          : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _writeAuditLog(
      action: hidden ? 'review_hidden' : 'review_unhidden',
      targetType: 'review',
      targetId: reviewId,
      details: {
        'reason': reason.trim(),
      },
    );
  }

  Future<void> setReportStatus({
    required String reportId,
    required String status,
    String adminNote = '',
  }) async {
    const allowed = {
      'pending',
      'reviewing',
      'resolved',
    };

    if (!allowed.contains(status)) {
      throw Exception('Invalid report status.');
    }

    final data = <String, dynamic>{
      'status': status,
      'adminNote': adminNote.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    };

    if (status == 'resolved') {
      data['resolvedAt'] = FieldValue.serverTimestamp();
      data['resolvedBy'] = _auth.currentUser?.uid;
    } else {
      data['resolvedAt'] = FieldValue.delete();
      data['resolvedBy'] = FieldValue.delete();
    }

    await _firestore
        .collection('reports')
        .doc(reportId)
        .update(data);

    await _writeAuditLog(
      action: 'report_status_changed',
      targetType: 'report',
      targetId: reportId,
      details: {
        'status': status,
        'adminNote': adminNote.trim(),
      },
    );
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetType,
    required String targetId,
    required Map<String, dynamic> details,
  }) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      return;
    }

    final ref = _firestore
        .collection('admin_audit_logs')
        .doc();

    await ref.set({
      'logId': ref.id,
      'adminId': admin.uid,
      'adminEmail': admin.email,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
