import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/chat_service.dart';
import '../widgets/premium_ui.dart';
import 'chat_screen.dart';

enum _MessageFilter {
  all,
  unread,
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
  });

  @override
  State<MessagesScreen> createState() =>
      _MessagesScreenState();
}

class _MessagesScreenState
    extends State<MessagesScreen> {
  final ChatService _chatService =
      ChatService();

  final TextEditingController
      _searchController =
      TextEditingController();

  final Map<String, String>
      _nameCache = {};

  final Map<String, String>
      _photoCache = {};

  String _searchQuery = '';

  _MessageFilter _filter =
      _MessageFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _MessagesHeader(
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
            ),

            _SearchAndFilter(
              controller:
                  _searchController,
              selectedFilter:
                  _filter,
              onSearchChanged:
                  (value) {
                setState(() {
                  _searchQuery =
                      value
                          .trim()
                          .toLowerCase();
                });
              },
              onClear: () {
                _searchController
                    .clear();

                setState(() {
                  _searchQuery = '';
                });
              },
              onFilterChanged:
                  (filter) {
                setState(() {
                  _filter = filter;
                });
              },
            ),

            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _chatService
                        .getMyConversations(),
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
                            AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _MessagesState(
                      icon:
                          LucideIcons
                              .triangleAlert,
                      title:
                          'Unable to load messages',
                      message:
                          _friendlyError(
                        snapshot.error!,
                      ),
                    );
                  }

                  final conversations =
                      snapshot.data ??
                          [];

                  if (conversations
                      .isEmpty) {
                    return const _MessagesState(
                      icon:
                          LucideIcons
                              .messageCircle,
                      title:
                          'No conversations yet',
                      message:
                          'When you message a client or worker, your conversations will appear here.',
                    );
                  }

                  return FutureBuilder<
                      List<
                          _ConversationData>>(
                    future:
                        _prepareConversations(
                      conversations,
                    ),
                    builder: (
                      context,
                      preparedSnapshot,
                    ) {
                      if (preparedSnapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting &&
                          !preparedSnapshot
                              .hasData) {
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

                      if (preparedSnapshot
                          .hasError) {
                        return _MessagesState(
                          icon:
                              LucideIcons
                                  .triangleAlert,
                          title:
                              'Unable to load inbox',
                          message:
                              _friendlyError(
                            preparedSnapshot
                                .error!,
                          ),
                        );
                      }

                      final prepared =
                          preparedSnapshot
                                  .data ??
                              [];

                      final filtered =
                          prepared.where(
                        (conversation) {
                          if (_filter ==
                                  _MessageFilter
                                      .unread &&
                              conversation
                                      .unreadCount ==
                                  0) {
                            return false;
                          }

                          if (_searchQuery
                              .isEmpty) {
                            return true;
                          }

                          final searchable =
                              '${conversation.otherUserName} '
                              '${conversation.jobTitle} '
                              '${conversation.lastMessage}'
                                  .toLowerCase();

                          return searchable
                              .contains(
                            _searchQuery,
                          );
                        },
                      ).toList();

                      if (filtered
                          .isEmpty) {
                        if (_filter ==
                                _MessageFilter
                                    .unread &&
                            _searchQuery
                                .isEmpty) {
                          return const _MessagesState(
                            icon:
                                LucideIcons
                                    .circleCheck,
                            title:
                                'All caught up',
                            message:
                                'You have no unread conversations.',
                          );
                        }

                        return const _MessagesState(
                          icon:
                              LucideIcons
                                  .search,
                          title:
                              'No conversations found',
                          message:
                              'Try another name, job title or message.',
                        );
                      }

                      return ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag,
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          8,
                          16,
                          30,
                        ),
                        itemCount:
                            filtered.length,
                        separatorBuilder:
                            (
                          context,
                          index,
                        ) =>
                                const SizedBox(
                          height:
                              10,
                        ),
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          return _ConversationTile(
                            data:
                                filtered[
                                    index],
                            chatService:
                                _chatService,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_ConversationData>>
      _prepareConversations(
    List<Map<String, dynamic>>
        conversations,
  ) async {
    final currentUserId =
        FirebaseAuth
                .instance
                .currentUser
                ?.uid ??
            '';

    final result =
        <_ConversationData>[];

    for (final conversation
        in conversations) {
      final clientId =
          conversation['clientId']
                  ?.toString() ??
              '';

      final workerId =
          conversation['workerId']
                  ?.toString() ??
              '';

      final otherUserId =
          currentUserId ==
                  clientId
              ? workerId
              : clientId;

      final otherUserName =
          await _getUserName(
        otherUserId,
      );

      final otherUserPhotoUrl =
          _photoCache[otherUserId] ??
              '';

      final conversationId =
          conversation[
                      'conversationId']
                  ?.toString() ??
              '';

      final jobTitle =
          conversation['jobTitle']
                  ?.toString()
                  .trim() ??
              'Job';

      final lastMessage =
          conversation['lastMessage']
                  ?.toString()
                  .trim() ??
              '';

      final lastMessageAt =
          conversation[
              'lastMessageAt'];

      final unreadCount =
          _chatService
              .getUnreadCountForConversation(
        conversation,
      );

      result.add(
        _ConversationData(
          conversationId:
              conversationId,
          otherUserName:
              otherUserName,
          otherUserPhotoUrl:
              otherUserPhotoUrl,
          jobTitle:
              jobTitle,
          lastMessage:
              lastMessage,
          lastMessageAt:
              lastMessageAt,
          unreadCount:
              unreadCount,
        ),
      );
    }

    return result;
  }

  Future<String> _getUserName(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return 'User';
    }

    final cached =
        _nameCache[userId];

    if (cached != null) {
      return cached;
    }

    try {
      final snapshot =
          await FirebaseFirestore
              .instance
              .collection(
                'users',
              )
              .doc(
                userId,
              )
              .get();

      final data =
          snapshot.data();

      final name =
          data?['name']
                  ?.toString()
                  .trim() ??
              '';

      final email =
          data?['email']
                  ?.toString()
                  .trim() ??
              '';

      final photoUrl =
          data?['photoUrl']
                  ?.toString()
                  .trim() ??
              '';

      final displayName =
          name.isNotEmpty
              ? name
              : email.isNotEmpty
                  ? email
                  : 'User';

      _nameCache[userId] =
          displayName;

      _photoCache[userId] =
          photoUrl;

      return displayName;
    } catch (_) {
      return 'User';
    }
  }
}

class _ConversationData {
  const _ConversationData({
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.jobTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String conversationId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String jobTitle;
  final String lastMessage;
  final dynamic lastMessageAt;
  final int unreadCount;
}

class _SearchAndFilter
    extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClear,
    required this.onFilterChanged,
  });

  final TextEditingController
      controller;

  final _MessageFilter
      selectedFilter;

  final ValueChanged<String>
      onSearchChanged;

  final VoidCallback onClear;

  final ValueChanged<_MessageFilter>
      onFilterChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextField(
            controller:
                controller,
            onChanged:
                onSearchChanged,
            textInputAction:
                TextInputAction.search,
            style:
                AppText.body(
              size:
                  12,
              color:
                  AppColors.ink,
            ),
            decoration:
                InputDecoration(
              hintText:
                  'Search conversations',
              hintStyle:
                  AppText.body(
                size:
                    11.5,
                color:
                    AppColors.muted,
              ),
              prefixIcon:
                  const Icon(
                LucideIcons.search,
                size:
                    18,
                color:
                    AppColors.muted,
              ),
              suffixIcon:
                  controller
                          .text
                          .isEmpty
                      ? null
                      : IconButton(
                          onPressed:
                              onClear,
                          icon:
                              const Icon(
                            LucideIcons.x,
                            size:
                                17,
                            color:
                                AppColors
                                    .muted,
                          ),
                        ),
              filled:
                  true,
              fillColor:
                  AppColors.surface,
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    14,
                vertical:
                    13,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      AppColors.line,
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      AppColors.line,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      AppColors.ink,
                ),
              ),
            ),
          ),

          const SizedBox(
            height:
                11,
          ),

          Row(
            children: [
              _FilterButton(
                icon:
                    LucideIcons
                        .messageCircle,
                label:
                    'All',
                selected:
                    selectedFilter ==
                        _MessageFilter
                            .all,
                onTap: () {
                  onFilterChanged(
                    _MessageFilter
                        .all,
                  );
                },
              ),

              const SizedBox(
                width:
                    8,
              ),

              _FilterButton(
                icon:
                    LucideIcons.mail,
                label:
                    'Unread',
                selected:
                    selectedFilter ==
                        _MessageFilter
                            .unread,
                onTap: () {
                  onFilterChanged(
                    _MessageFilter
                        .unread,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterButton
    extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? AppColors.ink
              : AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        30,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        child: Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                14,
            vertical:
                9,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? AppColors.ink
                      : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                size:
                    14,
                color:
                    selected
                        ? Colors.white
                        : AppColors
                            .muted,
              ),

              const SizedBox(
                width:
                    6,
              ),

              Text(
                label,
                style:
                    AppText.label(
                  size:
                      10,
                  color:
                      selected
                          ? Colors
                              .white
                          : AppColors
                              .ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile
    extends StatelessWidget {
  const _ConversationTile({
    required this.data,
    required this.chatService,
  });

  final _ConversationData data;
  final ChatService chatService;

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasUnread =
        data.unreadCount >
            0;

    return Material(
      color:
          hasUnread
              ? AppColors.goldSoft
                  .withValues(
                alpha:
                    0.55,
              )
              : AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap:
            data.conversationId
                    .isEmpty
                ? null
                : () async {
                    try {
                      await chatService
                          .markConversationRead(
                        conversationId:
                            data
                                .conversationId,
                      );
                    } catch (_) {
                      // Chat can still open.
                    }

                    if (!context
                        .mounted) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(
                          conversationId:
                              data
                                  .conversationId,
                          jobTitle:
                              data.jobTitle,
                          otherUserName:
                              data
                                  .otherUserName,
                          otherUserPhotoUrl:
                              data
                                  .otherUserPhotoUrl,
                        ),
                      ),
                    );
                  },
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            16,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  hasUnread
                      ? AppColors.gold
                      : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Container(
                    width:
                        48,
                    height:
                        48,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      border:
                          Border.all(
                        color:
                            AppColors.line,
                      ),
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child:
                        data.otherUserPhotoUrl
                                .isNotEmpty
                            ? Image.network(
                                data.otherUserPhotoUrl,
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
                                        data.otherUserName,
                                      ),
                                      style:
                                          AppText.heading(
                                        size:
                                            13,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Text(
                                _initials(
                                  data.otherUserName,
                                ),
                                style:
                                    AppText.heading(
                                  size:
                                      13,
                                ),
                              ),
                  ),

                  if (hasUnread)
                    Positioned(
                      right:
                          -4,
                      top:
                          -4,
                      child: Container(
                        width:
                            12,
                        height:
                            12,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.gold,
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                AppColors
                                    .surface,
                            width:
                                2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width:
                    13,
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
                            data
                                .otherUserName,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                AppText.heading(
                              size:
                                  14,
                            ),
                          ),
                        ),

                        if (data
                                .lastMessageAt
                            is Timestamp)
                          Text(
                            _formatConversationTime(
                              data
                                  .lastMessageAt,
                            ),
                            style:
                                AppText.body(
                              size:
                                  8.5,
                              color:
                                  hasUnread
                                      ? AppColors
                                          .ink
                                      : AppColors
                                          .muted,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          4,
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
                            data.jobTitle,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                AppText.label(
                              size:
                                  8.5,
                              color:
                                  AppColors
                                      .gold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height:
                          5,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.lastMessage
                                    .isEmpty
                                ? 'Conversation started'
                                : data
                                    .lastMessage,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                hasUnread
                                    ? AppText.label(
                                        size:
                                            10.5,
                                        color:
                                            AppColors
                                                .ink,
                                      )
                                    : AppText.body(
                                        size:
                                            10.5,
                                        color:
                                            AppColors
                                                .muted,
                                      ),
                          ),
                        ),

                        if (hasUnread) ...[
                          const SizedBox(
                            width:
                                8,
                          ),

                          Container(
                            constraints:
                                const BoxConstraints(
                              minWidth:
                                  22,
                              minHeight:
                                  22,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  6,
                            ),
                            alignment:
                                Alignment.center,
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.ink,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              data.unreadCount >
                                      99
                                  ? '99+'
                                  : data
                                      .unreadCount
                                      .toString(),
                              style:
                                  AppText.label(
                                size:
                                    8,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    8,
              ),

              const Icon(
                LucideIcons
                    .chevronRight,
                size:
                    17,
                color:
                    AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesHeader
    extends StatelessWidget {
  const _MessagesHeader({
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
        16,
        14,
        18,
        14,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(
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
                width:
                    44,
                height:
                    44,
                child: Center(
                  child: Icon(
                    LucideIcons
                        .arrowLeft,
                    size:
                        20,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Messages',
                  style:
                      AppText.heading(
                    size:
                        19,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  'Search and manage conversations',
                  style:
                      AppText.body(
                    size:
                        10.5,
                    color:
                        AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          const PremiumIconBox(
            icon:
                LucideIcons
                    .messageCircle,
          ),
        ],
      ),
    );
  }
}

class _MessagesState
    extends StatelessWidget {
  const _MessagesState({
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
                height:
                    15,
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

String _formatConversationTime(
  Timestamp timestamp,
) {
  final date =
      timestamp.toDate();

  final now =
      DateTime.now();

  final sameDay =
      now.year ==
              date.year &&
          now.month ==
              date.month &&
          now.day ==
              date.day;

  if (sameDay) {
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

  return '${date.day}/${date.month}/${date.year}';
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
  final text =
      error.toString();

  if (text.contains(
    'permission-denied',
  )) {
    return 'Permission denied. Check Firestore rules.';
  }

  return text;
}