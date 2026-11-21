import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../utils/duration_formatter.dart';
import 'premium_ui.dart';

class JobCountdownCard extends StatefulWidget {
  const JobCountdownCard({
    super.key,
    required this.job,
  });

  final Map<String, dynamic> job;

  @override
  State<JobCountdownCard> createState() => _JobCountdownCardState();
}

class _JobCountdownCardState extends State<JobCountdownCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant JobCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.job['deadlineAt'] != widget.job['deadlineAt'] ||
        oldWidget.job['startedAt'] != widget.job['startedAt'] ||
        oldWidget.job['durationHours'] != widget.job['durationHours']) {
      _now = DateTime.now();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  DateTime? get _startedAt => _asDateTime(widget.job['startedAt']);

  DateTime? get _deadline {
    final savedDeadline = _asDateTime(widget.job['deadlineAt']);
    if (savedDeadline != null) return savedDeadline;

    final startedAt = _startedAt;
    final durationHours =
        (widget.job['durationHours'] as num?)?.toInt() ?? 0;
    if (startedAt == null || durationHours <= 0) return null;

    // Fallback while the server-side deadline calculation is being written.
    return startedAt.add(Duration(hours: durationHours));
  }

  String _clock(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = _startedAt;
    final deadline = _deadline;
    final durationHours =
        (widget.job['durationHours'] as num?)?.toInt() ?? 0;

    if (startedAt == null || deadline == null || durationHours <= 0) {
      return const SizedBox.shrink();
    }

    final difference = deadline.difference(_now);
    final overdue = difference.isNegative || difference.inSeconds == 0;
    final remaining = difference.isNegative ? Duration.zero : difference;
    final overdueBy = difference.isNegative ? Duration(seconds: difference.inSeconds.abs()) : Duration.zero;
    final totalSeconds = Duration(hours: durationHours).inSeconds;
    final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final progress = totalSeconds <= 0
        ? 0.0
        : (1 - remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

    final statusColor = overdue ? Colors.red.shade700 : AppColors.success;
    final statusText = overdue ? 'TIME OVERDUE' : 'TIME REMAINING';
    final clockText = overdue ? _clock(overdueBy) : _clock(remaining);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: overdue ? Colors.red.withValues(alpha: 0.055) : AppColors.goldSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: overdue ? Colors.red.withValues(alpha: 0.24) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overdue ? LucideIcons.triangleAlert : LucideIcons.timer,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 7),
              Text(
                statusText,
                style: AppText.label(size: 9, color: statusColor),
              ),
              const Spacer(),
              Text(
                DurationFormatter.formatHours(durationHours),
                style: AppText.label(size: 9, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            clockText,
            style: AppText.heading(size: 25, color: statusColor),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Started ${_formatTime(startedAt)}',
                  style: AppText.body(size: 9, color: AppColors.muted),
                ),
              ),
              Text(
                overdue ? 'Exceeded by ${_clock(overdueBy)}' : 'Expected ${_formatExpected(deadline)}',
                style: AppText.body(size: 9, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _formatExpected(DateTime value) {
    final sameDate = value.year == _now.year &&
        value.month == _now.month &&
        value.day == _now.day;
    if (sameDate) return _formatTime(value);
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')} ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
