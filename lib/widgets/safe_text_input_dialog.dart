import 'package:flutter/material.dart';

import 'premium_ui.dart';

Future<String?> showSafeTextInputDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String fieldLabel,
  required String actionLabel,
  String initialValue = '',
  bool destructive = false,
}) {
  return showDialog<String?>(
    context: context,
    builder: (_) =>
        _SafeTextInputDialog(
      title: title,
      description: description,
      fieldLabel: fieldLabel,
      actionLabel: actionLabel,
      initialValue: initialValue,
      destructive: destructive,
    ),
  );
}

class _SafeTextInputDialog
    extends StatefulWidget {
  const _SafeTextInputDialog({
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.actionLabel,
    required this.initialValue,
    required this.destructive,
  });

  final String title;
  final String description;
  final String fieldLabel;
  final String actionLabel;
  final String initialValue;
  final bool destructive;

  @override
  State<_SafeTextInputDialog>
      createState() =>
          _SafeTextInputDialogState();
}

class _SafeTextInputDialogState
    extends State<
        _SafeTextInputDialog> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _controller.text.trim(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor:
          AppColors.surface,
      surfaceTintColor:
          Colors.transparent,
      title: Text(
        widget.title,
        style: AppText.heading(
          size: 19,
          color: AppColors.ink,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (widget.description
                .trim()
                .isNotEmpty) ...[
              Text(
                widget.description,
                style: AppText.body(
                  size: 11.5,
                  color:
                      AppColors.inkSoft,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
            ],
            TextField(
              controller:
                  _controller,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              style: AppText.body(
                size: 13.5,
                color:
                    AppColors.ink,
              ),
              cursorColor:
                  AppColors.ink,
              decoration:
                  InputDecoration(
                labelText:
                    widget.fieldLabel,
                labelStyle:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.inkSoft,
                ),
                floatingLabelStyle:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.ink,
                ),
                hintStyle:
                    AppText.body(
                  size: 11.5,
                  color:
                      AppColors.muted,
                ),
                filled: true,
                fillColor:
                    AppColors.background,
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
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
                    14,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        AppColors.ink,
                    width: 1.4,
                  ),
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onSubmitted:
                  (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop(),
          child: Text(
            'Cancel',
            style: AppText.label(
              size: 11,
              color:
                  AppColors.inkSoft,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                widget.destructive
                    ? Colors.red.shade700
                    : AppColors.dark,
            foregroundColor:
                Colors.white,
          ),
          child: Text(
            widget.actionLabel,
          ),
        ),
      ],
    );
  }
}
