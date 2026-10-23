import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class JobInvitationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  User? get currentUser =>
      _auth.currentUser;

  Future<List<Map<String, dynamic>>>
      getMyOpenJobs() async {
    final user = currentUser;

    if (user == null) {
      return [];
    }

    final snapshot =
        await _firestore
            .collection('jobs')
            .where(
              'clientId',
              isEqualTo: user.uid,
            )
            .get();

    final jobs =
        snapshot.docs
            .map(
              (doc) => {
                ...doc.data(),
                'jobId': doc.id,
              },
            )
            .where(
              (job) =>
                  job['status']
                      ?.toString()
                      .toLowerCase() ==
                  'open',
            )
            .toList();

    jobs.sort(
      (a, b) {
        final aTime =
            a['createdAt'];

        final bTime =
            b['createdAt'];

        if (aTime is Timestamp &&
            bTime is Timestamp) {
          return bTime.compareTo(
            aTime,
          );
        }

        return 0;
      },
    );

    return jobs;
  }

  Stream<Map<String, String>>
      getInvitationStatusesForWorker({
    required String workerId,
  }) {
    final user = currentUser;

    if (user == null) {
      return Stream.value(
        {},
      );
    }

    return _firestore
        .collection(
          'job_invitations',
        )
        .where(
          'clientId',
          isEqualTo:
              user.uid,
        )
        .where(
          'workerId',
          isEqualTo:
              workerId.trim(),
        )
        .snapshots()
        .map(
      (snapshot) {
        final statuses =
            <String, String>{};

        for (final doc
            in snapshot.docs) {
          final data =
              doc.data();

          final jobId =
              data['jobId']
                      ?.toString() ??
                  '';

          final status =
              data['status']
                      ?.toString()
                      .toLowerCase() ??
                  '';

          if (jobId.isNotEmpty) {
            statuses[jobId] =
                status;
          }
        }

        return statuses;
      },
    );
  }

  Future<void> inviteWorker({
    required String workerId,
    required String jobId,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message:
            'You must be signed in.',
      );
    }

    final cleanWorkerId =
        workerId.trim();

    final cleanJobId =
        jobId.trim();

    if (cleanWorkerId.isEmpty ||
        cleanJobId.isEmpty) {
      throw ArgumentError(
        'Worker and job are required.',
      );
    }

    if (cleanWorkerId ==
        user.uid) {
      throw StateError(
        'You cannot invite yourself.',
      );
    }

    final invitationId =
        '${cleanWorkerId}_$cleanJobId';

    final invitationRef =
        _firestore
            .collection(
              'job_invitations',
            )
            .doc(
              invitationId,
            );

    final existingSnapshot =
        await _firestore
            .collection(
              'job_invitations',
            )
            .where(
              'clientId',
              isEqualTo:
                  user.uid,
            )
            .where(
              'workerId',
              isEqualTo:
                  cleanWorkerId,
            )
            .where(
              'jobId',
              isEqualTo:
                  cleanJobId,
            )
            .get();

    String? existingStatus;

    if (existingSnapshot
        .docs
        .isNotEmpty) {
      existingStatus =
          existingSnapshot
              .docs
              .first
              .data()['status']
              ?.toString()
              .toLowerCase();
    }

    if (existingStatus ==
            'pending' ||
        existingStatus ==
            'accepted') {
      throw StateError(
        existingStatus ==
                'accepted'
            ? 'This worker has already accepted this job.'
            : 'This worker has already been invited to this job.',
      );
    }

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(
              cleanJobId,
            );

    late String jobTitle;

    await _firestore.runTransaction(
      (transaction) async {
        final jobSnapshot =
            await transaction.get(
          jobRef,
        );

        if (!jobSnapshot.exists) {
          throw StateError(
            'Job no longer exists.',
          );
        }

        final job =
            jobSnapshot.data()!;

        final clientId =
            job['clientId']
                ?.toString();

        final status =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (clientId !=
            user.uid) {
          throw StateError(
            'You can only invite workers to your own jobs.',
          );
        }

        if (status !=
            'open') {
          throw StateError(
            'Only open jobs can receive invitations.',
          );
        }

        jobTitle =
            job['title']
                    ?.toString()
                    .trim() ??
                'Job';

        if (existingStatus ==
            'rejected') {
          transaction.update(
            invitationRef,
            {
              'status':
                  'pending',
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );
        } else {
          transaction.set(
            invitationRef,
            {
              'invitationId':
                  invitationId,
              'jobId':
                  cleanJobId,
              'jobTitle':
                  jobTitle,
              'clientId':
                  user.uid,
              'workerId':
                  cleanWorkerId,
              'status':
                  'pending',
              'createdAt':
                  FieldValue
                      .serverTimestamp(),
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
          );
        }
      },
    );

    await _sendNotificationSafely(
      recipientId:
          cleanWorkerId,
      type:
          'job_invitation',
      title:
          'New job invitation',
      message:
          'You were invited to "$jobTitle".',
      jobId:
          cleanJobId,
    );
  }

  Stream<List<Map<String, dynamic>>>
      getWorkerInvitations() {
    final user = currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection(
          'job_invitations',
        )
        .where(
          'workerId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final invitations =
            snapshot.docs
                .map(
                  (doc) => {
                    ...doc.data(),
                    'invitationId':
                        doc.id,
                  },
                )
                .toList();

        invitations.sort(
          (a, b) {
            final aTime =
                a['createdAt'];

            final bTime =
                b['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(
                aTime,
              );
            }

            return 0;
          },
        );

        return invitations;
      },
    );
  }

  Future<void> acceptInvitation({
    required String invitationId,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message:
            'You must be signed in.',
      );
    }

    final invitationRef =
        _firestore
            .collection(
              'job_invitations',
            )
            .doc(
              invitationId.trim(),
            );

    late String clientId;
    late String jobId;
    late String jobTitle;

    await _firestore.runTransaction(
      (transaction) async {
        final invitationSnapshot =
            await transaction.get(
          invitationRef,
        );

        if (!invitationSnapshot.exists) {
          throw StateError(
            'Invitation no longer exists.',
          );
        }

        final invitation =
            invitationSnapshot.data()!;

        final workerId =
            invitation['workerId']
                ?.toString();

        clientId =
            invitation['clientId']
                    ?.toString() ??
                '';

        jobId =
            invitation['jobId']
                    ?.toString() ??
                '';

        jobTitle =
            invitation['jobTitle']
                    ?.toString()
                    .trim() ??
                'Job';

        final status =
            invitation['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (workerId !=
            user.uid) {
          throw StateError(
            'This invitation is not for you.',
          );
        }

        if (status !=
            'pending') {
          throw StateError(
            'This invitation has already been handled.',
          );
        }

        final jobRef =
            _firestore
                .collection('jobs')
                .doc(jobId);

        final jobSnapshot =
            await transaction.get(
          jobRef,
        );

        if (!jobSnapshot.exists) {
          throw StateError(
            'Job no longer exists.',
          );
        }

        final job =
            jobSnapshot.data()!;

        final jobStatus =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (jobStatus !=
            'open') {
          throw StateError(
            'This job is no longer available.',
          );
        }

        if (job['clientId'] !=
            clientId) {
          throw StateError(
            'Invalid invitation.',
          );
        }

        transaction.update(
          invitationRef,
          {
            'status':
                'accepted',
            'acceptedAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        transaction.update(
          jobRef,
          {
            'status':
                'assigned',
            'assignedWorkerId':
                user.uid,
            'assignedAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );
      },
    );

    if (clientId.isNotEmpty) {
      await _sendNotificationSafely(
        recipientId:
            clientId,
        type:
            'invitation_accepted',
        title:
            'Invitation accepted',
        message:
            'A worker accepted your invitation for "$jobTitle".',
        jobId:
            jobId,
      );
    }
  }

  Future<void> rejectInvitation({
    required String invitationId,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message:
            'You must be signed in.',
      );
    }

    final invitationRef =
        _firestore
            .collection(
              'job_invitations',
            )
            .doc(
              invitationId.trim(),
            );

    late String clientId;
    late String jobId;
    late String jobTitle;

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          invitationRef,
        );

        if (!snapshot.exists) {
          throw StateError(
            'Invitation no longer exists.',
          );
        }

        final invitation =
            snapshot.data()!;

        if (invitation['workerId'] !=
            user.uid) {
          throw StateError(
            'This invitation is not for you.',
          );
        }

        final status =
            invitation['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (status !=
            'pending') {
          throw StateError(
            'This invitation has already been handled.',
          );
        }

        clientId =
            invitation['clientId']
                    ?.toString() ??
                '';

        jobId =
            invitation['jobId']
                    ?.toString() ??
                '';

        jobTitle =
            invitation['jobTitle']
                    ?.toString()
                    .trim() ??
                'Job';

        transaction.update(
          invitationRef,
          {
            'status':
                'rejected',
            'rejectedAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );
      },
    );

    if (clientId.isNotEmpty) {
      await _sendNotificationSafely(
        recipientId:
            clientId,
        type:
            'invitation_rejected',
        title:
            'Invitation declined',
        message:
            'A worker declined your invitation for "$jobTitle".',
        jobId:
            jobId,
      );
    }
  }

  Future<void>
      _sendNotificationSafely({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    String? jobId,
  }) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      await _notificationService
          .createNotification(
        recipientId:
            recipientId,
        type:
            type,
        title:
            title,
        message:
            message,
        jobId:
            jobId,
        actorId:
            user.uid,
      );
    } catch (_) {
      // Notification failure must not
      // break invitation action.
    }
  }
}