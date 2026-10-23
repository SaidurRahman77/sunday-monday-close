import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String type,
    required String reason,
    String? targetOwnerId,
    String? targetLabel,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to submit a report.',
      );
    }

    final cleanTargetType =
        targetType.trim().toLowerCase();

    final cleanTargetId =
        targetId.trim();

    final cleanType =
        type.trim();

    final cleanReason =
        reason.trim();

    if (![
      'user',
      'job',
      'review',
    ].contains(
      cleanTargetType,
    )) {
      throw Exception(
        'Invalid report target.',
      );
    }

    if (cleanTargetId.isEmpty) {
      throw Exception(
        'Unable to identify what you are reporting.',
      );
    }

    if (cleanType.isEmpty) {
      throw Exception(
        'Please choose a report type.',
      );
    }

    if (cleanReason.length < 5) {
      throw Exception(
        'Please provide a little more detail.',
      );
    }

    if (cleanReason.length > 500) {
      throw Exception(
        'Report details must be 500 characters or less.',
      );
    }

    if (cleanTargetType == 'user' &&
        cleanTargetId == user.uid) {
      throw Exception(
        'You cannot report your own profile.',
      );
    }

    final safeTarget =
        cleanTargetId.replaceAll(
      '/',
      '_',
    );

    final reportId =
        '${user.uid}_${cleanTargetType}_$safeTarget';

    final reportRef =
        _firestore
            .collection(
              'reports',
            )
            .doc(
              reportId,
            );

    final existing =
        await reportRef.get();

    if (existing.exists) {
      throw Exception(
        'You already submitted a report for this item.',
      );
    }

    await reportRef.set({
      'reportId':
          reportId,
      'reporterId':
          user.uid,
      'reporterEmail':
          user.email ?? '',
      'targetType':
          cleanTargetType,
      'targetId':
          cleanTargetId,
      if (targetOwnerId != null &&
          targetOwnerId.trim().isNotEmpty)
        'targetOwnerId':
            targetOwnerId.trim(),
      if (targetLabel != null &&
          targetLabel.trim().isNotEmpty)
        'targetLabel':
            targetLabel.trim(),
      'type':
          cleanType,
      'reason':
          cleanReason,
      'status':
          'pending',
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}
