import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/report_service.dart';
import 'premium_ui.dart';

Future<bool> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String targetTitle,
  String? targetOwnerId,
}) async {
  final result =
      await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Colors.transparent,
    builder: (_) =>
        _ReportSheet(
      targetType:
          targetType,
      targetId:
          targetId,
      targetTitle:
          targetTitle,
      targetOwnerId:
          targetOwnerId,
    ),
  );

  return result == true;
}

class _ReportSheet
    extends StatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    this.targetOwnerId,
  });

  final String targetType;
  final String targetId;
  final String targetTitle;
  final String? targetOwnerId;

  @override
  State<_ReportSheet>
      createState() =>
          _ReportSheetState();
}

class _ReportSheetState
    extends State<_ReportSheet> {
  static const List<String>
      _types = [
    'Fraud / Scam',
    'Harassment',
    'Inappropriate content',
    'Spam',
    'Fake information',
    'Other',
  ];

  final ReportService _service =
      ReportService();

  final TextEditingController
      _reasonController =
      TextEditingController();

  String? _selectedType;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController
        .dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final type =
        _selectedType;

    final reason =
        _reasonController
            .text
            .trim();

    if (type == null ||
        type.isEmpty) {
      _showMessage(
        'Please choose a report type.',
      );
      return;
    }

    if (reason.length < 5) {
      _showMessage(
        'Please provide a little more detail.',
      );
      return;
    }

    FocusScope.of(context)
        .unfocus();

    setState(() {
      _submitting =
          true;
    });

    try {
      await _service.submitReport(
        targetType:
            widget.targetType,
        targetId:
            widget.targetId,
        targetOwnerId:
            widget.targetOwnerId,
        targetLabel:
            widget.targetTitle,
        type:
            type,
        reason:
            reason,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        true,
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
          _submitting =
              false;
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
          child:
              SingleChildScrollView(
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
                Row(
                  children: [
                    const PremiumIconBox(
                      icon:
                          LucideIcons
                              .messageSquareWarning,
                    ),
                    const SizedBox(
                      width:
                          12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report',
                            style:
                                AppText.heading(
                              size:
                                  21,
                            ),
                          ),
                          Text(
                            widget.targetTitle,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
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
                  ],
                ),
                const SizedBox(
                  height:
                      20,
                ),
                Text(
                  'Reason category',
                  style:
                      AppText.label(
                    size:
                        10,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                DropdownButtonFormField<String>(
                  initialValue:
                      _selectedType,
                  isExpanded:
                      true,
                  dropdownColor:
                      AppColors.surface,
                  style:
                      AppText.body(
                    size:
                        12.5,
                    color:
                        AppColors.ink,
                  ),
                  decoration:
                      InputDecoration(
                    hintText:
                        'Choose a reason',
                    hintStyle:
                        AppText.body(
                      size:
                          11.5,
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
                  ),
                  items:
                      _types
                          .map(
                            (type) =>
                                DropdownMenuItem<String>(
                              value:
                                  type,
                              child:
                                  Text(
                                type,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      _submitting
                          ? null
                          : (value) {
                              setState(
                                () {
                                  _selectedType =
                                      value;
                                },
                              );
                            },
                ),
                const SizedBox(
                  height:
                      16,
                ),
                Text(
                  'Details',
                  style:
                      AppText.label(
                    size:
                        10,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                TextField(
                  controller:
                      _reasonController,
                  maxLines:
                      4,
                  maxLength:
                      500,
                  enabled:
                      !_submitting,
                  style:
                      AppText.body(
                    size:
                        13,
                    color:
                        AppColors.ink,
                  ),
                  cursorColor:
                      AppColors.ink,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Briefly explain what happened.',
                    hintStyle:
                        AppText.body(
                      size:
                          11.5,
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
                ),
                const SizedBox(
                  height:
                      14,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  height:
                      50,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _submitting
                            ? null
                            : _submit,
                    icon:
                        _submitting
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                LucideIcons
                                    .send,
                                size:
                                    17,
                              ),
                    label:
                        Text(
                      _submitting
                          ? 'Submitting...'
                          : 'Submit report',
                    ),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
