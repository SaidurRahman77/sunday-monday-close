import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditLogService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchAuditLogs() {
    return _firestore
        .collection('admin_audit_logs')
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs.map((doc) {
        return <String, dynamic>{
          ...doc.data(),
          'logId': doc.id,
        };
      }).toList();

      logs.sort((a, b) {
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
      });

      return logs;
    });
  }
}
