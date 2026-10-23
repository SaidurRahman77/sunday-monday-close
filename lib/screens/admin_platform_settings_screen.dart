import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/platform_settings_service.dart';
import '../widgets/premium_ui.dart';

class AdminPlatformSettingsScreen
    extends StatefulWidget {
  const AdminPlatformSettingsScreen({
    super.key,
  });

  @override
  State<AdminPlatformSettingsScreen>
      createState() =>
          _AdminPlatformSettingsScreenState();
}

class _AdminPlatformSettingsScreenState
    extends State<
        AdminPlatformSettingsScreen> {
  final PlatformSettingsService
      _service =
      PlatformSettingsService();

  final TextEditingController
      _messageController =
      TextEditingController();

  bool _maintenanceMode =
      false;
  bool _allowRegistrations =
      true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController
        .dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings =
          await _service
              .getSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _maintenanceMode =
            settings[
                    'maintenanceMode'] ==
                true;

        _allowRegistrations =
            settings[
                    'allowNewRegistrations'] !=
                false;

        _messageController
                .text =
            settings[
                    'maintenanceMessage']
                ?.toString() ??
            '';

        _loading =
            false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading =
            false;
      });

      _showMessage(
        e.toString(),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving =
          true;
    });

    try {
      await _service.saveSettings(
        maintenanceMode:
            _maintenanceMode,
        allowNewRegistrations:
            _allowRegistrations,
        maintenanceMessage:
            _messageController
                .text,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Platform settings saved.',
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
          _saving =
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
              child:
                  _loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                AppColors
                                    .ink,
                          ),
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            22,
                            20,
                            40,
                          ),
                          children: [
                            const PremiumSectionHeader(
                              title:
                                  'Access controls',
                            ),
                            const SizedBox(
                              height:
                                  12,
                            ),
                            _SettingTile(
                              icon:
                                  LucideIcons
                                      .construction,
                              title:
                                  'Maintenance mode',
                              subtitle:
                                  'Block normal user logins while maintenance is active. Admin access remains available.',
                              value:
                                  _maintenanceMode,
                              onChanged:
                                  (value) {
                                setState(
                                  () {
                                    _maintenanceMode =
                                        value;
                                  },
                                );
                              },
                            ),
                            const SizedBox(
                              height:
                                  10,
                            ),
                            _SettingTile(
                              icon:
                                  LucideIcons
                                      .userPlus,
                              title:
                                  'Allow new registrations',
                              subtitle:
                                  'Control whether the Sign Up entry is available from the login screen.',
                              value:
                                  _allowRegistrations,
                              onChanged:
                                  (value) {
                                setState(
                                  () {
                                    _allowRegistrations =
                                        value;
                                  },
                                );
                              },
                            ),
                            const SizedBox(
                              height:
                                  26,
                            ),
                            const PremiumSectionHeader(
                              title:
                                  'Maintenance message',
                            ),
                            const SizedBox(
                              height:
                                  12,
                            ),
                            TextField(
                              controller:
                                  _messageController,
                              maxLines:
                                  4,
                              maxLength:
                                  300,
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
                                    'Message shown when maintenance mode blocks a login.',
                                hintStyle:
                                    AppText.body(
                                  size:
                                      11.5,
                                  color:
                                      AppColors.muted,
                                ),
                                labelStyle:
                                    AppText.body(
                                  size:
                                      11,
                                  color:
                                      AppColors.inkSoft,
                                ),
                                filled:
                                    true,
                                fillColor:
                                    AppColors
                                        .surface,
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        AppColors
                                            .line,
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
                                        AppColors
                                            .line,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  22,
                            ),
                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  ElevatedButton.icon(
                                onPressed:
                                    _saving
                                        ? null
                                        : _save,
                                icon:
                                    _saving
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
                                                .save,
                                            size:
                                                17,
                                          ),
                                label:
                                    Text(
                                  _saving
                                      ? 'Saving...'
                                      : 'Save settings',
                                ),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  14,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.all(
                                15,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    AppColors
                                        .surface,
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      AppColors
                                          .line,
                                ),
                              ),
                              child:
                                  Text(
                                'These are app-level controls stored in Firestore. Maintenance mode blocks new normal user logins; it does not forcibly sign out users who are already inside the app.',
                                style:
                                    AppText.body(
                                  size:
                                      10.5,
                                  color:
                                      AppColors
                                          .muted,
                                ),
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
            width:
                4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'PLATFORM SETTINGS',
                  style:
                      AppText.label(
                    size:
                        8,
                    color:
                        AppColors.gold,
                  ),
                ),
                const SizedBox(
                  height:
                      2,
                ),
                Text(
                  'System controls',
                  style:
                      AppText.heading(
                    size:
                        18,
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

class _SettingTile
    extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        15,
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
          PremiumIconBox(
            icon:
                icon,
          ),
          const SizedBox(
            width:
                12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      AppText.heading(
                    size:
                        14,
                  ),
                ),
                const SizedBox(
                  height:
                      3,
                ),
                Text(
                  subtitle,
                  style:
                      AppText.body(
                    size:
                        9.5,
                    color:
                        AppColors
                            .muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width:
                10,
          ),
          Switch.adaptive(
            value:
                value,
            onChanged:
                onChanged,
          ),
        ],
      ),
    );
  }
}
