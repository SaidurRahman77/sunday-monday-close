
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  static const Color navy = Color(0xFF172033);
  static const Color gold = Color(0xFFC69B45);
  static const Color background = Color(0xFFF7F8FA);

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthName(DateTime date) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminService().isCurrentUserAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (adminSnapshot.hasError || adminSnapshot.data != true) {
          return const Scaffold(
            body: Center(child: Text('Admin access required.')),
          );
        }

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            title: const Text('Platform Analytics'),
            backgroundColor: background,
            foregroundColor: navy,
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .snapshots(),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load job analytics.'),
                );
              }

              if (!jobSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load user analytics.'),
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final jobs = jobSnapshot.data!.docs
                      .map((doc) => doc.data())
                      .toList();

                  final users = userSnapshot.data!.docs
                      .map((doc) => doc.data())
                      .toList();

                  final now = DateTime.now();

                  final completed = jobs.where(
                    (j) => j['status'] == 'completed',
                  ).length;

                  final open = jobs.where(
                    (j) => j['status'] == 'open',
                  ).length;

                  final assigned = jobs.where(
                    (j) => j['status'] == 'assigned',
                  ).length;

                  final inProgress = jobs.where(
                    (j) => j['status'] == 'in_progress',
                  ).length;

                  final cancelled = jobs.where(
                    (j) => j['status'] == 'cancelled',
                  ).length;

                  final completionRate = jobs.isEmpty
                      ? 0.0
                      : completed / jobs.length * 100;

                  final newUsers = users.where((u) {
                    final date = _date(u['createdAt']);
                    return date != null &&
                        date.year == now.year &&
                        date.month == now.month;
                  }).length;

                  final monthlyJobs = <String, int>{};

                  final months = List.generate(6, (index) {
                    return DateTime(now.year, now.month - 5 + index, 1);
                  });

                  for (final month in months) {
                    monthlyJobs[_monthKey(month)] = 0;
                  }

                  for (final job in jobs) {
                    final date = _date(job['createdAt']);
                    if (date == null) continue;

                    final key = _monthKey(date);

                    if (monthlyJobs.containsKey(key)) {
                      monthlyJobs[key] = monthlyJobs[key]! + 1;
                    }
                  }

                  final categoryCounts = <String, int>{};

                  for (final job in jobs) {
                    final category =
                        job['category']?.toString().trim();

                    if (category == null || category.isEmpty) continue;

                    categoryCounts[category] =
                        (categoryCounts[category] ?? 0) + 1;
                  }

                  final topCategories = categoryCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final durations = <double>[];

                  for (final job in jobs) {
                    if (job['status'] != 'completed') continue;

                    final started = _date(job['startedAt']);
                    final finished = _date(job['completedAt']);

                    if (started == null || finished == null) continue;

                    final hours = finished.difference(started).inSeconds /
                        3600;

                    if (hours >= 0) durations.add(hours);
                  }

                  final averageHours = durations.isEmpty
                      ? null
                      : durations.reduce((a, b) => a + b) /
                          durations.length;

                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(
                        const Duration(milliseconds: 400),
                      );
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        _sectionTitle('Platform Overview'),
                        const SizedBox(height: 12),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            _statCard(
                              'Total Users',
                              users.length.toString(),
                              Icons.people_outline,
                            ),
                            _statCard(
                              'Total Jobs',
                              jobs.length.toString(),
                              Icons.work_outline,
                            ),
                            _statCard(
                              'New Users This Month',
                              newUsers.toString(),
                              Icons.person_add_alt,
                            ),
                            _statCard(
                              'Completion Rate',
                              '${completionRate.toStringAsFixed(1)}%',
                              Icons.check_circle_outline,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        _sectionTitle('Job Status Breakdown'),
                        const SizedBox(height: 12),

                        _statusRow('Open', open, jobs.length),
                        _statusRow('Assigned', assigned, jobs.length),
                        _statusRow('In Progress', inProgress, jobs.length),
                        _statusRow('Completed', completed, jobs.length),
                        _statusRow('Cancelled', cancelled, jobs.length),

                        const SizedBox(height: 28),
                        _sectionTitle('Monthly Job Growth'),
                        const SizedBox(height: 12),

                        _monthlyChart(months, monthlyJobs),

                        const SizedBox(height: 28),
                        _sectionTitle('Popular Job Categories'),
                        const SizedBox(height: 12),

                        if (topCategories.isEmpty)
                          _emptyMessage('No category data available.')
                        else
                          ...topCategories.take(5).map(
                            (entry) => _categoryRow(
                              entry.key,
                              entry.value,
                            ),
                          ),

                        const SizedBox(height: 28),
                        _sectionTitle('Work Performance'),
                        const SizedBox(height: 12),

                        _infoCard(
                          'Completed Jobs',
                          completed.toString(),
                          Icons.task_alt,
                        ),
                        const SizedBox(height: 10),
                        _infoCard(
                          'Average Completion Time',
                          averageHours == null
                              ? 'Not enough data'
                              : '${averageHours.toStringAsFixed(1)} hours',
                          Icons.timer_outlined,
                        ),

                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'Sunday–Monday Platform Analytics',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: gold, size: 22),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String title, int count, int total) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFE9ECF2),
              color: gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyChart(
    List<DateTime> months,
    Map<String, int> values,
  ) {
    final maxValue = math.max(
      1,
      values.values.fold<int>(0, (a, b) => math.max(a, b)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: SizedBox(
        height: 155,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: months.map((month) {
            final value = values[_monthKey(month)] ?? 0;
            final height = value == 0
                ? 4.0
                : math.max(8.0, value / maxValue * 100);

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 10,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: height,
                    width: 22,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _monthName(month),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _categoryRow(String name, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$count jobs',
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 23),
          const SizedBox(width: 13),
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
