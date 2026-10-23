import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/chat_service.dart';
import '../widgets/premium_ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.jobTitle,
    required this.otherUserName,
    this.otherUserPhotoUrl = '',
  });

  final String conversationId;
  final String jobTitle;
  final String otherUserName;
  final String otherUserPhotoUrl;

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final ChatService _chatService =
      ChatService();

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  final FocusNode _messageFocusNode =
      FocusNode();

  bool _sending = false;
  String? _lastReadMessageId;

  String get _currentUserId =>
      FirebaseAuth
              .instance
              .currentUser
              ?.uid ??
          '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _chatService.markConversationRead(
          conversationId:
              widget.conversationId,
        );
      },
    );
  }

  void _markReadForLatestMessage(
    List<Map<String, dynamic>> messages,
  ) {
    if (messages.isEmpty) {
      return;
    }

    final latest =
        messages.first;

    final latestMessageId =
        latest['messageId']
                ?.toString() ??
            '';

    final senderId =
        latest['senderId']
                ?.toString() ??
            '';

    if (latestMessageId.isEmpty ||
        senderId == _currentUserId ||
        latestMessageId ==
            _lastReadMessageId) {
      return;
    }

    _lastReadMessageId =
        latestMessageId;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _chatService.markConversationRead(
          conversationId:
              widget.conversationId,
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty ||
        _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _chatService.sendMessage(
        conversationId:
            widget.conversationId,
        text:
            text,
      );

      _messageController.clear();

      if (mounted) {
        _messageFocusNode
            .requestFocus();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(
              error,
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true,
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              otherUserName:
                  widget.otherUserName,
              photoUrl:
                  widget.otherUserPhotoUrl,
              jobTitle:
                  widget.jobTitle,
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
            ),

            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child:
                        _ChatBackground(),
                  ),

                  StreamBuilder<
                      List<
                          Map<String,
                              dynamic>>>(
                    stream:
                        _chatService
                            .getMessages(
                      conversationId:
                          widget
                              .conversationId,
                    ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                AppColors
                                    .ink,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _ChatStateMessage(
                          icon:
                              LucideIcons
                                  .triangleAlert,
                          title:
                              'Unable to load messages',
                          message:
                              snapshot.error
                                  .toString(),
                        );
                      }

                      final messages =
                          snapshot.data ??
                              [];

                      _markReadForLatestMessage(
                        messages,
                      );

                      if (messages.isEmpty) {
                        return _ChatStateMessage(
                          icon:
                              LucideIcons
                                  .messageCircle,
                          title:
                              'Start the conversation',
                          message:
                              'Ask ${widget.otherUserName} about the job, schedule, requirements or anything else you need to know.',
                        );
                      }

                      return ListView.builder(
                        controller:
                            _scrollController,
                        reverse:
                            true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag,
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          18,
                          12,
                          16,
                        ),
                        itemCount:
                            messages.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final message =
                              messages[
                                  index];

                          final senderId =
                              message[
                                          'senderId']
                                      ?.toString() ??
                                  '';

                          final text =
                              message[
                                          'text']
                                      ?.toString() ??
                                  '';

                          final createdAt =
                              message[
                                  'createdAt'];

                          final isMine =
                              senderId ==
                                  _currentUserId;

                          final newerMessage =
                              index > 0
                                  ? messages[
                                      index -
                                          1]
                                  : null;

                          final olderMessage =
                              index <
                                      messages
                                              .length -
                                          1
                                  ? messages[
                                      index +
                                          1]
                                  : null;

                          final newerSenderId =
                              newerMessage?[
                                          'senderId']
                                      ?.toString() ??
                                  '';

                          final olderSenderId =
                              olderMessage?[
                                          'senderId']
                                      ?.toString() ??
                                  '';

                          final isFirstInGroup =
                              olderSenderId !=
                                  senderId;

                          final isLastInGroup =
                              newerSenderId !=
                                  senderId;

                          return _MessageRow(
                            text:
                                text,
                            isMine:
                                isMine,
                            createdAt:
                                createdAt,
                            otherUserName:
                                widget
                                    .otherUserName,
                            isFirstInGroup:
                                isFirstInGroup,
                            isLastInGroup:
                                isLastInGroup,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            _MessageComposer(
              controller:
                  _messageController,
              focusNode:
                  _messageFocusNode,
              sending:
                  _sending,
              onSend:
                  _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackground
    extends StatelessWidget {
  const _ChatBackground();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          const BoxDecoration(
        color:
            AppColors.background,
      ),
      child: Stack(
        children: [
          Positioned(
            right:
                -55,
            top:
                70,
            child: Container(
              width:
                  150,
              height:
                  150,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    AppColors.goldSoft
                        .withValues(
                  alpha:
                      0.28,
                ),
              ),
            ),
          ),
          Positioned(
            left:
                -45,
            bottom:
                90,
            child: Container(
              width:
                  130,
              height:
                  130,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    AppColors.surface
                        .withValues(
                  alpha:
                      0.65,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader
    extends StatelessWidget {
  const _ChatHeader({
    required this.otherUserName,
    required this.photoUrl,
    required this.jobTitle,
    required this.onBack,
  });

  final String otherUserName;
  final String photoUrl;
  final String jobTitle;
  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        border: const Border(
          bottom:
              BorderSide(
            color:
                AppColors.line,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  0.035,
            ),
            blurRadius:
                12,
            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color:
                Colors.transparent,
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
                width:
                    42,
                height:
                    42,
                child: Center(
                  child: Icon(
                    LucideIcons
                        .arrowLeft,
                    size:
                        21,
                    color:
                        AppColors.ink,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                4,
          ),

          _Avatar(
            name:
                otherUserName,
            photoUrl:
                photoUrl,
            size:
                44,
          ),

          const SizedBox(
            width:
                11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  otherUserName,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppText.heading(
                    size:
                        15.5,
                  ),
                ),
                const SizedBox(
                  height:
                      3,
                ),
                Row(
                  children: [
                    const Icon(
                      LucideIcons
                          .briefcase,
                      size:
                          11,
                      color:
                          AppColors.gold,
                    ),
                    const SizedBox(
                      width:
                          5,
                    ),
                    Expanded(
                      child: Text(
                        jobTitle,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppText.body(
                          size:
                              9.5,
                          color:
                              AppColors
                                  .muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          Container(
            width:
                36,
            height:
                36,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .background,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              border:
                  Border.all(
                color:
                    AppColors.line,
              ),
            ),
            child:
                const Icon(
              LucideIcons
                  .messageCircle,
              size:
                  17,
              color:
                  AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar
    extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.size,
    this.photoUrl = '',
  });

  final String name;
  final double size;
  final String photoUrl;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          size,
      height:
          size,
      clipBehavior:
          Clip.antiAlias,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            AppColors.goldSoft,
        shape:
            BoxShape.circle,
        border:
            Border.all(
          color:
              AppColors.gold
                  .withValues(
            alpha:
                0.35,
          ),
        ),
      ),
      child:
          photoUrl.trim().isNotEmpty
              ? Image.network(
                  photoUrl.trim(),
                  width:
                      double.infinity,
                  height:
                      double.infinity,
                  fit:
                      BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Center(
                      child: Text(
                        _initials(
                          name,
                        ),
                        style:
                            AppText.label(
                          size:
                              size *
                                  0.25,
                          color:
                              AppColors.ink,
                        ),
                      ),
                    );
                  },
                )
              : Text(
                  _initials(
                    name,
                  ),
                  style:
                      AppText.label(
                    size:
                        size *
                            0.25,
                    color:
                        AppColors.ink,
                  ),
                ),
    );
  }
}

class _MessageRow
    extends StatelessWidget {
  const _MessageRow({
    required this.text,
    required this.isMine,
    required this.createdAt,
    required this.otherUserName,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  final String text;
  final bool isMine;
  final dynamic createdAt;
  final String otherUserName;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottomSpacing =
        isLastInGroup
            ? 12.0
            : 3.0;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            bottomSpacing,
      ),
      child: Row(
        mainAxisAlignment:
            isMine
                ? MainAxisAlignment
                    .end
                : MainAxisAlignment
                    .start,
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            SizedBox(
              width:
                  30,
              child:
                  isLastInGroup
                      ? _Avatar(
                          name:
                              otherUserName,
                          size:
                              28,
                        )
                      : const SizedBox
                          .shrink(),
            ),
            const SizedBox(
              width:
                  7,
            ),
          ],

          Flexible(
            child: Container(
              constraints:
                  BoxConstraints(
                maxWidth:
                    MediaQuery.of(
                          context,
                        ).size.width *
                        0.74,
              ),
              padding:
                  const EdgeInsets
                      .fromLTRB(
                14,
                10,
                12,
                8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    isMine
                        ? AppColors
                            .ink
                        : AppColors
                            .surface,
                borderRadius:
                    _bubbleRadius(
                  isMine:
                      isMine,
                  isFirstInGroup:
                      isFirstInGroup,
                  isLastInGroup:
                      isLastInGroup,
                ),
                border:
                    isMine
                        ? null
                        : Border.all(
                            color:
                                AppColors
                                    .line,
                          ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withValues(
                      alpha:
                          isMine
                              ? 0.055
                              : 0.025,
                    ),
                    blurRadius:
                        10,
                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .end,
                children: [
                  Align(
                    alignment:
                        Alignment
                            .centerLeft,
                    child: Text(
                      text,
                      style:
                          AppText.body(
                        size:
                            12.5,
                        color:
                            isMine
                                ? Colors
                                    .white
                                : AppColors
                                    .inkSoft,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height:
                        4,
                  ),
                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(
                          createdAt,
                        ),
                        style:
                            AppText.body(
                          size:
                              7.5,
                          color:
                              isMine
                                  ? Colors
                                      .white54
                                  : AppColors
                                      .muted,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(
                          width:
                              4,
                        ),
                        const Icon(
                          LucideIcons
                              .check,
                          size:
                              10,
                          color:
                              Colors.white54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMine)
            const SizedBox(
              width:
                  6,
            ),
        ],
      ),
    );
  }

  BorderRadius _bubbleRadius({
    required bool isMine,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    const large =
        Radius.circular(
      18,
    );

    const small =
        Radius.circular(
      6,
    );

    if (isMine) {
      return BorderRadius.only(
        topLeft:
            large,
        topRight:
            isFirstInGroup
                ? large
                : small,
        bottomLeft:
            large,
        bottomRight:
            isLastInGroup
                ? small
                : large,
      );
    }

    return BorderRadius.only(
      topLeft:
          isFirstInGroup
              ? large
              : small,
      topRight:
          large,
      bottomLeft:
          isLastInGroup
              ? small
              : large,
      bottomRight:
          large,
    );
  }
}

class _MessageComposer
    extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController
      controller;

  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(
        12,
        9,
        12,
        9 +
            MediaQuery.of(
              context,
            ).padding.bottom,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        border: const Border(
          top:
              BorderSide(
            color:
                AppColors.line,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  0.035,
            ),
            blurRadius:
                16,
            offset:
                const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),
      child:
          ValueListenableBuilder<
              TextEditingValue>(
        valueListenable:
            controller,
        builder: (
          context,
          value,
          _,
        ) {
          final hasText =
              value.text
                  .trim()
                  .isNotEmpty;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .end,
            children: [
              Expanded(
                child: Container(
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .background,
                    borderRadius:
                        BorderRadius
                            .circular(
                      24,
                    ),
                    border:
                        Border.all(
                      color:
                          AppColors
                              .line,
                    ),
                  ),
                  child: TextField(
                    controller:
                        controller,
                    focusNode:
                        focusNode,
                    minLines:
                        1,
                    maxLines:
                        5,
                    maxLength:
                        2000,
                    keyboardType:
                        TextInputType
                            .multiline,
                    textInputAction:
                        TextInputAction
                            .newline,
                    textCapitalization:
                        TextCapitalization
                            .sentences,
                    style:
                        AppText.body(
                      size:
                          12.5,
                      color:
                          AppColors
                              .ink,
                    ),
                    decoration:
                        InputDecoration(
                      counterText:
                          '',
                      hintText:
                          'Message...',
                      hintStyle:
                          AppText.body(
                        size:
                            12,
                        color:
                            AppColors
                                .muted,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        12,
                        16,
                        12,
                      ),
                      border:
                          InputBorder
                              .none,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      180,
                ),
                width:
                    48,
                height:
                    48,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      sending
                          ? AppColors
                              .line
                          : hasText
                              ? AppColors
                                  .ink
                              : AppColors
                                  .goldSoft,
                ),
                child:
                    Material(
                  color:
                      Colors
                          .transparent,
                  shape:
                      const CircleBorder(),
                  child: InkWell(
                    onTap:
                        sending ||
                                !hasText
                            ? null
                            : onSend,
                    customBorder:
                        const CircleBorder(),
                    child:
                        Center(
                      child:
                          sending
                              ? const SizedBox(
                                  width:
                                      17,
                                  height:
                                      17,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : Icon(
                                  LucideIcons
                                      .send,
                                  size:
                                      18,
                                  color:
                                      hasText
                                          ? Colors
                                              .white
                                          : AppColors
                                              .ink,
                                ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatStateMessage
    extends StatelessWidget {
  const _ChatStateMessage({
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
          30,
        ),
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth:
                360,
          ),
          padding:
              const EdgeInsets.all(
            24,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              26,
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
              Container(
                width:
                    52,
                height:
                    52,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .goldSoft,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  icon,
                  size:
                      21,
                  color:
                      AppColors.ink,
                ),
              ),
              const SizedBox(
                height:
                    14,
              ),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style:
                    AppText.heading(
                  size:
                      17,
                ),
              ),
              const SizedBox(
                height:
                    6,
              ),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    AppText.body(
                  size:
                      11,
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

String _formatMessageTime(
  dynamic raw,
) {
  if (raw is! Timestamp) {
    return 'Sending...';
  }

  final date =
      raw.toDate();

  final hour24 =
      date.hour;

  final minute =
      date.minute;

  final period =
      hour24 >= 12
          ? 'PM'
          : 'AM';

  var hour12 =
      hour24 % 12;

  if (hour12 == 0) {
    hour12 = 12;
  }

  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

String _initials(
  String name,
) {
  final parts =
      name
          .trim()
          .split(
            RegExp(
              r'\s+',
            ),
          )
          .where(
            (part) =>
                part.isNotEmpty,
          )
          .toList();

  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first
        .substring(
          0,
          1,
        )
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'
      .toUpperCase();
}

String _friendlyError(
  Object error,
) {
  var text =
      error.toString();

  if (text.startsWith(
    'Bad state: ',
  )) {
    text =
        text.substring(
      'Bad state: '.length,
    );
  }

  if (text.startsWith(
    'Invalid argument(s): ',
  )) {
    text =
        text.substring(
      'Invalid argument(s): '
          .length,
    );
  }

  if (text.contains(
    'permission-denied',
  )) {
    return 'Permission denied. Check Firestore rules.';
  }

  return text;
}
