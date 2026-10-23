import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/admin_user_service.dart';
import '../widgets/premium_ui.dart';
import '../widgets/safe_text_input_dialog.dart';

class AdminUserManagementScreen
    extends StatefulWidget {
  const AdminUserManagementScreen({
    super.key,
  });

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends State<AdminUserManagementScreen> {
  final AdminUserService _userService =
      AdminUserService();

  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';
  String _statusFilter = 'all';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>>
      _filteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    return users.where(
      (user) {
        final name =
            user['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final email =
            user['email']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final phone =
            user['phone']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final location =
            user['location']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final query =
            _query
                .trim()
                .toLowerCase();

        final status =
            _statusOf(user);

        final matchesQuery =
            query.isEmpty ||
                name.contains(query) ||
                email.contains(query) ||
                phone.contains(query) ||
                location.contains(query);

        final matchesStatus =
            _statusFilter == 'all' ||
                status == _statusFilter;

        return matchesQuery &&
            matchesStatus;
      },
    ).toList();
  }

  String _statusOf(
    Map<String, dynamic> user,
  ) {
    final value =
        user['accountStatus']
            ?.toString()
            .trim()
            .toLowerCase();

    if (value == null ||
        value.isEmpty) {
      return 'active';
    }

    return value;
  }

  Future<void> _showUserDetails(
    Map<String, dynamic> user,
  ) async {
    final userId =
        user['userId']
                ?.toString() ??
            '';

    final name =
        user['name']
                ?.toString()
                .trim() ??
            'Unnamed user';

    final email =
        user['email']
                ?.toString()
                .trim() ??
            '';

    final phone =
        user['phone']
                ?.toString()
                .trim() ??
            '';

    final location =
        user['location']
                ?.toString()
                .trim() ??
            '';

    final workerProfile =
        user['workerProfile'];

    final worker =
        workerProfile is Map
            ? Map<String, dynamic>.from(
                workerProfile,
              )
            : <String, dynamic>{};

    final rating =
        (worker['rating'] as num?)
                ?.toDouble() ??
            0;

    final completedJobs =
        (worker['completedJobs'] as num?)
                ?.toInt() ??
            0;

    final status =
        _statusOf(user);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        sheetContext,
      ) {
        return Container(
          margin:
              const EdgeInsets.all(
            12,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            24,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              28,
            ),
          ),
          child: SafeArea(
            top: false,
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.line,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.goldSoft,
                        child: Text(
                          _initials(
                            name,
                          ),
                          style:
                              AppText.heading(
                            size: 17,
                          ),
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
                            Text(
                              name,
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              email.isEmpty
                                  ? 'No email stored'
                                  : email,
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
                      _StatusBadge(
                        status:
                            status,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _DetailRow(
                    label: 'User ID',
                    value: userId,
                  ),
                  _DetailRow(
                    label: 'Phone',
                    value: phone.isEmpty
                        ? 'Not set'
                        : phone,
                  ),
                  _DetailRow(
                    label: 'Location',
                    value: location.isEmpty
                        ? 'Not set'
                        : location,
                  ),
                  _DetailRow(
                    label: 'Client profile',
                    value:
                        user['clientProfileComplete'] ==
                                true
                            ? 'Complete'
                            : 'Not complete',
                  ),
                  _DetailRow(
                    label: 'Worker profile',
                    value:
                        user['workerProfileComplete'] ==
                                true
                            ? 'Complete'
                            : 'Not complete',
                  ),
                  _DetailRow(
                    label: 'Worker rating',
                    value:
                        rating.toStringAsFixed(
                      1,
                    ),
                  ),
                  _DetailRow(
                    label: 'Completed jobs',
                    value:
                        '$completedJobs',
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  _ModerationActions(
                    status:
                        status,
                    busy: _busy,
                    onSuspend: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _suspendUser(
                        userId:
                            userId,
                        userName:
                            name,
                      );
                    },
                    onUnsuspend: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _runAction(
                        () => _userService
                            .unsuspendUser(
                          userId:
                              userId,
                          userName:
                              name,
                        ),
                        success:
                            'User account reactivated.',
                      );
                    },
                    onRemove: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _removeUser(
                        userId:
                            userId,
                        userName:
                            name,
                      );
                    },
                    onRestore: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _runAction(
                        () => _userService
                            .restoreUser(
                          userId:
                              userId,
                          userName:
                              name,
                        ),
                        success:
                            'User account restored.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _suspendUser({
    required String userId,
    required String userName,
  }) async {
    final reason =
        await _reasonDialog(
      title:
          'Suspend user?',
      description:
          'The user will be blocked from future logins until an admin reactivates the account.',
      actionLabel:
          'Suspend',
    );

    if (reason == null ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _userService
          .suspendUser(
        userId: userId,
        userName:
            userName,
        reason:
            reason,
      ),
      success:
          'User account suspended.',
    );
  }

  Future<void> _removeUser({
    required String userId,
    required String userName,
  }) async {
    final reason =
        await _reasonDialog(
      title:
          'Remove account?',
      description:
          'This performs a safe soft-delete. Existing jobs, reviews and history remain linked, but the user will not be able to log in.',
      actionLabel:
          'Remove account',
      destructive: true,
    );

    if (reason == null ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _userService
          .removeUser(
        userId: userId,
        userName:
            userName,
        reason:
            reason,
      ),
      success:
          'User account removed.',
    );
  }

  Future<String?> _reasonDialog({
    required String title,
    required String description,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showSafeTextInputDialog(
      context,
      title: title,
      description: description,
      fieldLabel: 'Reason (optional)',
      actionLabel: actionLabel,
      destructive: destructive,
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(
        success,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
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

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
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
              onBack: () =>
                  Navigator.pop(
                context,
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _userService
                        .watchUsers(),
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
                        strokeWidth: 2,
                        color:
                            AppColors.ink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child:
                          Text(
                        snapshot.error
                            .toString(),
                      ),
                    );
                  }

                  final users =
                      snapshot.data ??
                          [];

                  final filtered =
                      _filteredUsers(
                    users,
                  );

                  return ListView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      20,
                      20,
                      40,
                    ),
                    children: [
                      _SearchBox(
                        controller:
                            _searchController,
                        onChanged:
                            (value) {
                          setState(() {
                            _query =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _StatusFilters(
                        selected:
                            _statusFilter,
                        onChanged:
                            (value) {
                          setState(() {
                            _statusFilter =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Users',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${filtered.length} found',
                            style:
                                AppText.body(
                              size: 10,
                              color:
                                  AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (filtered.isEmpty)
                        _EmptyState()
                      else
                        ...filtered.map(
                          (user) =>
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom:
                                  10,
                            ),
                            child:
                                _UserTile(
                              user:
                                  user,
                              status:
                                  _statusOf(
                                user,
                              ),
                              onTap:
                                  () {
                                _showUserDetails(
                                  user,
                                );
                              },
                            ),
                          ),
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

class _Header
    extends StatelessWidget {
  const _Header({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        0,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          25,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                onBack,
            icon:
                const Icon(
              LucideIcons
                  .arrowLeft,
              color:
                  Colors.white,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'USER MANAGEMENT',
                  style:
                      AppText.label(
                    size: 8,
                    color:
                        AppColors.gold,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Platform accounts',
                  style:
                      AppText.heading(
                    size: 18,
                    color:
                        Colors.white,
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

class _SearchBox
    extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController
      controller;
  final ValueChanged<String>
      onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      style:
          AppText.body(
        size: 13,
        color:
            AppColors.ink,
      ),
      cursorColor:
          AppColors.ink,
      onChanged:
          onChanged,
      decoration:
          InputDecoration(
        hintText:
            'Search by name, email, phone or location',
        hintStyle:
            AppText.body(
          size: 11.5,
          color:
              AppColors.muted,
        ),
        prefixIcon:
            const Icon(
          LucideIcons.search,
          size: 18,
        ),
        filled: true,
        fillColor:
            AppColors.surface,
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
      ),
    );
  }
}

class _StatusFilters
    extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String>
      onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    final items = [
      ('all', 'All'),
      ('active', 'Active'),
      ('suspended', 'Suspended'),
      ('deleted', 'Removed'),
    ];

    return SizedBox(
      height: 38,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            items.length,
        separatorBuilder:
            (
          context,
          index,
        ) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final item =
              items[index];

          final isSelected =
              selected ==
                  item.$1;

          return ChoiceChip(
            label:
                Text(
              item.$2,
            ),
            selected:
                isSelected,
            onSelected: (_) =>
                onChanged(
              item.$1,
            ),
          );
        },
      ),
    );
  }
}

class _UserTile
    extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.status,
    required this.onTap,
  });

  final Map<String, dynamic>
      user;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final name =
        user['name']
                ?.toString()
                .trim() ??
            'Unnamed user';

    final email =
        user['email']
                ?.toString()
                .trim() ??
            '';

    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  AppColors.line,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppColors.goldSoft,
                child:
                    Text(
                  name.isEmpty
                      ? 'U'
                      : name[0]
                          .toUpperCase(),
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.heading(
                        size: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      email.isEmpty
                          ? 'No email stored'
                          : email,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppText.body(
                        size: 9.5,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              _StatusBadge(
                status:
                    status,
              ),
              const SizedBox(
                width: 4,
              ),
              const Icon(
                LucideIcons
                    .chevronRight,
                size: 17,
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

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(
    BuildContext context,
  ) {
    final label =
        switch (status) {
      'suspended' =>
        'SUSPENDED',
      'deleted' =>
        'REMOVED',
      _ => 'ACTIVE',
    };

    final background =
        status == 'active'
            ? AppColors.goldSoft
            : AppColors.background;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Text(
        label,
        style:
            AppText.label(
          size: 7,
          color:
              status ==
                      'active'
                  ? AppColors.ink
                  : AppColors.muted,
        ),
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
                  AppText.body(
                size: 10,
                color:
                    AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  AppText.body(
                size: 10.5,
                color:
                    AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationActions
    extends StatelessWidget {
  const _ModerationActions({
    required this.status,
    required this.busy,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onRemove,
    required this.onRestore,
  });

  final String status;
  final bool busy;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onRemove;
  final VoidCallback onRestore;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (status == 'deleted') {
      return SizedBox(
        width:
            double.infinity,
        child:
            ElevatedButton.icon(
          onPressed:
              busy
                  ? null
                  : onRestore,
          icon:
              const Icon(
            LucideIcons
                .rotateCcw,
            size: 17,
          ),
          label:
              const Text(
            'Restore account',
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width:
              double.infinity,
          child:
              ElevatedButton.icon(
            onPressed:
                busy
                    ? null
                    : status ==
                            'suspended'
                        ? onUnsuspend
                        : onSuspend,
            icon:
                Icon(
              status ==
                      'suspended'
                  ? LucideIcons
                      .circleCheck
                  : LucideIcons
                      .ban,
              size: 17,
            ),
            label:
                Text(
              status ==
                      'suspended'
                  ? 'Reactivate account'
                  : 'Suspend account',
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width:
              double.infinity,
          child:
              OutlinedButton.icon(
            onPressed:
                busy
                    ? null
                    : onRemove,
            icon:
                const Icon(
              LucideIcons.trash2,
              size: 17,
            ),
            label:
                const Text(
              'Remove account',
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
          22,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons
                .usersRound,
            color:
                AppColors.muted,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No users found',
            style:
                AppText.heading(
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
