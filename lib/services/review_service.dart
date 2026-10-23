import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  User? get currentUser =>
      _auth.currentUser;

  // --------------------------------------------------
  // SUBMIT REVIEW
  // --------------------------------------------------

  Future<void> submitReview({
    required String jobId,
    required int stars,
    required String comment,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to submit a review.',
      );
    }

    if (stars < 1 ||
        stars > 5) {
      throw Exception(
        'Rating must be between 1 and 5 stars.',
      );
    }

    final cleanComment =
        comment.trim();

    if (cleanComment.length >
        500) {
      throw Exception(
        'Review cannot exceed 500 characters.',
      );
    }

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(jobId);

    final reviewRef =
        _firestore
            .collection('reviews')
            .doc(jobId);

    String workerId = '';
    String jobTitle = 'Job';

    await _firestore.runTransaction(
      (transaction) async {
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

        final clientId =
            job['clientId']
                    ?.toString() ??
                '';

        if (clientId !=
            user.uid) {
          throw Exception(
            'Only the client who posted this job can submit a review.',
          );
        }

        final status =
            job['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        if (status !=
            'completed') {
          throw Exception(
            'You can review the worker only after the job is completed.',
          );
        }

        workerId =
            job['assignedWorkerId']
                    ?.toString() ??
                '';

        if (workerId.isEmpty) {
          throw Exception(
            'No worker is assigned to this job.',
          );
        }

        if (workerId ==
            user.uid) {
          throw Exception(
            'You cannot review yourself.',
          );
        }

        final existingReview =
            await transaction.get(
          reviewRef,
        );

        if (existingReview.exists) {
          throw Exception(
            'You have already reviewed this job.',
          );
        }

        final workerRef =
            _firestore
                .collection('users')
                .doc(workerId);

        final workerSnapshot =
            await transaction.get(
          workerRef,
        );

        if (!workerSnapshot.exists) {
          throw Exception(
            'Worker profile not found.',
          );
        }

        final workerData =
            workerSnapshot.data();

        if (workerData == null) {
          throw Exception(
            'Unable to load worker profile.',
          );
        }

        final rawWorkerProfile =
            workerData['workerProfile'];

        final workerProfile =
            rawWorkerProfile
                    is Map<String, dynamic>
                ? Map<String, dynamic>.from(
                    rawWorkerProfile,
                  )
                : <String, dynamic>{};

        final oldRating =
            (workerProfile['rating']
                        as num?)
                    ?.toDouble() ??
                0.0;

        final oldReviewCount =
            (workerProfile['reviewCount']
                        as num?)
                    ?.toInt() ??
                0;

        final newReviewCount =
            oldReviewCount + 1;

        final newRating =
            ((oldRating *
                        oldReviewCount) +
                    stars) /
                newReviewCount;

        jobTitle =
            job['title']
                    ?.toString() ??
                'Job';

        final category =
            job['category']
                    ?.toString() ??
                'Other';

        transaction.set(
          reviewRef,
          {
            'reviewId':
                reviewRef.id,
            'jobId':
                jobId,
            'jobTitle':
                jobTitle,
            'category':
                category,
            'clientId':
                user.uid,
            'clientEmail':
                user.email,
            'workerId':
                workerId,
            'stars':
                stars,
            'comment':
                cleanComment,
            'createdAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        transaction.update(
          workerRef,
          {
            'workerProfile.rating':
                newRating,
            'workerProfile.reviewCount':
                newReviewCount,
            'workerProfile.lastReviewJobId':
                jobId,
          },
        );
      },
    );

    await _sendNotificationSafely(
      recipientId: workerId,
      type: 'new_review',
      title: 'New review received',
      message:
          'You received a $stars-star review for "$jobTitle".',
      jobId: jobId,
      actorId: user.uid,
    );
  }

  // --------------------------------------------------
  // CHECK IF CLIENT ALREADY REVIEWED JOB
  // --------------------------------------------------

  Future<bool> hasReviewed(
    String jobId,
  ) async {
    final user =
        _auth.currentUser;

    if (user == null ||
        jobId.trim().isEmpty) {
      return false;
    }

    try {
      final snapshot =
          await _firestore
              .collection('reviews')
              .doc(jobId)
              .get();

      if (!snapshot.exists) {
        return false;
      }

      final data =
          snapshot.data();

      return data?['clientId'] ==
          user.uid;
    } on FirebaseException catch (e) {
      if (e.code ==
          'permission-denied') {
        return false;
      }

      rethrow;
    }
  }

  // --------------------------------------------------
  // GET REVIEW FOR ONE JOB
  // --------------------------------------------------

  Stream<Map<String, dynamic>?>
      getReviewForJob(
    String jobId,
  ) {
    if (jobId.trim().isEmpty) {
      return Stream.value(
        null,
      );
    }

    return _firestore
        .collection('reviews')
        .doc(jobId)
        .snapshots()
        .map(
      (snapshot) {
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
          'reviewId':
              snapshot.id,
        };
      },
    );
  }

  // --------------------------------------------------
  // WORKER: ALL REVIEWS
  // --------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      getWorkerReviews({
    String? workerId,
  }) {
    final targetWorkerId =
        workerId ??
            _auth.currentUser?.uid;

    if (targetWorkerId == null ||
        targetWorkerId.isEmpty) {
      return Stream.value(
        [],
      );
    }

    return _firestore
        .collection('reviews')
        .where(
          'workerId',
          isEqualTo:
              targetWorkerId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final reviews =
            snapshot.docs.map(
          (doc) {
            return <String, dynamic>{
              ...doc.data(),
              'reviewId':
                  doc.id,
            };
          },
        ).toList();

        reviews.sort(
          (
            a,
            b,
          ) {
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

        return reviews;
      },
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
      // the main review submission.
    }
  }
}