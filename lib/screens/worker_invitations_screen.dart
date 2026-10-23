import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_invitation_service.dart';
import '../utils/app_error.dart';
import '../widgets/premium_ui.dart';

class WorkerInvitationsScreen extends StatefulWidget {
  const WorkerInvitationsScreen({
    super.key,
  });

  @override
  State<WorkerInvitationsScreen> createState() =>
      _WorkerInvitationsScreenState();
}

class _WorkerInvitationsScreenState
    extends State<WorkerInvitationsScreen> {
  final JobInvitationService _service =
      JobInvitationService();

  final Set<String> _busyInvitationIds =
      <String>{};

  Future<void> _accept(
    String invitationId,
  ) async {
    if (_busyInvitationIds.contains(
      invitationId,
    )) {
      return;
    }

    setState(() {
      _busyInvitationIds.add(
        invitationId,
      );
    });

    try {
      await _service.acceptInvitation(
        invitationId:
            invitationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Invitation accepted. The job is now assigned to you.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              error,
              fallback:
                  'Unable to accept this invitation. Please try again.',
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyInvitationIds.remove(
            invitationId,
          );
        });
      }
    }
  }

  Future<void> _reject(
    String invitationId,
  ) async {
    if (_busyInvitationIds.contains(
      invitationId,
    )) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
              context: context,
              builder: (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor:
                      AppColors.surface,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                  ),
                  title: Text(
                    'Decline invitation?',
                    style:
                        AppText.heading(
                      size: 18,
                    ),
                  ),
                  content: Text(
                    'The client will be notified that you declined this invitation.',
                    style:
                        AppText.body(
                      size: 12,
                      color:
                          AppColors.inkSoft,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style:
                            AppText.label(
                          size: 10.5,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.ink,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                      ),
                      child: Text(
                        'Decline',
                        style:
                            AppText.label(
                          size: 10.5,
                          color:
                              Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;

    if (!confirmed ||
        !mounted) {
      return;
    }

    setState(() {
      _busyInvitationIds.add(
        invitationId,
      );
    });

    try {
      await _service.rejectInvitation(
        invitationId:
            invitationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Invitation declined.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              error,
              fallback:
                  'Unable to decline this invitation. Please try again.',
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyInvitationIds.remove(
            invitationId,
          );
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
            ),
            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _service
                        .getWorkerInvitations(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                              .connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      'WORKER INVITATIONS STREAM ERROR: ${snapshot.error}',
                    );

                    return const _MessageState(
                      icon:
                          LucideIcons
                              .triangleAlert,
                      title:
                          'Unable to load invitations',
                      message:
                          'Please try again in a moment.',
                    );
                  }

                  final invitations =
                      snapshot.data ??
                          [];

                  if (invitations
                      .isEmpty) {
                    return const _MessageState(
                      icon:
                          LucideIcons.mailOpen,
                      title:
                          'No invitations yet',
                      message:
                          'When a client invites you to a job, it will appear here.',
                    );
                  }

                  final pending =
                      invitations
                          .where(
                            (invite) =>
                                invite['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'pending',
                          )
                          .length;

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
                            invitations.length,
                        pending:
                            pending,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Job invitations',
                        style:
                            AppText.heading(
                          size: 18,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      ...invitations.map(
                        (invitation) {
                          final invitationId =
                              invitation[
                                          'invitationId']
                                      ?.toString() ??
                                  '';

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _InvitationCard(
                              invitation:
                                  invitation,
                              busy:
                                  _busyInvitationIds
                                      .contains(
                                invitationId,
                              ),
                              onAccept: () {
                                _accept(
                                  invitationId,
                                );
                              },
                              onReject: () {
                                _reject(
                                  invitationId,
                                );
                              },
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

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        16,
        20,
        18,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                AppColors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color:
                AppColors.ink,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap:
                  onBack,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child:
                  const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    LucideIcons
                        .arrowLeft,
                    size: 20,
                    color:
                        Colors.white,
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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Invitations',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Review jobs clients invited you to',
                  style:
                      AppText.body(
                    size: 10.5,
                    color:
                        AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              LucideIcons.mail,
              size: 18,
              color:
                  AppColors.ink,
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
    required this.pending,
  });

  final int total;
  final int pending;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewItem(
              value:
                  pending.toString(),
              label:
                  'Pending',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color:
                Colors.white
                    .withValues(
              alpha: 0.12,
            ),
          ),
          Expanded(
            child: _OverviewItem(
              value:
                  total.toString(),
              label:
                  'Total',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewItem
    extends StatelessWidget {
  const _OverviewItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          value,
          style:
              AppText.heading(
            size: 23,
            color:
                Colors.white,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          label,
          style:
              AppText.body(
            size: 10,
            color:
                Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _InvitationCard
    extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final Map<String, dynamic>
      invitation;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        invitation['jobTitle']
                ?.toString()
                .trim() ??
            'Job invitation';

    final status =
        invitation['status']
                ?.toString()
                .toLowerCase() ??
            'pending';

    final createdAt =
        invitation['createdAt'];

    final isPending =
        status == 'pending';

    final isAccepted =
        status == 'accepted';

    final statusText =
        isPending
            ? 'PENDING'
            : isAccepted
                ? 'ACCEPTED'
                : 'DECLINED';

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const PremiumIconBox(
                icon:
                    LucideIcons
                        .briefcaseBusiness,
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
                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 14.5,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      _formatTimestamp(
                        createdAt,
                      ),
                      style:
                          AppText.body(
                        size: 9.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      isPending
                          ? AppColors
                              .goldSoft
                          : AppColors
                              .background,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  statusText,
                  style:
                      AppText.label(
                    size: 7.5,
                    color:
                        isAccepted
                            ? AppColors
                                .success
                            : AppColors
                                .ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            isPending
                ? 'A client wants you to work on this job.'
                : isAccepted
                    ? 'You accepted this invitation. The job is now in Active work.'
                    : 'You declined this invitation.',
            style:
                AppText.body(
              size: 10.5,
              color:
                  AppColors.inkSoft,
            ),
          ),
          if (isPending) ...[
            const SizedBox(
              height: 16,
            ),
            if (busy)
              const Center(
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      AppColors.ink,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          onReject,
                      icon:
                          const Icon(
                        LucideIcons.x,
                        size: 16,
                      ),
                      label: Text(
                        'Decline',
                        style:
                            AppText.label(
                          size: 11,
                        ),
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            AppColors
                                .inkSoft,
                        side:
                            const BorderSide(
                          color:
                              AppColors
                                  .line,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical:
                              13,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          onAccept,
                      icon:
                          const Icon(
                        LucideIcons
                            .check,
                        size: 16,
                      ),
                      label: Text(
                        'Accept',
                        style:
                            AppText.label(
                          size: 11,
                          color:
                              Colors.white,
                        ),
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.ink,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical:
                              13,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _MessageState
    extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            26,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            border:
                Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              PremiumIconBox(
                icon:
                    icon,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style:
                    AppText.heading(
                  size: 17,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTimestamp(
  dynamic raw,
) {
  if (raw is! Timestamp) {
    return 'Recently';
  }

  final date =
      raw.toDate();

  final now =
      DateTime.now();

  final difference =
      now.difference(
    date,
  );

  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  return '${date.day}/${date.month}/${date.year}';
}
