import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  User? get currentUser =>
      _auth.currentUser;

  String conversationId({
    required String jobId,
    required String workerId,
  }) {
    return '${jobId.trim()}_${workerId.trim()}';
  }

  Future<Map<String, dynamic>> ensureConversation({
    required String jobId,
    String? workerId,
  }) async {
    final user =
        currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in.',
      );
    }

    final cleanJobId =
        jobId.trim();

    if (cleanJobId.isEmpty) {
      throw ArgumentError(
        'Job is required.',
      );
    }

    final jobRef =
        _firestore
            .collection('jobs')
            .doc(cleanJobId);

    final jobSnapshot =
        await jobRef.get();

    if (!jobSnapshot.exists) {
      throw StateError(
        'Job no longer exists.',
      );
    }

    final job =
        jobSnapshot.data()!;

    final clientId =
        job['clientId']
                ?.toString()
                .trim() ??
            '';

    final jobTitle =
        job['title']
                ?.toString()
                .trim() ??
            'Job';

    if (clientId.isEmpty) {
      throw StateError(
        'Job client information is missing.',
      );
    }

    late String cleanWorkerId;

    if (user.uid == clientId) {
      cleanWorkerId =
          workerId?.trim() ?? '';

      if (cleanWorkerId.isEmpty) {
        throw ArgumentError(
          'Worker is required.',
        );
      }

      if (cleanWorkerId ==
          clientId) {
        throw StateError(
          'You cannot message yourself.',
        );
      }
    } else {
      cleanWorkerId =
          user.uid;
    }

    final id =
        conversationId(
      jobId:
          cleanJobId,
      workerId:
          cleanWorkerId,
    );

    final conversationRef =
        _firestore
            .collection(
              'conversations',
            )
            .doc(id);

    QuerySnapshot<Map<String, dynamic>>
        existingSnapshot;

    if (user.uid == clientId) {
      existingSnapshot =
          await _firestore
              .collection(
                'conversations',
              )
              .where(
                'clientId',
                isEqualTo:
                    user.uid,
              )
              .where(
                'jobId',
                isEqualTo:
                    cleanJobId,
              )
              .where(
                'workerId',
                isEqualTo:
                    cleanWorkerId,
              )
              .limit(1)
              .get();
    } else {
      existingSnapshot =
          await _firestore
              .collection(
                'conversations',
              )
              .where(
                'workerId',
                isEqualTo:
                    user.uid,
              )
              .where(
                'jobId',
                isEqualTo:
                    cleanJobId,
              )
              .where(
                'clientId',
                isEqualTo:
                    clientId,
              )
              .limit(1)
              .get();
    }

    if (existingSnapshot.docs.isNotEmpty) {
      final existingDoc =
          existingSnapshot.docs.first;

      final existingData =
          existingDoc.data();

      final existingJobTitle =
          existingData['jobTitle']
                  ?.toString()
                  .trim() ??
              '';

      return {
        ...existingData,
        'conversationId':
            existingDoc.id,
        'jobId':
            cleanJobId,
        'jobTitle':
            existingJobTitle.isNotEmpty
                ? existingJobTitle
                : jobTitle,
        'clientId':
            clientId,
        'workerId':
            cleanWorkerId,
      };
    }

    await conversationRef.set(
      {
        'conversationId':
            id,
        'jobId':
            cleanJobId,
        'jobTitle':
            jobTitle,
        'clientId':
            clientId,
        'workerId':
            cleanWorkerId,
        'participants': [
          clientId,
          cleanWorkerId,
        ],
        'unreadClient':
            0,
        'unreadWorker':
            0,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    return {
      'conversationId':
          id,
      'jobId':
          cleanJobId,
      'jobTitle':
          jobTitle,
      'clientId':
          clientId,
      'workerId':
          cleanWorkerId,
      'unreadClient':
          0,
      'unreadWorker':
          0,
    };
  }

  Stream<List<Map<String, dynamic>>>
      getMessages({
    required String conversationId,
  }) {
    return _firestore
        .collection(
          'conversations',
        )
        .doc(
          conversationId.trim(),
        )
        .collection(
          'messages',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) => {
                ...doc.data(),
                'messageId':
                    doc.id,
              },
            )
            .toList();
      },
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user =
        currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in.',
      );
    }

    final cleanConversationId =
        conversationId.trim();

    final cleanText =
        text.trim();

    if (cleanConversationId.isEmpty) {
      throw ArgumentError(
        'Conversation is required.',
      );
    }

    if (cleanText.isEmpty) {
      return;
    }

    if (cleanText.length > 2000) {
      throw ArgumentError(
        'Message is too long.',
      );
    }

    final conversationRef =
        _firestore
            .collection(
              'conversations',
            )
            .doc(
              cleanConversationId,
            );

    final conversationSnapshot =
        await conversationRef.get();

    if (!conversationSnapshot.exists) {
      throw StateError(
        'Conversation no longer exists.',
      );
    }

    final conversation =
        conversationSnapshot.data()!;

    final clientId =
        conversation['clientId']
                ?.toString() ??
            '';

    final workerId =
        conversation['workerId']
                ?.toString() ??
            '';

    if (user.uid != clientId &&
        user.uid != workerId) {
      throw StateError(
        'You are not part of this conversation.',
      );
    }

    final recipientUnreadField =
        user.uid == clientId
            ? 'unreadWorker'
            : 'unreadClient';

    final messageRef =
        conversationRef
            .collection(
              'messages',
            )
            .doc();

    final batch =
        _firestore.batch();

    batch.set(
      messageRef,
      {
        'messageId':
            messageRef.id,
        'senderId':
            user.uid,
        'text':
            cleanText,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      conversationRef,
      {
        'lastMessage':
            cleanText,
        'lastMessageSenderId':
            user.uid,
        'lastMessageAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        recipientUnreadField:
            FieldValue.increment(1),
      },
    );

    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
  }) async {
    final user =
        currentUser;

    if (user == null) {
      return;
    }

    final cleanConversationId =
        conversationId.trim();

    if (cleanConversationId.isEmpty) {
      return;
    }

    final conversationRef =
        _firestore
            .collection(
              'conversations',
            )
            .doc(
              cleanConversationId,
            );

    final snapshot =
        await conversationRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data()!;

    final clientId =
        data['clientId']
                ?.toString() ??
            '';

    final workerId =
        data['workerId']
                ?.toString() ??
            '';

    late String unreadField;

    if (user.uid == clientId) {
      unreadField =
          'unreadClient';
    } else if (user.uid == workerId) {
      unreadField =
          'unreadWorker';
    } else {
      return;
    }

    final currentUnread =
        (data[unreadField]
                    as num?)
                ?.toInt() ??
            0;

    if (currentUnread <= 0) {
      return;
    }

    await conversationRef.update(
      {
        unreadField:
            0,
      },
    );
  }

  int getUnreadCountForConversation(
    Map<String, dynamic> conversation,
  ) {
    final user =
        currentUser;

    if (user == null) {
      return 0;
    }

    final clientId =
        conversation['clientId']
                ?.toString() ??
            '';

    final workerId =
        conversation['workerId']
                ?.toString() ??
            '';

    if (user.uid == clientId) {
      return (conversation['unreadClient']
                  as num?)
              ?.toInt() ??
          0;
    }

    if (user.uid == workerId) {
      return (conversation['unreadWorker']
                  as num?)
              ?.toInt() ??
          0;
    }

    return 0;
  }

  Stream<int> getTotalUnreadCount() {
    return getMyConversations().map(
      (conversations) {
        var total =
            0;

        for (final conversation
            in conversations) {
          total +=
              getUnreadCountForConversation(
            conversation,
          );
        }

        return total;
      },
    );
  }

  Stream<List<Map<String, dynamic>>>
      getMyConversations() {
    final user =
        currentUser;

    if (user == null) {
      return Stream.value(
        [],
      );
    }

    late StreamController<
            List<Map<String, dynamic>>>
        controller;

    StreamSubscription<
            QuerySnapshot<
                Map<String, dynamic>>>?
        clientSubscription;

    StreamSubscription<
            QuerySnapshot<
                Map<String, dynamic>>>?
        workerSubscription;

    var clientConversations =
        <Map<String, dynamic>>[];

    var workerConversations =
        <Map<String, dynamic>>[];

    void emitCombined() {
      final merged =
          <String, Map<String, dynamic>>{};

      for (final conversation
          in clientConversations) {
        final id =
            conversation['conversationId']
                    ?.toString() ??
                '';

        if (id.isNotEmpty) {
          merged[id] =
              conversation;
        }
      }

      for (final conversation
          in workerConversations) {
        final id =
            conversation['conversationId']
                    ?.toString() ??
                '';

        if (id.isNotEmpty) {
          merged[id] =
              conversation;
        }
      }

      final conversations =
          merged.values.toList();

      conversations.sort(
        (
          a,
          b,
        ) {
          final aTime =
              a['lastMessageAt'] ??
                  a['updatedAt'] ??
                  a['createdAt'];

          final bTime =
              b['lastMessageAt'] ??
                  b['updatedAt'] ??
                  b['createdAt'];

          if (aTime is Timestamp &&
              bTime is Timestamp) {
            return bTime.compareTo(
              aTime,
            );
          }

          if (aTime is Timestamp) {
            return -1;
          }

          if (bTime is Timestamp) {
            return 1;
          }

          return 0;
        },
      );

      if (!controller.isClosed) {
        controller.add(
          conversations,
        );
      }
    }

    List<Map<String, dynamic>>
        convertSnapshot(
      QuerySnapshot<Map<String, dynamic>>
          snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => {
              ...doc.data(),
              'conversationId':
                  doc.id,
            },
          )
          .toList();
    }

    controller =
        StreamController<
            List<Map<String, dynamic>>>(
      onListen: () {
        clientSubscription =
            _firestore
                .collection(
                  'conversations',
                )
                .where(
                  'clientId',
                  isEqualTo:
                      user.uid,
                )
                .snapshots()
                .listen(
          (snapshot) {
            clientConversations =
                convertSnapshot(
              snapshot,
            );

            emitCombined();
          },
          onError:
              controller.addError,
        );

        workerSubscription =
            _firestore
                .collection(
                  'conversations',
                )
                .where(
                  'workerId',
                  isEqualTo:
                      user.uid,
                )
                .snapshots()
                .listen(
          (snapshot) {
            workerConversations =
                convertSnapshot(
              snapshot,
            );

            emitCombined();
          },
          onError:
              controller.addError,
        );
      },
      onCancel: () async {
        await clientSubscription
            ?.cancel();

        await workerSubscription
            ?.cancel();
      },
    );

    return controller.stream;
  }
}
