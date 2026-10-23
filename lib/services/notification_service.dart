import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    String? jobId,
    String? applicationId,
    String? actorId,
  }) async {
    final cleanRecipientId = recipientId.trim();

    if (cleanRecipientId.isEmpty) {
      return;
    }

    await _firestore
        .collection('notifications')
        .add({
      'recipientId': cleanRecipientId,
      'type': type.trim(),
      'title': title.trim(),
      'message': message.trim(),
      'jobId': jobId?.trim(),
      'applicationId': applicationId?.trim(),
      'actorId': actorId?.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>>
      getMyNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where(
          'recipientId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final notifications =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'notificationId': doc.id,
            };
          },
        ).toList();

        notifications.sort(
          (a, b) {
            final aTime =
                a['createdAt'] as Timestamp?;
            final bTime =
                b['createdAt'] as Timestamp?;

            if (aTime == null &&
                bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(aTime);
          },
        );

        return notifications;
      },
    );
  }

  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where(
          'recipientId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.where(
          (doc) {
            final data = doc.data();

            return data['isRead'] != true;
          },
        ).length;
      },
    );
  }

  Future<void> markAsRead(
    String notificationId,
  ) async {
    final user = _auth.currentUser;

    if (user == null ||
        notificationId.trim().isEmpty) {
      return;
    }

    final ref = _firestore
        .collection('notifications')
        .doc(notificationId);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();

    if (data == null) {
      return;
    }

    if (data['recipientId'] != user.uid) {
      throw Exception(
        'You cannot update this notification.',
      );
    }

    if (data['isRead'] == true) {
      return;
    }

    await ref.update({
      'isRead': true,
      'readAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where(
          'recipientId',
          isEqualTo: user.uid,
        )
        .get();

    final unreadDocs =
        snapshot.docs.where(
      (doc) =>
          doc.data()['isRead'] != true,
    );

    if (unreadDocs.isEmpty) {
      return;
    }

    WriteBatch batch =
        _firestore.batch();

    var operationCount = 0;

    for (final doc in unreadDocs) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
          'readAt':
              FieldValue.serverTimestamp(),
        },
      );

      operationCount++;

      if (operationCount == 400) {
        await batch.commit();

        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }
}