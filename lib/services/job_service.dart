import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class JobService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  User? get currentUser =>
      _auth.currentUser;

  // --------------------------------------------------
  // CREATE JOB
  // --------------------------------------------------

  Future<String> createJob({
    required String title,
    required String category,
    required List<String> requiredSkills,
    required String description,
    required String location,
    required DateTime workDate,
    required String startTime,
    required int durationHours,
    required double budget,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to post a job.',
      );
    }

    final docRef =
        _firestore
            .collection('jobs')
            .doc();

    await docRef.set({
      'jobId':
          docRef.id,
      'clientId':
          user.uid,
      'clientEmail':
          user.email,
      'title':
          title.trim(),
      'category':
          category.trim(),
      'requiredSkills':
          requiredSkills,
      'description':
          description.trim(),
      'location':
          location.trim(),
      'workDate':
          Timestamp.fromDate(
        workDate,
      ),
      'startTime':
          startTime,
      'durationHours':
          durationHours,
      'budget':
          budget,
      'status':
          'open',
      'assignedWorkerId':
          null,
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // --------------------------------------------------
  // CLIENT: MY JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getMyJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'clientId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'jobId':
                  doc.id,
            };
          },
        ).toList();

        _sortNewestFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // WORKER: OPEN JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getOpenJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'status',
          isEqualTo:
              'open',
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs
                .map(
                  (doc) {
                    return <String, dynamic>{
                      ...doc.data(),
                      'jobId':
                          doc.id,
                    };
                  },
                )
                .where(
                  (job) =>
                      job['clientId'] !=
                      user.uid,
                )
                .toList();

        _sortNewestFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // WORKER: ACTIVE JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getWorkerActiveJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'assignedWorkerId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs
                .map(
                  (doc) {
                    return <String, dynamic>{
                      ...doc.data(),
                      'jobId':
                          doc.id,
                    };
                  },
                )
                .where(
                  (job) {
                    final status =
                        job['status']
                            ?.toString()
                            .toLowerCase();

                    return status ==
                            'assigned' ||
                        status ==
                            'in_progress';
                  },
                )
                .toList();

        _sortWorkDateFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // CLIENT: ACTIVE JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getClientActiveJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'clientId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs
                .map(
                  (doc) {
                    return <String, dynamic>{
                      ...doc.data(),
                      'jobId':
                          doc.id,
                    };
                  },
                )
                .where(
                  (job) {
                    final status =
                        job['status']
                            ?.toString()
                            .toLowerCase();

                    return status ==
                            'assigned' ||
                        status ==
                            'in_progress';
                  },
                )
                .toList();

        _sortWorkDateFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // CLIENT: COMPLETED JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getClientCompletedJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'clientId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs
                .map(
                  (doc) {
                    return <String, dynamic>{
                      ...doc.data(),
                      'jobId':
                          doc.id,
                    };
                  },
                )
                .where(
                  (job) =>
                      job['status']
                          ?.toString()
                          .toLowerCase() ==
                      'completed',
                )
                .toList();

        _sortCompletedNewestFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // WORKER: COMPLETED JOBS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getWorkerCompletedJobs() {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('jobs')
        .where(
          'assignedWorkerId',
          isEqualTo:
              user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final jobs =
            snapshot.docs
                .map(
                  (doc) {
                    return <String, dynamic>{
                      ...doc.data(),
                      'jobId':
                          doc.id,
                    };
                  },
                )
                .where(
                  (job) =>
                      job['status']
                          ?.toString()
                          .toLowerCase() ==
                      'completed',
                )
                .toList();

        _sortCompletedNewestFirst(
          jobs,
        );

        return jobs;
      },
    );
  }

  // --------------------------------------------------
  // WORKER: START WORK
  // --------------------------------------------------

  Future<void> startWork({
    required String jobId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(jobId);

    String clientId = '';
    String jobTitle = 'Job';
    bool changed = false;

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          jobRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Job not found.',
          );
        }

        final job =
            snapshot.data();

        if (job == null) {
          throw Exception(
            'Unable to load job.',
          );
        }

        final assignedWorkerId =
            job['assignedWorkerId']
                    ?.toString() ??
                '';

        if (assignedWorkerId !=
            user.uid) {
          throw Exception(
            'This job is not assigned to you.',
          );
        }

        final status =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        clientId =
            job['clientId']
                    ?.toString() ??
                '';

        jobTitle =
            job['title']
                    ?.toString() ??
                'Job';

        if (status ==
            'in_progress') {
          return;
        }

        if (status !=
            'assigned') {
          throw Exception(
            'This job cannot be started.',
          );
        }

        changed = true;

        transaction.update(
          jobRef,
          {
            'status':
                'in_progress',
            'startedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    if (!changed) {
      return;
    }

    await _sendNotificationSafely(
      recipientId: clientId,
      type: 'work_started',
      title: 'Work started',
      message:
          'The worker has started "$jobTitle".',
      jobId: jobId,
      actorId: user.uid,
    );
  }

  // --------------------------------------------------
  // CLIENT: COMPLETE WORK
  // --------------------------------------------------

  Future<void> completeWork({
    required String jobId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(jobId);

    String workerId = '';
    String jobTitle = 'Job';
    bool changed = false;

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(
          jobRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Job not found.',
          );
        }

        final job =
            snapshot.data();

        if (job == null) {
          throw Exception(
            'Unable to load job.',
          );
        }

        if (job['clientId'] !=
            user.uid) {
          throw Exception(
            'You are not allowed to complete this job.',
          );
        }

        final status =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        workerId =
            job['assignedWorkerId']
                    ?.toString() ??
                '';

        jobTitle =
            job['title']
                    ?.toString() ??
                'Job';

        if (status ==
            'completed') {
          return;
        }

        if (status !=
            'in_progress') {
          throw Exception(
            'Only work in progress can be completed.',
          );
        }

        if (workerId.isEmpty) {
          throw Exception(
            'No worker is assigned to this job.',
          );
        }

        changed = true;

        transaction.update(
          jobRef,
          {
            'status':
                'completed',
            'completedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    if (!changed) {
      return;
    }

    await _sendNotificationSafely(
      recipientId: workerId,
      type: 'work_completed',
      title: 'Work completed',
      message:
          'The client marked "$jobTitle" as completed.',
      jobId: jobId,
      actorId: user.uid,
    );
  }

  // --------------------------------------------------
  // NOTIFICATION HELPER
  // --------------------------------------------------

  Future<void> _sendNotificationSafely({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    required String jobId,
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
        recipientId: recipientId,
        type: type,
        title: title,
        message: message,
        jobId: jobId,
        actorId: actorId,
      );
    } catch (_) {
      // Notification failure must not break
      // the main job action.
    }
  }

  // --------------------------------------------------
  // SORT: NEWEST CREATED FIRST
  // --------------------------------------------------

  static void _sortNewestFirst(
    List<Map<String, dynamic>>
        jobs,
  ) {
    jobs.sort(
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

  // --------------------------------------------------
  // SORT: UPCOMING WORK DATE FIRST
  // --------------------------------------------------

  static void _sortWorkDateFirst(
    List<Map<String, dynamic>>
        jobs,
  ) {
    jobs.sort(
      (a, b) {
        final aDate =
            a['workDate']
                as Timestamp?;

        final bDate =
            b['workDate']
                as Timestamp?;

        if (aDate == null &&
            bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return aDate.compareTo(
          bDate,
        );
      },
    );
  }

  // --------------------------------------------------
  // SORT: MOST RECENTLY COMPLETED FIRST
  // --------------------------------------------------

  static void _sortCompletedNewestFirst(
    List<Map<String, dynamic>>
        jobs,
  ) {
    jobs.sort(
      (a, b) {
        final aTime =
            a['completedAt']
                as Timestamp?;

        final bTime =
            b['completedAt']
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