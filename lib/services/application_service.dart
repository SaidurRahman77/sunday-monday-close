import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class ApplicationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  User? get currentUser =>
      _auth.currentUser;

  // --------------------------------------------------
  // APPLY TO JOB
  // --------------------------------------------------

  Future<void> applyToJob({
    required String jobId,
    required int matchScore,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to apply for a job.',
      );
    }

    final workerId =
        user.uid;

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(jobId);

    final workerRef =
        _firestore
            .collection('users')
            .doc(workerId);

    final applicationId =
        '${jobId}_$workerId';

    final applicationRef =
        _firestore
            .collection('applications')
            .doc(applicationId);

    String clientId = '';
    String jobTitle = 'Job';
    String workerNameForNotification =
        'A worker';

    await _firestore.runTransaction(
      (transaction) async {
        final jobSnapshot =
            await transaction.get(
          jobRef,
        );

        if (!jobSnapshot.exists) {
          throw Exception(
            'This job no longer exists.',
          );
        }

        final job =
            jobSnapshot.data();

        if (job == null) {
          throw Exception(
            'Unable to load job information.',
          );
        }

        if (job['status'] != 'open') {
          throw Exception(
            'This job is no longer accepting applications.',
          );
        }

        clientId =
            job['clientId']
                    ?.toString() ??
                '';

        if (clientId.isEmpty) {
          throw Exception(
            'Invalid job information.',
          );
        }

        if (clientId == workerId) {
          throw Exception(
            'You cannot apply to your own job.',
          );
        }

        final workerSnapshot =
            await transaction.get(
          workerRef,
        );

        if (!workerSnapshot.exists) {
          throw Exception(
            'Please complete your worker profile before applying.',
          );
        }

        final workerData =
            workerSnapshot.data();

        if (workerData == null) {
          throw Exception(
            'Unable to load your profile.',
          );
        }

        final workerProfileComplete =
            workerData[
                    'workerProfileComplete'] ==
                true;

        if (!workerProfileComplete) {
          throw Exception(
            'Please complete your worker profile before applying.',
          );
        }

        final workerName =
            workerData['name']
                ?.toString()
                .trim();

        final workerLocation =
            workerData['location']
                ?.toString()
                .trim();

        final rawWorkerProfile =
            workerData[
                'workerProfile'];

        final workerProfile =
            rawWorkerProfile is Map
                ? Map<String, dynamic>.from(
                    rawWorkerProfile,
                  )
                : <String, dynamic>{};

        final rawSkills =
            workerProfile['skills'];

        final workerSkills =
            rawSkills is List
                ? rawSkills
                    .map(
                      (item) =>
                          item.toString(),
                    )
                    .toList()
                : <String>[];

        final experienceYears =
            (workerProfile[
                        'experienceYears']
                    as num?)
                ?.toInt() ??
            0;

        final rating =
            (workerProfile['rating']
                    as num?)
                ?.toDouble() ??
            0;

        final reviewCount =
            (workerProfile[
                        'reviewCount']
                    as num?)
                ?.toInt() ??
            0;

        final resolvedWorkerName =
            workerName?.isNotEmpty == true
                ? workerName!
                : user.displayName ??
                    'Worker';

        workerNameForNotification =
            resolvedWorkerName;

        jobTitle =
            job['title']
                    ?.toString() ??
                'Untitled job';

        transaction.set(
          applicationRef,
          {
            'applicationId':
                applicationId,
            'jobId':
                jobId,
            'jobTitle':
                jobTitle,
            'jobCategory':
                job['category']
                        ?.toString() ??
                    '',
            'clientId':
                clientId,
            'workerId':
                workerId,
            'workerEmail':
                user.email,
            'workerName':
                resolvedWorkerName,
            'workerLocation':
                workerLocation ?? '',
            'workerSkills':
                workerSkills,
            'experienceYears':
                experienceYears,
            'rating':
                rating,
            'reviewCount':
                reviewCount,
            'matchScore':
                matchScore.clamp(
              0,
              100,
            ),
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
      },
    );

    await _sendNotificationSafely(
      recipientId: clientId,
      type: 'job_application',
      title: 'New job application',
      message:
          '$workerNameForNotification applied for "$jobTitle".',
      jobId: jobId,
      applicationId: applicationId,
      actorId: workerId,
    );
  }

  // --------------------------------------------------
  // CHECK IF WORKER ALREADY APPLIED
  // --------------------------------------------------

  Future<bool> hasApplied(
    String jobId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    final applicationId =
        '${jobId}_${user.uid}';

    try {
      final snapshot =
          await _firestore
              .collection(
                'applications',
              )
              .doc(
                applicationId,
              )
              .get();

      return snapshot.exists;
    } on FirebaseException catch (e) {
      if (e.code ==
          'permission-denied') {
        return false;
      }

      rethrow;
    }
  }

  // --------------------------------------------------
  // WORKER: MY APPLICATIONS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getMyApplications() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection(
          'applications',
        )
        .where(
          'workerId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final applications =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'applicationId':
                  doc.id,
            };
          },
        ).toList();

        _sortNewestFirst(
          applications,
        );

        return applications;
      },
    );
  }

  // --------------------------------------------------
  // CLIENT: APPLICANTS FOR A JOB
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getApplicantsForJob(
    String jobId,
  ) {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection(
          'applications',
        )
        .where(
          'jobId',
          isEqualTo:
              jobId,
        )
        .where(
          'clientId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final applications =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'applicationId':
                  doc.id,
            };
          },
        ).toList();

        applications.sort(
          (a, b) {
            final aScore =
                (a['matchScore']
                        as num?)
                    ?.toInt() ??
                0;

            final bScore =
                (b['matchScore']
                        as num?)
                    ?.toInt() ??
                0;

            final scoreCompare =
                bScore.compareTo(
              aScore,
            );

            if (scoreCompare != 0) {
              return scoreCompare;
            }

            final aTime =
                a['createdAt']
                    as Timestamp?;

            final bTime =
                b['createdAt']
                    as Timestamp?;

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

            return bTime.compareTo(
              aTime,
            );
          },
        );

        return applications;
      },
    );
  }

  // --------------------------------------------------
  // CLIENT: ACCEPT APPLICATION
  // --------------------------------------------------

  Future<void> acceptApplication({
    required String applicationId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final applicationRef =
        _firestore
            .collection('applications')
            .doc(applicationId);

    String acceptedWorkerId = '';
    String acceptedJobId = '';
    String acceptedJobTitle = 'Job';

    await _firestore.runTransaction(
      (transaction) async {
        final applicationSnapshot =
            await transaction.get(
          applicationRef,
        );

        if (!applicationSnapshot.exists) {
          throw Exception(
            'Application not found.',
          );
        }

        final application =
            applicationSnapshot.data();

        if (application == null) {
          throw Exception(
            'Unable to load application.',
          );
        }

        final clientId =
            application['clientId']
                    ?.toString() ??
                '';

        if (clientId != user.uid) {
          throw Exception(
            'You are not allowed to manage this application.',
          );
        }

        final status =
            application['status']
                    ?.toString() ??
                '';

        if (status == 'accepted') {
          throw Exception(
            'This application is already accepted.',
          );
        }

        if (status == 'rejected') {
          throw Exception(
            'This application has already been rejected.',
          );
        }

        final jobId =
            application['jobId']
                    ?.toString() ??
                '';

        final workerId =
            application['workerId']
                    ?.toString() ??
                '';

        if (jobId.isEmpty ||
            workerId.isEmpty) {
          throw Exception(
            'Invalid application information.',
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
          throw Exception(
            'Job not found.',
          );
        }

        final job =
            jobSnapshot.data();

        if (job == null) {
          throw Exception(
            'Unable to load job.',
          );
        }

        if (job['clientId'] !=
            user.uid) {
          throw Exception(
            'You are not allowed to manage this job.',
          );
        }

        if (job['status'] !=
            'open') {
          throw Exception(
            'This job is no longer open.',
          );
        }

        acceptedWorkerId =
            workerId;

        acceptedJobId =
            jobId;

        acceptedJobTitle =
            application['jobTitle']
                    ?.toString() ??
                job['title']
                    ?.toString() ??
                'Job';

        transaction.update(
          applicationRef,
          {
            'status':
                'accepted',
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
                workerId,
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );
      },
    );

    await _sendNotificationSafely(
      recipientId:
          acceptedWorkerId,
      type:
          'application_accepted',
      title:
          'Application accepted',
      message:
          'Your application for "$acceptedJobTitle" was accepted.',
      jobId:
          acceptedJobId,
      applicationId:
          applicationId,
      actorId:
          user.uid,
    );

    final otherApplications =
        await _firestore
            .collection(
              'applications',
            )
            .where(
              'jobId',
              isEqualTo:
                  acceptedJobId,
            )
            .where(
              'clientId',
              isEqualTo:
                  user.uid,
            )
            .where(
              'status',
              isEqualTo:
                  'pending',
            )
            .get();

    if (otherApplications
        .docs.isEmpty) {
      return;
    }

    final batch =
        _firestore.batch();

    final rejectedWorkers =
        <Map<String, String>>[];

    for (final doc
        in otherApplications.docs) {
      if (doc.id ==
          applicationId) {
        continue;
      }

      final data =
          doc.data();

      final workerId =
          data['workerId']
                  ?.toString() ??
              '';

      final otherJobTitle =
          data['jobTitle']
                  ?.toString() ??
              acceptedJobTitle;

      if (workerId.isNotEmpty) {
        rejectedWorkers.add({
          'workerId':
              workerId,
          'applicationId':
              doc.id,
          'jobTitle':
              otherJobTitle,
        });
      }

      batch.update(
        doc.reference,
        {
          'status':
              'rejected',
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        },
      );
    }

    await batch.commit();

    for (final item
        in rejectedWorkers) {
      await _sendNotificationSafely(
        recipientId:
            item['workerId'] ?? '',
        type:
            'application_rejected',
        title:
            'Application update',
        message:
            'Another worker was selected for "${item['jobTitle'] ?? acceptedJobTitle}".',
        jobId:
            acceptedJobId,
        applicationId:
            item['applicationId'],
        actorId:
            user.uid,
      );
    }
  }

  // --------------------------------------------------
  // CLIENT: REJECT APPLICATION
  // --------------------------------------------------

  Future<void> rejectApplication({
    required String applicationId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final applicationRef =
        _firestore
            .collection('applications')
            .doc(applicationId);

    String workerId = '';
    String jobId = '';
    String jobTitle = 'Job';
    bool changed = false;

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          applicationRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Application not found.',
          );
        }

        final application =
            snapshot.data();

        if (application == null) {
          throw Exception(
            'Unable to load application.',
          );
        }

        if (application['clientId'] !=
            user.uid) {
          throw Exception(
            'You are not allowed to manage this application.',
          );
        }

        final currentStatus =
            application['status']
                    ?.toString() ??
                '';

        if (currentStatus ==
            'accepted') {
          throw Exception(
            'An accepted application cannot be rejected.',
          );
        }

        workerId =
            application['workerId']
                    ?.toString() ??
                '';

        jobId =
            application['jobId']
                    ?.toString() ??
                '';

        jobTitle =
            application['jobTitle']
                    ?.toString() ??
                'Job';

        if (currentStatus ==
            'rejected') {
          return;
        }

        changed = true;

        transaction.update(
          applicationRef,
          {
            'status':
                'rejected',
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );
      },
    );

    if (!changed) {
      return;
    }

    await _sendNotificationSafely(
      recipientId:
          workerId,
      type:
          'application_rejected',
      title:
          'Application update',
      message:
          'Your application for "$jobTitle" was not selected.',
      jobId:
          jobId,
      applicationId:
          applicationId,
      actorId:
          user.uid,
    );
  }

  // --------------------------------------------------
  // GET SINGLE APPLICATION
  // --------------------------------------------------

  Future<Map<String, dynamic>?>
      getApplication({
    required String jobId,
    required String workerId,
  }) async {
    final applicationId =
        '${jobId}_$workerId';

    final snapshot =
        await _firestore
            .collection(
              'applications',
            )
            .doc(
              applicationId,
            )
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    return <String, dynamic>{
      ...data,
      'applicationId':
          snapshot.id,
    };
  }

  // --------------------------------------------------
  // NOTIFICATION HELPER
  // --------------------------------------------------

  Future<void> _sendNotificationSafely({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    String? jobId,
    String? applicationId,
    required String actorId,
  }) async {
    if (recipientId.trim().isEmpty ||
        actorId.trim().isEmpty ||
        recipientId == actorId) {
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
        applicationId:
            applicationId,
        actorId:
            actorId,
      );
    } catch (_) {
      // Notification failure must not break
      // the main job/application action.
    }
  }

  // --------------------------------------------------
  // SORT
  // --------------------------------------------------

  static void _sortNewestFirst(
    List<Map<String, dynamic>>
        applications,
  ) {
    applications.sort(
      (a, b) {
        final aTime =
            a['createdAt']
                as Timestamp?;

        final bTime =
            b['createdAt']
                as Timestamp?;

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

        return bTime.compareTo(
          aTime,
        );
      },
    );
  }
}