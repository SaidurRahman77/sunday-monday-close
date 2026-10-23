import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlatformSettingsService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>
      get _settingsRef =>
          _firestore
              .collection(
                'platform_settings',
              )
              .doc('general');

  static const Map<String, dynamic>
      defaultSettings = {
    'maintenanceMode': false,
    'allowNewRegistrations': true,
    'maintenanceMessage':
        'The platform is temporarily unavailable for maintenance. Please try again later.',
  };

  Stream<Map<String, dynamic>>
      watchSettings() {
    return _settingsRef.snapshots().map(
      (snapshot) {
        return <String, dynamic>{
          ...defaultSettings,
          ...?snapshot.data(),
        };
      },
    );
  }

  Future<Map<String, dynamic>>
      getSettings() async {
    final snapshot =
        await _settingsRef.get();

    return <String, dynamic>{
      ...defaultSettings,
      ...?snapshot.data(),
    };
  }

  Future<bool>
      isMaintenanceMode() async {
    final settings =
        await getSettings();

    return settings[
            'maintenanceMode'] ==
        true;
  }

  Future<bool>
      areRegistrationsAllowed() async {
    final settings =
        await getSettings();

    return settings[
            'allowNewRegistrations'] !=
        false;
  }

  Future<String>
      getMaintenanceMessage() async {
    final settings =
        await getSettings();

    final message =
        settings[
                'maintenanceMessage']
            ?.toString()
            .trim();

    if (message == null ||
        message.isEmpty) {
      return defaultSettings[
              'maintenanceMessage']
          .toString();
    }

    return message;
  }

  Future<void> saveSettings({
    required bool maintenanceMode,
    required bool allowNewRegistrations,
    required String maintenanceMessage,
  }) async {
    final admin =
        _auth.currentUser;

    if (admin == null) {
      throw Exception(
        'Admin session not found.',
      );
    }

    final message =
        maintenanceMessage.trim();

    final batch =
        _firestore.batch();

    batch.set(
      _settingsRef,
      {
        'maintenanceMode':
            maintenanceMode,
        'allowNewRegistrations':
            allowNewRegistrations,
        'maintenanceMessage':
            message.isEmpty
                ? defaultSettings[
                        'maintenanceMessage']
                    .toString()
                : message,
        'updatedAt':
            FieldValue.serverTimestamp(),
        'updatedBy':
            admin.uid,
      },
      SetOptions(
        merge: true,
      ),
    );

    final auditRef =
        _firestore
            .collection(
              'admin_audit_logs',
            )
            .doc();

    batch.set(
      auditRef,
      {
        'logId':
            auditRef.id,
        'adminId':
            admin.uid,
        'adminEmail':
            admin.email,
        'action':
            'platform_settings_updated',
        'targetType':
            'platform_settings',
        'targetId':
            'general',
        'details': {
          'maintenanceMode':
              maintenanceMode,
          'allowNewRegistrations':
              allowNewRegistrations,
          'maintenanceMessage':
              message,
        },
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}
