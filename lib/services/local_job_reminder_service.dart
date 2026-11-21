import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules job-start reminders on the assigned worker's own device.
///
/// This is deliberately device-local. It does not use Cloud Functions,
/// Cloud Scheduler, or a Firebase Blaze billing plan.
class LocalJobReminderService {
  LocalJobReminderService._();

  static final LocalJobReminderService instance =
      LocalJobReminderService._();

  static const String _payloadPrefix = 'smc_job_start_reminder::';
  static const String _channelId = 'job_start_reminders';
  static const String _channelName = 'Job start reminders';
  static const String _channelDescription =
      'Reminders before an assigned job is scheduled to start.';
  static const List<int> _reminderOffsetsMinutes = [60, 30, 10, 0];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSubscription;
  String? _currentUserId;
  bool _initialized = false;
  bool _permissionRequested = false;
  bool _permissionGranted = false;
  Future<void>? _syncInProgress;

  bool get _supportsLocalScheduling {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (!_supportsLocalScheduling || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      // Bangladesh is the initial market. Use this only if the device cannot
      // provide its IANA timezone through the platform plugin.
      debugPrint('Unable to read device timezone: $error');
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Job reminder opened: ${response.payload ?? ''}');
  }

  /// Watches jobs assigned to the signed-in user. Client accounts normally
  /// return no documents from this query, so no reminder permission is asked.
  Future<void> startForUser(String userId) async {
    if (!_supportsLocalScheduling || userId.trim().isEmpty) return;

    await initialize();

    if (_currentUserId == userId && _jobsSubscription != null) return;

    // On a normal app restart _currentUserId is null while OS-scheduled
    // reminders may still be pending. Preserve them and reconcile from the
    // Firestore snapshot. Only cancel all reminders when switching accounts.
    if (_currentUserId != null && _currentUserId != userId) {
      await stopForUser();
    } else {
      await _jobsSubscription?.cancel();
      _jobsSubscription = null;
    }
    _currentUserId = userId;

    _jobsSubscription = _firestore
        .collection('jobs')
        .where('assignedWorkerId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) => unawaited(_syncFromSnapshot(snapshot)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Local job reminder stream error: $error');
      },
    );
  }

  /// Reconciles local reminders after app launch or foreground resume.
  Future<void> refresh() async {
    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (!_supportsLocalScheduling || userId == null || userId.isEmpty) return;

    await initialize();
    // Re-check OS permission after the user returns from device settings.
    _permissionRequested = false;
    final snapshot = await _firestore
        .collection('jobs')
        .where('assignedWorkerId', isEqualTo: userId)
        .get();
    await _syncFromSnapshot(snapshot);
  }

  Future<void> stopForUser() async {
    await _jobsSubscription?.cancel();
    _jobsSubscription = null;
    _currentUserId = null;

    if (_initialized && _supportsLocalScheduling) {
      await _cancelAllManagedReminders();
    }
  }

  /// Cancels all remaining pre-start reminders for a job on this device.
  Future<void> cancelJobReminders(String jobId) async {
    if (!_supportsLocalScheduling || !_initialized || jobId.isEmpty) return;

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final parts = (request.payload ?? '').split('::');
      if (parts.length >= 3 &&
          parts[0] == 'smc_job_start_reminder' &&
          parts[1] == jobId) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> _cancelAllManagedReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if ((request.payload ?? '').startsWith(_payloadPrefix)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<bool> _ensureNotificationPermission() async {
    if (_permissionGranted) return true;
    if (_permissionRequested) return false;

    _permissionRequested = true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      _permissionGranted = result ?? true;
      return _permissionGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = result ?? false;
      return _permissionGranted;
    }

    return false;
  }

  Future<void> _syncFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Serialize syncs so fast Firestore events cannot race schedule/cancel work.
    final previous = _syncInProgress;
    if (previous != null) {
      try {
        await previous;
      } catch (error) {
        debugPrint('Previous local reminder sync failed: $error');
      }
    }

    final operation = _performSync(snapshot);
    _syncInProgress = operation;
    try {
      await operation;
    } finally {
      if (identical(_syncInProgress, operation)) {
        _syncInProgress = null;
      }
    }
  }

  Future<void> _performSync(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (!_initialized || !_supportsLocalScheduling) return;
    // An empty cache-only snapshot is not authoritative. Keep existing OS
    // reminders until Firestore returns the server-backed snapshot.
    if (snapshot.metadata.isFromCache && snapshot.docs.isEmpty) return;

    final now = DateTime.now();
    final desired = <int, _LocalReminder>{};

    for (final document in snapshot.docs) {
      final job = document.data();
      final status = (job['status'] ?? '').toString().toLowerCase();
      if (status != 'assigned') continue;
      if ((job['assignedWorkerId'] ?? '').toString() != _currentUserId) {
        continue;
      }

      final scheduledStart = _readScheduledStart(job);
      if (scheduledStart == null || !scheduledStart.isAfter(now)) continue;

      final jobTitle = (job['title'] ?? 'your job').toString();
      for (final offset in _reminderOffsetsMinutes) {
        final reminderAt = scheduledStart.subtract(Duration(minutes: offset));
        if (!reminderAt.isAfter(now)) continue;

        final seed =
            '${document.id}|${scheduledStart.millisecondsSinceEpoch}|$offset';
        final notificationId = _stableNotificationId(seed);
        final payload = '$_payloadPrefix${document.id}::'
            '${scheduledStart.millisecondsSinceEpoch}::$offset';
        final copy = _reminderCopy(offset, jobTitle);

        desired[notificationId] = _LocalReminder(
          id: notificationId,
          title: copy.$1,
          body: copy.$2,
          scheduledAt: reminderAt,
          payload: payload,
        );
      }
    }

    if (desired.isNotEmpty && !await _ensureNotificationPermission()) {
      debugPrint('Job reminders skipped: notification permission not granted.');
      return;
    }

    final pending = await _plugin.pendingNotificationRequests();
    final pendingById = <int, PendingNotificationRequest>{
      for (final request in pending) request.id: request,
    };

    // Cancel reminders for jobs that were started, cancelled, rescheduled,
    // reassigned, or are no longer assigned to this worker.
    for (final request in pending) {
      if (!(request.payload ?? '').startsWith(_payloadPrefix)) continue;
      final wanted = desired[request.id];
      if (wanted == null || wanted.payload != request.payload) {
        await _plugin.cancel(request.id);
      }
    }

    for (final reminder in desired.values) {
      final existing = pendingById[reminder.id];
      if (existing != null && existing.payload == reminder.payload) continue;

      await _plugin.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.body,
        tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload,
      );
    }
  }

  DateTime? _readScheduledStart(Map<String, dynamic> job) {
    final direct = _asDateTime(job['scheduledStartAt']);
    if (direct != null) return direct;

    // Backward-compatible fallback for older jobs without scheduledStartAt.
    final workDate = _asDateTime(job['workDate']);
    final startTime = (job['startTime'] ?? '').toString();
    if (workDate == null) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(startTime);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }

    final localDate = workDate.toLocal();
    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      hour,
      minute,
    );
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  (String, String) _reminderCopy(int minutesBefore, String jobTitle) {
    if (minutesBefore == 60) {
      return (
        'Your job starts in 1 hour',
        'Your scheduled job "$jobTitle" starts in 1 hour. Please prepare.',
      );
    }
    if (minutesBefore == 30) {
      return (
        'Your job starts in 30 minutes',
        'Your scheduled job "$jobTitle" starts in 30 minutes. Please get ready.',
      );
    }
    if (minutesBefore == 10) {
      return (
        'Your job starts in 10 minutes',
        'Your scheduled job "$jobTitle" starts in 10 minutes. Please be ready.',
      );
    }
    return (
      'It is time to start your job',
      'Your scheduled start time for "$jobTitle" has arrived. Please start your work.',
    );
  }

  int _stableNotificationId(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}

class _LocalReminder {
  const _LocalReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String payload;
}
