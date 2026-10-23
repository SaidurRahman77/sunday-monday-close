import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/category_service.dart';
import '../widgets/premium_ui.dart';

class AdminCategoryManagementScreen
    extends StatefulWidget {
  const AdminCategoryManagementScreen({
    super.key,
  });

  @override
  State<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> {
  final CategoryService _categoryService =
      CategoryService();

  bool _busy = false;

  Future<void> _showCategoryEditor({
    String? categoryId,
    String initialName = '',
  }) async {
    final isEditing =
        categoryId != null;

    final result =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          _CategoryEditorSheet(
        initialName:
            initialName,
        isEditing:
            isEditing,
      ),
    );

    final name =
        result?.trim() ?? '';

    if (name.isEmpty ||
        !mounted) {
      return;
    }

    await _runAction(
      () async {
        if (isEditing) {
          await _categoryService
              .updateCategory(
            categoryId:
                categoryId,
            name: name,
          );
        } else {
          await _categoryService
              .addCategory(
            name: name,
          );
        }
      },
      successMessage:
          isEditing
              ? 'Category updated.'
              : 'Category added.',
    );
  }

  Future<void> _toggleCategory({
    required String categoryId,
    required String name,
    required bool active,
  }) async {
    await _runAction(
      () => _categoryService
          .setCategoryActive(
        categoryId:
            categoryId,
        active:
            !active,
        name: name,
      ),
      successMessage:
          active
              ? 'Category disabled.'
              : 'Category enabled.',
    );
  }

  Future<void> _deleteCategory({
    required String categoryId,
    required String name,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppColors.surface,
          surfaceTintColor:
              Colors.transparent,
          title: Text(
            'Delete category?',
            style:
                AppText.heading(
              size: 19,
            ),
          ),
          content: Text(
            '“$name” will disappear from future category selections. Existing jobs and worker profiles keep their stored category text.',
            style:
                AppText.body(
              size: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await _runAction(
      () => _categoryService
          .deleteCategory(
        categoryId:
            categoryId,
        name: name,
      ),
      successMessage:
          'Category deleted.',
    );
  }

  Future<void> _seedDefaults() async {
    await _runAction(
      _categoryService
          .seedDefaultCategories,
      successMessage:
          'Default categories added.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
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
        successMessage,
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
              busy: _busy,
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
              onAdd: () {
                _showCategoryEditor();
              },
            ),
            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _categoryService
                        .watchAllCategories(),
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
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child: Text(
                          snapshot.error
                              .toString(),
                          textAlign:
                              TextAlign.center,
                          style:
                              AppText.body(),
                        ),
                      ),
                    );
                  }

                  final categories =
                      snapshot.data ??
                          [];

                  if (categories
                      .isEmpty) {
                    return _EmptyState(
                      busy:
                          _busy,
                      onSeed:
                          _seedDefaults,
                      onAdd: () {
                        _showCategoryEditor();
                      },
                    );
                  }

                  final activeCount =
                      categories
                          .where(
                            (item) =>
                                item['active'] !=
                                false,
                          )
                          .length;

                  return ListView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      22,
                      20,
                      40,
                    ),
                    children: [
                      _SummaryCard(
                        total:
                            categories.length,
                        active:
                            activeCount,
                        disabled:
                            categories.length -
                                activeCount,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Categories',
                              style:
                                  AppText.heading(
                                size: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${categories.length} total',
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
                      ...categories.map(
                        (category) {
                          final id =
                              category[
                                      'categoryId']
                                  ?.toString() ??
                                  '';

                          final name =
                              category[
                                      'name']
                                  ?.toString()
                                  .trim() ??
                                  'Untitled';

                          final active =
                              category[
                                      'active'] !=
                                  false;

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                                _CategoryTile(
                              name:
                                  name,
                              active:
                                  active,
                              busy:
                                  _busy,
                              onEdit: () {
                                _showCategoryEditor(
                                  categoryId:
                                      id,
                                  initialName:
                                      name,
                                );
                              },
                              onToggle: () {
                                _toggleCategory(
                                  categoryId:
                                      id,
                                  name:
                                      name,
                                  active:
                                      active,
                                );
                              },
                              onDelete: () {
                                _deleteCategory(
                                  categoryId:
                                      id,
                                  name:
                                      name,
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

class _Header
    extends StatelessWidget {
  const _Header({
    required this.busy,
    required this.onBack,
    required this.onAdd,
  });

  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onAdd;

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
                busy
                    ? null
                    : onBack,
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
                  'CATEGORY MANAGEMENT',
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
                  'Work categories',
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
          IconButton(
            tooltip:
                'Add category',
            onPressed:
                busy
                    ? null
                    : onAdd,
            icon:
                const Icon(
              LucideIcons.plus,
              color:
                  AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.active,
    required this.disabled,
  });

  final int total;
  final int active;
  final int disabled;

  @override
  Widget build(
    BuildContext context,
  ) {
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
      child: Row(
        children: [
          Expanded(
            child:
                _Metric(
              label:
                  'TOTAL',
              value:
                  total,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color:
                AppColors.line,
          ),
          Expanded(
            child:
                _Metric(
              label:
                  'ACTIVE',
              value:
                  active,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color:
                AppColors.line,
          ),
          Expanded(
            child:
                _Metric(
              label:
                  'DISABLED',
              value:
                  disabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric
    extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          '$value',
          style:
              AppText.heading(
            size: 20,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          label,
          style:
              AppText.label(
            size: 7.5,
            color:
                AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile
    extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.active,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final String name;
  final bool active;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        15,
        14,
        8,
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
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
          Container(
            width: 40,
            height: 40,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  active
                      ? AppColors.goldSoft
                      : AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              active
                  ? LucideIcons
                      .circleCheck
                  : LucideIcons
                      .circlePause,
              size: 17,
              color:
                  active
                      ? AppColors.ink
                      : AppColors.muted,
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
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  active
                      ? 'Visible to clients and workers'
                      : 'Hidden from new selections',
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
          PopupMenuButton<String>(
            enabled:
                !busy,
            tooltip:
                'Category actions',
            onSelected:
                (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'toggle':
                  onToggle();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder:
                (context) => [
              const PopupMenuItem(
                value:
                    'edit',
                child:
                    Text(
                  'Edit',
                ),
              ),
              PopupMenuItem(
                value:
                    'toggle',
                child:
                    Text(
                  active
                      ? 'Disable'
                      : 'Enable',
                ),
              ),
              const PopupMenuItem(
                value:
                    'delete',
                child:
                    Text(
                  'Delete',
                ),
              ),
            ],
            icon:
                const Icon(
              LucideIcons
                  .ellipsisVertical,
              color:
                  AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}


class _CategoryEditorSheet
    extends StatefulWidget {
  const _CategoryEditorSheet({
    required this.initialName,
    required this.isEditing,
  });

  final String initialName;
  final bool isEditing;

  @override
  State<_CategoryEditorSheet>
      createState() =>
          _CategoryEditorSheetState();
}

class _CategoryEditorSheetState
    extends State<_CategoryEditorSheet> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text:
          widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value =
        _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    Navigator.of(context).pop(
      value,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),
      child: Container(
        margin:
            const EdgeInsets.all(
          12,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          22,
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
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width:
                      38,
                  height:
                      4,
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
                height:
                    20,
              ),
              Text(
                widget.isEditing
                    ? 'Edit category'
                    : 'Add category',
                style:
                    AppText.heading(
                  size:
                      21,
                ),
              ),
              const SizedBox(
                height:
                    6,
              ),
              Text(
                widget.isEditing
                    ? 'Update the category name used across the platform.'
                    : 'Create a new work category for clients and workers.',
                style:
                    AppText.body(
                  size:
                      11.5,
                  color:
                      AppColors.muted,
                ),
              ),
              const SizedBox(
                height:
                    18,
              ),
              TextField(
                controller:
                    _controller,
                autofocus:
                    true,
                textCapitalization:
                    TextCapitalization.words,
                style:
                    AppText.body(
                  size:
                      14,
                  color:
                      AppColors.ink,
                ),
                cursorColor:
                    AppColors.ink,
                decoration:
                    InputDecoration(
                  labelText:
                      'Category name',
                  labelStyle:
                      AppText.body(
                    size:
                        11,
                    color:
                        AppColors.inkSoft,
                  ),
                  floatingLabelStyle:
                      AppText.body(
                    size:
                        11,
                    color:
                        AppColors.ink,
                  ),
                  hintText:
                      'e.g. Gardening',
                  hintStyle:
                      AppText.body(
                    size:
                        12,
                    color:
                        AppColors.muted,
                  ),
                  filled:
                      true,
                  fillColor:
                      AppColors.background,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
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
                      16,
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
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.ink,
                      width:
                          1.5,
                    ),
                  ),
                ),
                onSubmitted:
                    (_) =>
                        _submit(),
              ),
              const SizedBox(
                height:
                    16,
              ),
              SizedBox(
                width:
                    double.infinity,
                height:
                    50,
                child:
                    ElevatedButton(
                  onPressed:
                      _submit,
                  style:
                      ElevatedButton.styleFrom(
                    elevation:
                        0,
                    backgroundColor:
                        AppColors.dark,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child:
                      Text(
                    widget.isEditing
                        ? 'Save changes'
                        : 'Add category',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState({
    required this.busy,
    required this.onSeed,
    required this.onAdd,
  });

  final bool busy;
  final VoidCallback onSeed;
  final VoidCallback onAdd;

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
              Container(
                width: 54,
                height: 54,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons
                      .layoutGrid,
                  color:
                      AppColors.ink,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                'No categories yet',
                style:
                    AppText.heading(
                  size: 18,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Add categories manually or import the current default set.',
                textAlign:
                    TextAlign.center,
                style:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.muted,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed:
                      busy
                          ? null
                          : onSeed,
                  child:
                      const Text(
                    'Add default categories',
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    busy
                        ? null
                        : onAdd,
                child:
                    const Text(
                  'Add one manually',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
