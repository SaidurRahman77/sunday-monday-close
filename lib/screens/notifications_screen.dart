import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/notification_service.dart';
import '../utils/app_error.dart';
import '../widgets/premium_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService();

  bool _markingAll = false;

  Future<void> _markAllAsRead() async {
    if (_markingAll) {
      return;
    }

    setState(() {
      _markingAll = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications marked as read.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              e,
              fallback:
                  'Unable to mark all notifications as read. Please try again.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(
              onMarkAll: _markingAll
                  ? null
                  : _markAllAsRead,
            ),
            Expanded(
              child: StreamBuilder<
                  List<Map<String, dynamic>>>(
                stream: _notificationService
                    .getMyNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      'NOTIFICATIONS STREAM ERROR: ${snapshot.error}',
                    );

                    return const _ErrorState(
                      message:
                          'Please try again in a moment.',
                    );
                  }

                  final notifications =
                      snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const _EmptyState();
                  }

                  final unreadCount =
                      notifications.where(
                    (notification) =>
                        notification['isRead'] !=
                        true,
                  ).length;

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      40,
                    ),
                    children: [
                      _OverviewCard(
                        total:
                            notifications.length,
                        unread: unreadCount,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Notifications',
                              style: AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            unreadCount == 0
                                ? 'All caught up'
                                : '$unreadCount unread',
                            style: AppText.body(
                              size: 10.5,
                              color:
                                  AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      ...notifications.map(
                        (notification) {
                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),
                            child:
                                _NotificationCard(
                              notification:
                                  notification,
                              service:
                                  _notificationService,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader
    extends StatelessWidget {
  const _NotificationsHeader({
    required this.onMarkAll,
  });

  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.ink,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Updates about your jobs and work',
                  style: AppText.body(
                    size: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onMarkAll,
            child: Text(
              'Mark all read',
              style: AppText.label(
                size: 9.5,
                color: onMarkAll == null
                    ? AppColors.muted
                    : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.total,
    required this.unread,
  });

  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  unread == 0
                      ? 'You are all caught up'
                      : '$unread unread ${unread == 1 ? 'notification' : 'notifications'}',
                  style: AppText.heading(
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '$total total ${total == 1 ? 'notification' : 'notifications'}',
                  style: AppText.body(
                    size: 9.5,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard
    extends StatefulWidget {
  const _NotificationCard({
    required this.notification,
    required this.service,
  });

  final Map<String, dynamic>
      notification;

  final NotificationService service;

  @override
  State<_NotificationCard>
      createState() =>
          _NotificationCardState();
}

class _NotificationCardState
    extends State<_NotificationCard> {
  bool _busy = false;

  Future<void> _markRead() async {
    if (_busy) {
      return;
    }

    final notificationId =
        widget.notification[
                    'notificationId']
                ?.toString() ??
            '';

    if (notificationId.isEmpty) {
      return;
    }

    if (widget.notification['isRead'] ==
        true) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await widget.service.markAsRead(
        notificationId,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              e,
              fallback:
                  'Unable to mark this notification as read. Please try again.',
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification =
        widget.notification;

    final title =
        notification['title']
                ?.toString()
                .trim() ??
            'Notification';

    final message =
        notification['message']
                ?.toString()
                .trim() ??
            '';

    final type =
        notification['type']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final isRead =
        notification['isRead'] == true;

    final createdAt =
        notification['createdAt']
            as Timestamp?;

    final style =
        _notificationStyle(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _markRead,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.surface
                : AppColors.goldSoft
                    .withValues(
                    alpha: 0.55,
                  ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: isRead
                  ? AppColors.line
                  : AppColors.gold
                      .withValues(
                      alpha: 0.35,
                    ),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment:
                    Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: 18,
                  color: style.color,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style:
                                AppText.heading(
                              size: 13,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.gold,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        message,
                        style: AppText.body(
                          size: 10.5,
                          color:
                              AppColors.inkSoft,
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          style.icon,
                          size: 11,
                          color:
                              AppColors.muted,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          style.label,
                          style: AppText.label(
                            size: 8,
                            color:
                                AppColors.muted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(
                            createdAt,
                          ),
                          style: AppText.body(
                            size: 8.5,
                            color:
                                AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_busy) ...[
                const SizedBox(
                  width: 8,
                ),
                const SizedBox(
                  width: 15,
                  height: 15,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          34,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const PremiumIconBox(
              icon: LucideIcons.bell,
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              'No notifications yet',
              style: AppText.heading(
                size: 19,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Job applications, work updates and reviews will appear here.',
              textAlign:
                  TextAlign.center,
              style: AppText.body(
                size: 11.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Text(
          'Unable to load notifications.\n$message',
          textAlign:
              TextAlign.center,
          style: AppText.body(
            size: 12,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

_NotificationStyle _notificationStyle(
  String type,
) {
  switch (type) {
    case 'job_application':
      return const _NotificationStyle(
        icon: LucideIcons.userPlus,
        label: 'Application',
        color: AppColors.gold,
      );

    case 'application_accepted':
      return const _NotificationStyle(
        icon: LucideIcons.circleCheck,
        label: 'Accepted',
        color: AppColors.success,
      );

    case 'application_rejected':
      return const _NotificationStyle(
        icon: LucideIcons.circleX,
        label: 'Application',
        color: AppColors.muted,
      );

    case 'work_started':
      return const _NotificationStyle(
        icon: LucideIcons.play,
        label: 'Work update',
        color: AppColors.gold,
      );

    case 'work_completed':
      return const _NotificationStyle(
        icon: LucideIcons.badgeCheck,
        label: 'Work completed',
        color: AppColors.success,
      );

    case 'new_review':
      return const _NotificationStyle(
        icon: LucideIcons.star,
        label: 'Review',
        color: AppColors.gold,
      );

    default:
      return const _NotificationStyle(
        icon: LucideIcons.bell,
        label: 'Notification',
        color: AppColors.ink,
      );
  }
}

String _formatTime(
  Timestamp? timestamp,
) {
  if (timestamp == null) {
    return 'Just now';
  }

  final date =
      timestamp.toDate();

  final now = DateTime.now();

  final difference =
      now.difference(date);

  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  final day =
      date.day.toString().padLeft(
            2,
            '0',
          );

  final month =
      date.month.toString().padLeft(
            2,
            '0',
          );

  return '$day/$month/${date.year}';
}
