import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/profile_service.dart';
import '../widgets/premium_ui.dart';
import 'account_settings_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({
    super.key,
  });

  @override
  State<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState
    extends State<ClientProfileScreen> {
  final ProfileService _profileService =
      ProfileService();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _bioController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  String _email = '';
  String _photoUrl = '';

  String? _nameError;
  String? _phoneError;
  String? _locationError;
  String? _bioError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // =====================================================
  // LOAD PROFILE
  // =====================================================

  Future<void> _loadProfile() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    _email =
        user.email ?? '';

    try {
      final profile =
          await _profileService.getProfile();

      if (profile != null) {
        _nameController.text =
            profile['name']
                    ?.toString() ??
                user.displayName ??
                '';

        _phoneController.text =
            profile['phone']
                    ?.toString() ??
                '';

        _locationController.text =
            profile['location']
                    ?.toString() ??
                '';

        _bioController.text =
            profile['bio']
                    ?.toString() ??
                '';

        _photoUrl =
            profile['photoUrl']
                    ?.toString()
                    .trim() ??
                user.photoURL?.trim() ??
                '';
      } else {
        _nameController.text =
            user.displayName ?? '';

        _photoUrl =
            user.photoURL?.trim() ??
                '';
      }
    } catch (e) {
      debugPrint(
        'CLIENT PROFILE LOAD ERROR: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to load profile. Please try again.',
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // VALIDATION
  // =====================================================

  String? _validateName(
    String value,
  ) {
    final name =
        value.trim();

    if (name.isEmpty) {
      return 'Please enter your name.';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters.';
    }

    if (name.length > 60) {
      return 'Name cannot exceed 60 characters.';
    }

    return null;
  }

  String? _validatePhone(
    String value,
  ) {
    final phone =
        value.trim();

    if (phone.isEmpty) {
      return 'Please enter your phone number.';
    }

    final digits =
        phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.length < 7) {
      return 'Phone number is too short.';
    }

    if (digits.length > 15) {
      return 'Phone number is too long.';
    }

    return null;
  }

  String? _validateLocation(
    String value,
  ) {
    final location =
        value.trim();

    if (location.isEmpty) {
      return 'Please enter your location.';
    }

    if (location.length < 2) {
      return 'Please enter a valid location.';
    }

    if (location.length > 100) {
      return 'Location cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateBio(
    String value,
  ) {
    if (value.trim().length > 300) {
      return 'Bio cannot exceed 300 characters.';
    }

    return null;
  }

  bool _validateProfile() {
    final nameError =
        _validateName(
      _nameController.text,
    );

    final phoneError =
        _validatePhone(
      _phoneController.text,
    );

    final locationError =
        _validateLocation(
      _locationController.text,
    );

    final bioError =
        _validateBio(
      _bioController.text,
    );

    setState(() {
      _nameError =
          nameError;

      _phoneError =
          phoneError;

      _locationError =
          locationError;

      _bioError =
          bioError;
    });

    return nameError == null &&
        phoneError == null &&
        locationError == null &&
        bioError == null;
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    if (!_validateProfile()) {
      _showMessage(
        'Please correct the highlighted fields.',
      );
      return;
    }

    final oldOffset =
        _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;

    FocusManager.instance.primaryFocus
        ?.unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.saveProfile(
        name:
            _nameController.text.trim(),
        phone:
            _phoneController.text.trim(),
        location:
            _locationController.text.trim(),
        bio:
            _bioController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nameError = null;
        _phoneError = null;
        _locationError = null;
        _bioError = null;
      });

      _restoreScroll(
        oldOffset,
      );

      _showMessage(
        'Profile updated successfully.',
      );
    } catch (e) {
      debugPrint(
        'CLIENT PROFILE SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _restoreScroll(
        oldOffset,
      );

      _showMessage(
        _friendlyProfileError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        _restoreScroll(
          oldOffset,
        );
      }
    }
  }

  // =====================================================
  // PROFILE PHOTO
  // =====================================================

  Future<void> _showPhotoOptions() async {
    if (_isUploadingPhoto) {
      return;
    }

    final action =
        await showModalBottomSheet<
            _PhotoAction>(
      context: context,
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
            18,
            14,
            18,
            20,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              26,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.line,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile photo',
                        style:
                            AppText.heading(
                          size: 18,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      icon:
                          const Icon(
                        LucideIcons.x,
                        size: 19,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                _PhotoOptionTile(
                  icon:
                      LucideIcons.image,
                  title:
                      'Choose from gallery',
                  subtitle:
                      'Select a photo from your device',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _PhotoAction.gallery,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _PhotoOptionTile(
                  icon:
                      LucideIcons.camera,
                  title:
                      'Take a photo',
                  subtitle:
                      'Use your device camera',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _PhotoAction.camera,
                    );
                  },
                ),

                if (_photoUrl
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  _PhotoOptionTile(
                    icon:
                        LucideIcons.trash2,
                    title:
                        'Remove photo',
                    subtitle:
                        'Show your initials instead',
                    destructive:
                        true,
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        _PhotoAction.remove,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    switch (action) {
      case _PhotoAction.gallery:
        await _pickAndUploadPhoto(
          ImageSource.gallery,
        );
        break;

      case _PhotoAction.camera:
        await _pickAndUploadPhoto(
          ImageSource.camera,
        );
        break;

      case _PhotoAction.remove:
        await _removeProfilePhoto();
        break;
    }
  }

  Future<void> _pickAndUploadPhoto(
    ImageSource source,
  ) async {
    if (_isUploadingPhoto) {
      return;
    }

    try {
      final picker =
          ImagePicker();

      final image =
          await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      final bytes =
          await image.readAsBytes();

      if (bytes.length >
          5 * 1024 * 1024) {
        _showMessage(
          'Profile photo must be smaller than 5 MB.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingPhoto = true;
      });

      final photoUrl =
          await _profileService
              .uploadProfilePhoto(
        bytes: bytes,
        extension:
            _getImageExtension(
          image.name,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _photoUrl =
            photoUrl;
      });

      _showMessage(
        'Profile photo updated.',
      );
    } catch (e) {
      debugPrint(
        'CLIENT PHOTO UPLOAD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyPhotoError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void>
      _removeProfilePhoto() async {
    if (_isUploadingPhoto ||
        _photoUrl.isEmpty) {
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
          surfaceTintColor:
              Colors.transparent,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
          title: Text(
            'Remove profile photo?',
            style: AppText.heading(
              size: 19,
            ),
          ),
          content: Text(
            'Your initials will be shown instead.',
            style: AppText.body(
              size: 12.5,
              color:
                  AppColors.muted,
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
                  color:
                      AppColors
                          .inkSoft,
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
                elevation: 0,
                backgroundColor:
                    AppColors.ink,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Remove',
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

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      await _profileService
          .removeProfilePhoto();

      if (!mounted) {
        return;
      }

      setState(() {
        _photoUrl = '';
      });

      _showMessage(
        'Profile photo removed.',
      );
    } catch (e) {
      debugPrint(
        'CLIENT PHOTO REMOVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyPhotoError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  String _getImageExtension(
    String fileName,
  ) {
    final parts =
        fileName
            .toLowerCase()
            .split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension =
        parts.last;

    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp') {
      return extension;
    }

    return 'jpg';
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _restoreScroll(
    double offset,
  ) {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted ||
            !_scrollController
                .hasClients) {
          return;
        }

        final position =
            _scrollController.position;

        final safeOffset =
            offset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );

        _scrollController.jumpTo(
          safeOffset.toDouble(),
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AccountSettingsScreen(),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
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

  String _getInitials() {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final parts =
        name
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

  // =====================================================
  // BUILD
  // =====================================================

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
            _buildHeader(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            AppColors.ink,
                      ),
                    )
                  : SingleChildScrollView(
                      controller:
                          _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        24,
                        20,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          _buildProfileHero(),

                          const SizedBox(
                            height: 28,
                          ),

                          Text(
                            'Personal information',
                            style:
                                AppText.heading(
                              size: 20,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Keep your details accurate so workers know who they are working with.',
                            style:
                                AppText.body(
                              size: 12.5,
                              color:
                                  AppColors
                                      .muted,
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          const _ProfileLabel(
                            label:
                                'FULL NAME',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ProfileTextField(
                            controller:
                                _nameController,
                            hint:
                                'Enter your full name',
                            icon:
                                LucideIcons.user,
                            errorText:
                                _nameError,
                            maxLength: 60,
                            onChanged: (
                              value,
                            ) {
                              setState(() {
                                if (_nameError !=
                                    null) {
                                  _nameError =
                                      _validateName(
                                    value,
                                  );
                                }
                              });
                            },
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const _ProfileLabel(
                            label:
                                'EMAIL ADDRESS',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ReadOnlyField(
                            value:
                                _email.isEmpty
                                    ? 'No email'
                                    : _email,
                            icon:
                                LucideIcons.mail,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const _ProfileLabel(
                            label:
                                'PHONE NUMBER',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ProfileTextField(
                            controller:
                                _phoneController,
                            hint:
                                'e.g. 017XXXXXXXX',
                            icon:
                                LucideIcons.phone,
                            keyboardType:
                                TextInputType
                                    .phone,
                            errorText:
                                _phoneError,
                            maxLength: 20,
                            onChanged: (
                              value,
                            ) {
                              if (_phoneError !=
                                  null) {
                                setState(() {
                                  _phoneError =
                                      _validatePhone(
                                    value,
                                  );
                                });
                              }
                            },
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const _ProfileLabel(
                            label:
                                'LOCATION / AREA',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ProfileTextField(
                            controller:
                                _locationController,
                            hint:
                                'e.g. Amberkhana, Sylhet',
                            icon:
                                LucideIcons.mapPin,
                            errorText:
                                _locationError,
                            maxLength: 100,
                            onChanged: (
                              value,
                            ) {
                              setState(() {
                                if (_locationError !=
                                    null) {
                                  _locationError =
                                      _validateLocation(
                                    value,
                                  );
                                }
                              });
                            },
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const _ProfileLabel(
                            label:
                                'ABOUT YOU',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ProfileTextField(
                            controller:
                                _bioController,
                            hint:
                                'Write a short introduction about yourself...',
                            icon:
                                LucideIcons
                                    .alignLeft,
                            maxLines: 4,
                            maxLength: 300,
                            errorText:
                                _bioError,
                            onChanged: (
                              value,
                            ) {
                              if (_bioError !=
                                  null) {
                                setState(() {
                                  _bioError =
                                      _validateBio(
                                    value,
                                  );
                                });
                              }
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                LucideIcons.info,
                                size: 14,
                                color:
                                    AppColors
                                        .muted,
                              ),

                              const SizedBox(
                                width: 7,
                              ),

                              Expanded(
                                child: Text(
                                  'Your email comes from your verified account and cannot be changed here.',
                                  style:
                                      AppText.body(
                                    size: 10.5,
                                    color:
                                        AppColors
                                            .muted,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 34,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            height: 58,
                            child:
                                ElevatedButton(
                              onPressed:
                                  _isSaving ||
                                          _isUploadingPhoto
                                      ? null
                                      : _saveProfile,
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    AppColors
                                        .ink,
                                foregroundColor:
                                    Colors.white,
                                disabledBackgroundColor:
                                    AppColors
                                        .inkSoft,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors
                                                .white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        const Icon(
                                          LucideIcons
                                              .save,
                                          size: 17,
                                        ),
                                        const SizedBox(
                                          width: 9,
                                        ),
                                        Text(
                                          'Save profile',
                                          style:
                                              AppText
                                                  .label(
                                            color:
                                                Colors
                                                    .white,
                                            size:
                                                13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            height: 56,
                            child:
                                OutlinedButton(
                              onPressed:
                                  _isSaving ||
                                          _isUploadingPhoto
                                      ? null
                                      : _openSettings,
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                foregroundColor:
                                    AppColors
                                        .ink,
                                backgroundColor:
                                    AppColors
                                        .surface,
                                side:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .line,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  const Icon(
                                    LucideIcons
                                        .settings,
                                    size: 17,
                                  ),

                                  const SizedBox(
                                    width: 9,
                                  ),

                                  Text(
                                    'Account settings',
                                    style:
                                        AppText.label(
                                      size: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Center(
                            child: Text(
                              _email.isEmpty
                                  ? 'Signed in account'
                                  : 'Signed in as $_email',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  AppText.body(
                                size: 9.5,
                                color:
                                    AppColors
                                        .muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        16,
        18,
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
              onTap: () {
                Navigator.pop(
                  context,
                );
              },
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
                  'Client profile',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                Text(
                  'Personal details & account',
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

          Material(
            color:
                AppColors.surface,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap:
                  _openSettings,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.line,
                  ),
                ),
                child:
                    const Icon(
                  LucideIcons.settings,
                  size: 18,
                  color:
                      AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PROFILE HERO
  // =====================================================

  Widget _buildProfileHero() {
    final name =
        _nameController.text.trim();

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.dark,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),
      child: Row(
        children: [
          _ProfileAvatar(
            photoUrl:
                _photoUrl,
            initials:
                _getInitials(),
            uploading:
                _isUploadingPhoto,
            onTap:
                _showPhotoOptions,
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name.isEmpty
                      ? 'Client profile'
                      : name,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppText.heading(
                    size: 19,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'CLIENT ACCOUNT',
                  style:
                      AppText.label(
                    size: 9,
                    color:
                        AppColors.gold,
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                Row(
                  children: [
                    const Icon(
                      LucideIcons
                          .mapPin,
                      size: 13,
                      color:
                          Colors.white54,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Expanded(
                      child: Text(
                        _locationController
                                .text
                                .trim()
                                .isEmpty
                            ? 'Location not set'
                            : _locationController
                                .text
                                .trim(),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppText.body(
                          size: 10.5,
                          color:
                              Colors
                                  .white60,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                GestureDetector(
                  onTap:
                      _isUploadingPhoto
                          ? null
                          : _showPhotoOptions,
                  child: Text(
                    _photoUrl.isEmpty
                        ? 'Add profile photo'
                        : 'Change profile photo',
                    style:
                        AppText.label(
                      size: 10,
                      color:
                          AppColors.gold,
                    ),
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

// =====================================================
// PHOTO ACTION
// =====================================================

enum _PhotoAction {
  gallery,
  camera,
  remove,
}

// =====================================================
// PROFILE AVATAR
// =====================================================

class _ProfileAvatar
    extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
  });

  final String photoUrl;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      clipBehavior:
          Clip.none,
      children: [
        Material(
          color:
              Colors.transparent,
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          child: InkWell(
            onTap:
                uploading
                    ? null
                    : onTap,
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            child: Container(
              width: 72,
              height: 72,
              clipBehavior:
                  Clip.antiAlias,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .goldSoft,
                borderRadius:
                    BorderRadius
                        .circular(
                  22,
                ),
                border:
                    Border.all(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: uploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            AppColors
                                .ink,
                      ),
                    )
                  : photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width:
                              double
                                  .infinity,
                          height:
                              double
                                  .infinity,
                          fit:
                              BoxFit
                                  .cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Center(
                              child:
                                  Text(
                                initials,
                                style:
                                    AppText
                                        .display(
                                  size:
                                      21,
                                ),
                              ),
                            );
                          },
                        )
                      : Text(
                          initials,
                          style:
                              AppText.display(
                            size: 21,
                          ),
                        ),
            ),
          ),
        ),

        Positioned(
          right: -5,
          bottom: -5,
          child: Material(
            color:
                AppColors.gold,
            shape:
                const CircleBorder(),
            child: InkWell(
              onTap:
                  uploading
                      ? null
                      : onTap,
              customBorder:
                  const CircleBorder(),
              child:
                  const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  LucideIcons.camera,
                  size: 14,
                  color:
                      AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// PHOTO OPTION TILE
// =====================================================

class _PhotoOptionTile
    extends StatelessWidget {
  const _PhotoOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(
    BuildContext context,
  ) {
    final foreground =
        destructive
            ? Colors.redAccent
            : AppColors.ink;

    return Material(
      color:
          AppColors.background,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(
            15,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: destructive
                      ? Colors.redAccent
                          .withValues(
                          alpha: 0.08,
                        )
                      : AppColors
                          .goldSoft,
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color:
                      foreground,
                ),
              ),

              const SizedBox(
                width: 13,
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
                        size: 13.5,
                        color:
                            foreground,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
                      style:
                          AppText.body(
                        size: 10.5,
                        color:
                            AppColors
                                .muted,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                LucideIcons
                    .chevronRight,
                size: 17,
                color: destructive
                    ? Colors
                        .redAccent
                    : AppColors
                        .muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// LABEL
// =====================================================

class _ProfileLabel
    extends StatelessWidget {
  const _ProfileLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      label,
      style:
          AppText.label(
        size: 9.5,
        color:
            AppColors.inkSoft,
      ),
    );
  }
}

// =====================================================
// TEXT FIELD
// =====================================================

class _ProfileTextField
    extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController
      controller;

  final String hint;
  final IconData icon;
  final TextInputType?
      keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? errorText;

  final ValueChanged<String>?
      onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      keyboardType:
          keyboardType,
      maxLines:
          maxLines,
      maxLength:
          maxLength,
      onChanged:
          onChanged,
      textCapitalization:
          TextCapitalization
              .sentences,
      style:
          AppText.body(
        size: 13.5,
        color:
            AppColors.ink,
      ),
      decoration:
          InputDecoration(
        hintText:
            hint,
        errorText:
            errorText,
        counterText:
            '',
        hintStyle:
            AppText.body(
          size: 13,
          color:
              AppColors.muted,
        ),
        errorStyle:
            AppText.body(
          size: 10,
          color:
              Colors.redAccent,
        ),
        prefixIcon:
            Icon(
          icon,
          size: 18,
          color:
              errorText != null
                  ? Colors
                      .redAccent
                  : AppColors
                      .muted,
        ),
        filled:
            true,
        fillColor:
            AppColors.surface,
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide(
            color:
                errorText != null
                    ? Colors
                        .redAccent
                    : AppColors
                        .line,
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
                AppColors.gold,
            width: 1.3,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                Colors.redAccent,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                Colors.redAccent,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// READ ONLY FIELD
// =====================================================

class _ReadOnlyField
    extends StatelessWidget {
  const _ReadOnlyField({
    required this.value,
    required this.icon,
  });

  final String value;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                AppColors.muted,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              value,
              style:
                  AppText.body(
                size: 13.5,
                color:
                    AppColors
                        .inkSoft,
              ),
            ),
          ),

          const Icon(
            LucideIcons
                .lockKeyhole,
            size: 14,
            color:
                AppColors.muted,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// FRIENDLY ERRORS
// =====================================================

String _friendlyPhotoError(
  Object error,
) {
  final text =
      error
          .toString()
          .toLowerCase();

  if (text.contains(
        'permission-denied',
      ) ||
      text.contains(
        'unauthorized',
      )) {
    return 'Photo upload is not allowed yet. Please check Firebase Storage settings.';
  }

  if (text.contains(
        'network',
      ) ||
      text.contains(
        'unavailable',
      )) {
    return 'Please check your internet connection and try again.';
  }

  if (text.contains(
    '5 mb',
  )) {
    return 'Profile photo must be smaller than 5 MB.';
  }

  return 'Unable to update profile photo. Please try again.';
}

String _friendlyProfileError(
  Object error,
) {
  final text =
      error.toString();

  if (text.contains(
    'permission-denied',
  )) {
    return 'Unable to save your profile. Please try again.';
  }

  if (text.contains(
        'network',
      ) ||
      text.contains(
        'unavailable',
      )) {
    return 'Please check your internet connection and try again.';
  }

  return 'Unable to update profile. Please try again.';
}