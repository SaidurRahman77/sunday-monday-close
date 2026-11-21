import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientAnalyticsScreen extends StatefulWidget {
  const ClientAnalyticsScreen({super.key});

  @override
  State<ClientAnalyticsScreen> createState() => _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState extends State<ClientAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _preset = '30 days';
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    );
  }

  DateTimeRange _rangeFor(String preset) {
    final today = DateUtils.dateOnly(DateTime.now());
    switch (preset) {
      case '7 days':
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      case '6 months':
        return DateTimeRange(start: DateTime(today.year, today.month - 5, 1), end: today);
      case '1 year':
        return DateTimeRange(start: DateTime(today.year - 1, today.month, today.day), end: today);
      default:
        return DateTimeRange(start: today.subtract(const Duration(days: 29)), end: today);
    }
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _within(dynamic value, DateTimeRange range) {
    final date = _asDate(value);
    if (date == null) return false;
    final start = DateUtils.dateOnly(range.start);
    final endExclusive = DateUtils.dateOnly(range.end).add(const Duration(days: 1));
    return !date.isBefore(start) && date.isBefore(endExclusive);
  }

  DateTimeRange get _previousRange {
    final days = _range.end.difference(_range.start).inDays + 1;
    final previousEnd = _range.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: days - 1));
    return DateTimeRange(start: previousStart, end: previousEnd);
  }

  Future<void> _chooseCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      initialDateRange: _range,
      helpText: 'Select analytics date range',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = 'Custom';
      _range = DateTimeRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateUtils.dateOnly(picked.end),
      );
    });
  }

  void _selectPreset(String preset) {
    setState(() {
      _preset = preset;
      _range = _rangeFor(preset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view analytics.')),
      );
    }

    final jobsStream = _firestore
        .collection('jobs')
        .where('clientId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Job Analytics')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: jobsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Unable to load your job statistics.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allJobs = snapshot.data!.docs.map((doc) => doc.data()).toList();
          final currentJobs = allJobs.where((job) => _within(job['createdAt'], _range)).toList();
          final previousJobs = allJobs.where((job) => _within(job['createdAt'], _previousRange)).toList();

          final current = _metrics(currentJobs);
          final previous = _metrics(previousJobs);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _dateFilter(),
              const SizedBox(height: 18),
              Text(
                '${_formatDate(_range.start)} – ${_formatDate(_range.end)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Job overview'),
              const SizedBox(height: 12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 104,
                ),
                children: [
                  _MetricTile(title: 'Total jobs', value: '${current.total}', icon: Icons.work_outline),
                  _MetricTile(title: 'Open jobs', value: '${current.open}', icon: Icons.search),
                  _MetricTile(title: 'Assigned', value: '${current.assigned}', icon: Icons.assignment_outlined),
                  _MetricTile(title: 'In progress', value: '${current.inProgress}', icon: Icons.timelapse),
                  _MetricTile(title: 'Completed', value: '${current.completed}', icon: Icons.check_circle_outline),
                  _MetricTile(title: 'Cancelled', value: '${current.cancelled}', icon: Icons.cancel_outlined),
                ],
              ),
              const SizedBox(height: 12),
              _rateTile('Completion rate', current.completionRate),
              _rateTile('Cancellation rate', current.cancellationRate),
              const SizedBox(height: 24),
              const _SectionTitle('Compared with previous period'),
              const SizedBox(height: 12),
              _comparisonCard('Jobs posted', current.total, previous.total),
              _comparisonCard('Completed jobs', current.completed, previous.completed),
              _comparisonCard('Completion rate', current.completionRate, previous.completionRate, suffix: '%'),
              _comparisonCard(
                'Cancellation rate',
                current.cancellationRate,
                previous.cancellationRate,
                suffix: '%',
                lowerIsBetter: true,
              ),
            ],
          );
        },
      ),
    );
  }

  _ClientMetrics _metrics(List<Map<String, dynamic>> jobs) {
    String status(Map<String, dynamic> job) =>
        (job['status'] ?? '').toString().toLowerCase();

    final total = jobs.length;
    final completed = jobs.where((job) => status(job) == 'completed').length;
    final cancelled = jobs.where((job) => status(job) == 'cancelled').length;

    return _ClientMetrics(
      total: total,
      open: jobs.where((job) => status(job) == 'open').length,
      assigned: jobs.where((job) => status(job) == 'assigned').length,
      inProgress: jobs.where((job) => status(job) == 'in_progress').length,
      completed: completed,
      cancelled: cancelled,
      completionRate: total == 0 ? 0 : completed * 100 / total,
      cancellationRate: total == 0 ? 0 : cancelled * 100 / total,
    );
  }

  Widget _dateFilter() {
    const presets = ['7 days', '30 days', '6 months', '1 year'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Date range'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((preset) => ChoiceChip(
                  label: Text(preset),
                  selected: _preset == preset,
                  onSelected: (_) => _selectPreset(preset),
                )),
            ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 17),
              label: Text(_preset == 'Custom' ? 'Custom range' : 'Custom'),
              onPressed: _chooseCustomRange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _rateTile(String title, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${rate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 9),
            LinearProgressIndicator(value: (rate / 100).clamp(0.0, 1.0).toDouble(), minHeight: 7),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard(
    String title,
    num current,
    num previous, {
    String suffix = '',
    bool lowerIsBetter = false,
  }) {
    final difference = current - previous;
    final isUp = difference > 0;
    final isDown = difference < 0;
    final favorable = lowerIsBetter ? isDown : isUp;
    final neutral = difference == 0;
    final color = neutral ? Colors.grey : favorable ? Colors.green : Colors.red;
    final valueText = suffix == '%'
        ? '${difference.abs().toStringAsFixed(1)}%'
        : difference.abs().toStringAsFixed(0);

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('Current: ${_number(current)}$suffix  •  Previous: ${_number(previous)}$suffix'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(neutral ? Icons.remove : isUp ? Icons.trending_up : Icons.trending_down, color: color),
            const SizedBox(width: 4),
            Text(
              neutral ? 'No change' : '${isUp ? '+' : '-'}$valueText',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _number(num value) => value is int ? '$value' : value.toStringAsFixed(1);
}

class _ClientMetrics {
  const _ClientMetrics({
    required this.total,
    required this.open,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.completionRate,
    required this.cancellationRate,
  });

  final int total;
  final int open;
  final int assigned;
  final int inProgress;
  final int completed;
  final int cancelled;
  final double completionRate;
  final double cancellationRate;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
