import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/category_service.dart';

import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../widgets/premium_ui.dart';
import 'account_settings_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final CategoryService _categoryService = CategoryService();
  final ReviewService _reviewService = ReviewService();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _bioController =
      TextEditingController();

  final TextEditingController _skillsController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  double? _savedScrollOffset;

  List<String> _categories =
      List<String>.from(
    CategoryService.defaultCategories,
  );

  StreamSubscription<List<String>>? _categorySubscription;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  final Set<String> _selectedCategories = {};

  final Map<String, List<_AvailabilitySlot>> _availability = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  String _email = '';

  int _experienceYears = 0;

  bool _acceptingJobs = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  String _photoUrl = '';

  String? _nameError;
  String? _phoneError;
  String? _locationError;
  String? _skillsError;
  String? _bioError;

  @override
  void initState() {
    super.initState();
    _watchCategories();
    _loadProfile();
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();

    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _scrollController.dispose();

    super.dispose();
  }
  void _watchCategories() {
    _categorySubscription =
        _categoryService
            .watchActiveCategoryNames()
            .listen(
      (activeCategories) {
        if (!mounted) {
          return;
        }

        final merged = <String>[
          ...activeCategories,
        ];

        for (final selected
            in _selectedCategories) {
          if (!merged.contains(
            selected,
          )) {
            merged.add(
              selected,
            );
          }
        }

        setState(() {
          _categories = merged;
        });
      },
      onError: (error) {
        debugPrint(
          'WORKER PROFILE CATEGORY STREAM ERROR: $error',
        );
      },
    );
  }


  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    _email = user.email ?? '';

    try {
      final profile =
          await _profileService.getProfile();

      if (profile != null) {
        _nameController.text =
            profile['name']?.toString() ??
                user.displayName ??
                '';

        _phoneController.text =
            profile['phone']?.toString() ?? '';

        _locationController.text =
            profile['location']?.toString() ?? '';

        _bioController.text =
            profile['bio']?.toString() ?? '';

        _photoUrl =
            profile['photoUrl']
                    ?.toString()
                    .trim() ??
                user.photoURL?.trim() ??
                '';

        final rawWorker =
            profile['workerProfile'];

        if (rawWorker is Map) {
          final workerProfile =
              Map<String, dynamic>.from(
            rawWorker,
          );

          final skills =
              workerProfile['skills'];

          if (skills is List) {
            _skillsController.text =
                skills
                    .map(
                      (item) =>
                          item.toString(),
                    )
                    .join(', ');
          }

          final categories =
              workerProfile['categories'];

          if (categories is List) {
            _selectedCategories.addAll(
              categories.map(
                (item) =>
                    item.toString(),
              ),
            );

          for (final selected in _selectedCategories) {
            if (!_categories.contains(selected)) {
              _categories.add(selected);
            }
          }
          }

          final experience =
              workerProfile[
                  'experienceYears'];

          if (experience is num) {
            _experienceYears =
                experience.toInt();
          }

          final accepting =
              workerProfile[
                  'acceptingJobs'];

          final oldAvailable =
              workerProfile[
                  'isAvailable'];

          if (accepting is bool) {
            _acceptingJobs =
                accepting;
          } else if (oldAvailable
              is bool) {
            _acceptingJobs =
                oldAvailable;
          }

          final rawAvailability =
              workerProfile[
                  'availability'];

          if (rawAvailability is Map) {
            for (final day
                in _days) {
              final rawSlots =
                  rawAvailability[day];

              if (rawSlots is List) {
                final parsedSlots =
                    <_AvailabilitySlot>[];

                for (final rawSlot
                    in rawSlots) {
                  if (rawSlot is Map) {
                    final slotMap =
                        Map<String, dynamic>.from(
                      rawSlot,
                    );

                    final start =
                        slotMap[
                            'startMinutes'];

                    final end =
                        slotMap[
                            'endMinutes'];

                    if (start is num &&
                        end is num) {
                      final startValue =
                          start.toInt();

                      final endValue =
                          end.toInt();

                      if (startValue >= 0 &&
                          endValue <= 1440 &&
                          startValue <
                              endValue) {
                        parsedSlots.add(
                          _AvailabilitySlot(
                            startMinutes:
                                startValue,
                            endMinutes:
                                endValue,
                          ),
                        );
                      }
                    }
                  }
                }

                parsedSlots.sort(
                  (a, b) =>
                      a.startMinutes
                          .compareTo(
                    b.startMinutes,
                  ),
                );

                _availability[day] =
                    parsedSlots;
              }
            }
          }
        }
      } else {
        _nameController.text =
            user.displayName ?? '';

        _photoUrl =
            user.photoURL?.trim() ??
                '';
      }
    } catch (e) {
      debugPrint(
        'WORKER PROFILE LOAD ERROR: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to load worker profile.',
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getSkills() {
    return _skillsController.text
        .split(',')
        .map(
          (skill) =>
              skill.trim(),
        )
        .where(
          (skill) =>
              skill.isNotEmpty,
        )
        .toSet()
        .toList();
  }

  Map<String, List<Map<String, int>>>
      _availabilityForFirestore() {
    final result =
        <String,
            List<Map<String, int>>>{};

    for (final day in _days) {
      final slots =
          List<_AvailabilitySlot>.from(
        _availability[day] ?? [],
      );

      slots.sort(
        (a, b) =>
            a.startMinutes.compareTo(
          b.startMinutes,
        ),
      );

      result[day] =
          slots
              .map(
                (slot) => {
                  'startMinutes':
                      slot.startMinutes,
                  'endMinutes':
                      slot.endMinutes,
                },
              )
              .toList();
    }

    return result;
  }

  bool _hasAnyAvailability() {
    return _availability.values.any(
      (slots) =>
          slots.isNotEmpty,
    );
  }

  bool _hasOverlap(
    String day,
    _AvailabilitySlot candidate, {
    int? ignoreIndex,
  }) {
    final slots =
        _availability[day] ?? [];

    for (int i = 0;
        i < slots.length;
        i++) {
      if (ignoreIndex != null &&
          i == ignoreIndex) {
        continue;
      }

      final slot =
          slots[i];

      final overlaps =
          candidate.startMinutes <
                  slot.endMinutes &&
              candidate.endMinutes >
                  slot.startMinutes;

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  Future<void> _addTimeSlot(
    String day,
  ) async {
    final start =
        await showTimePicker(
      context: context,
      initialTime:
          const TimeOfDay(
        hour: 9,
        minute: 0,
      ),
    );

    if (start == null ||
        !mounted) {
      return;
    }

    final startMinutes =
        _timeToMinutes(
      start,
    );

    final suggestedEnd =
        startMinutes + 60;

    final initialEnd =
        _minutesToTime(
      suggestedEnd > 1439
          ? 1439
          : suggestedEnd,
    );

    final end =
        await showTimePicker(
      context: context,
      initialTime:
          initialEnd,
    );

    if (end == null ||
        !mounted) {
      return;
    }

    int endMinutes =
        _timeToMinutes(
      end,
    );

    if (endMinutes == 0 &&
        startMinutes > 0) {
      endMinutes = 1440;
    }

    if (endMinutes <=
        startMinutes) {
      _showMessage(
        'End time must be later than start time.',
      );
      return;
    }

    final candidate =
        _AvailabilitySlot(
      startMinutes:
          startMinutes,
      endMinutes:
          endMinutes,
    );

    if (_hasOverlap(
      day,
      candidate,
    )) {
      _showMessage(
        'This time overlaps with another ${_dayLabels[day]} slot.',
      );
      return;
    }

    setState(() {
      _availability[day]!
          .add(
        candidate,
      );

      _availability[day]!
          .sort(
        (a, b) =>
            a.startMinutes
                .compareTo(
          b.startMinutes,
        ),
      );
    });
  }

  Future<void> _editStartTime(
    String day,
    int index,
  ) async {
    final slot =
        _availability[day]![index];

    final picked =
        await showTimePicker(
      context: context,
      initialTime:
          _minutesToTime(
        slot.startMinutes,
      ),
    );

    if (picked == null ||
        !mounted) {
      return;
    }

    final newStart =
        _timeToMinutes(
      picked,
    );

    if (newStart >=
        slot.endMinutes) {
      _showMessage(
        'Start time must be earlier than end time.',
      );
      return;
    }

    final candidate =
        _AvailabilitySlot(
      startMinutes:
          newStart,
      endMinutes:
          slot.endMinutes,
    );

    if (_hasOverlap(
      day,
      candidate,
      ignoreIndex: index,
    )) {
      _showMessage(
        'This time overlaps with another slot.',
      );
      return;
    }

    setState(() {
      _availability[day]![index] =
          candidate;

      _availability[day]!
          .sort(
        (a, b) =>
            a.startMinutes
                .compareTo(
          b.startMinutes,
        ),
      );
    });
  }

  Future<void> _editEndTime(
    String day,
    int index,
  ) async {
    final slot =
        _availability[day]![index];

    final picked =
        await showTimePicker(
      context: context,
      initialTime:
          _minutesToTime(
        slot.endMinutes,
      ),
    );

    if (picked == null ||
        !mounted) {
      return;
    }

    int newEnd =
        _timeToMinutes(
      picked,
    );

    if (newEnd == 0 &&
        slot.startMinutes > 0) {
      newEnd = 1440;
    }

    if (newEnd <=
        slot.startMinutes) {
      _showMessage(
        'End time must be later than start time.',
      );
      return;
    }

    final candidate =
        _AvailabilitySlot(
      startMinutes:
          slot.startMinutes,
      endMinutes:
          newEnd,
    );

    if (_hasOverlap(
      day,
      candidate,
      ignoreIndex: index,
    )) {
      _showMessage(
        'This time overlaps with another slot.',
      );
      return;
    }

    setState(() {
      _availability[day]![index] =
          candidate;

      _availability[day]!
          .sort(
        (a, b) =>
            a.startMinutes
                .compareTo(
          b.startMinutes,
        ),
      );
    });
  }

  void _removeSlot(
    String day,
    int index,
  ) {
    setState(() {
      _availability[day]!
          .removeAt(
        index,
      );
    });
  }

  void _rememberScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollOffset =
          _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    final target =
        _savedScrollOffset;

    if (target == null) {
      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted ||
            !_scrollController.hasClients) {
          return;
        }

        final maxOffset =
            _scrollController
                .position
                .maxScrollExtent;

        final safeOffset =
            target.clamp(
          0.0,
          maxOffset,
        );

        _scrollController.jumpTo(
          safeOffset.toDouble(),
        );
      },
    );
  }

  String? _validateName(
    String value,
  ) {
    final name = value.trim();

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
    final phone = value.trim();

    if (phone.isEmpty) {
      return 'Please enter your phone number.';
    }

    final digits = phone.replaceAll(
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
    final location = value.trim();

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

  String? _validateSkills(
    String value,
  ) {
    final skills = _getSkills();

    if (skills.isEmpty) {
      return 'Please add at least one skill.';
    }

    if (value.trim().length > 250) {
      return 'Skills cannot exceed 250 characters.';
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

  bool _validateProfileFields() {
    final nameError = _validateName(
      _nameController.text,
    );

    final phoneError = _validatePhone(
      _phoneController.text,
    );

    final locationError = _validateLocation(
      _locationController.text,
    );

    final skillsError = _validateSkills(
      _skillsController.text,
    );

    final bioError = _validateBio(
      _bioController.text,
    );

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _locationError = locationError;
      _skillsError = skillsError;
      _bioError = bioError;
    });

    return nameError == null &&
        phoneError == null &&
        locationError == null &&
        skillsError == null &&
        bioError == null;
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

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    _rememberScrollPosition();

    FocusManager.instance.primaryFocus
        ?.unfocus();

    _restoreScrollPosition();

    if (!_validateProfileFields()) {
      _restoreScrollPosition();
      _showMessage(
        'Please correct the highlighted fields.',
      );
      return;
    }

    final skills =
        _getSkills();

    if (_selectedCategories
        .isEmpty) {
      _showMessage(
        'Please select at least one work category.',
      );
      return;
    }

    if (_acceptingJobs &&
        !_hasAnyAvailability()) {
      _showMessage(
        'Add at least one weekly availability slot.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    _restoreScrollPosition();

    try {
      await _profileService
          .saveWorkerProfile(
        name:
            _nameController.text,
        phone:
            _phoneController.text,
        location:
            _locationController.text,
        bio:
            _bioController.text,
        skills:
            skills,
        categories:
            _selectedCategories
                .toList(),
        experienceYears:
            _experienceYears,
        acceptingJobs:
            _acceptingJobs,
        availability:
            _availabilityForFirestore(),
      );

      if (!mounted) return;

      _showMessage(
        'Worker profile updated successfully.',
      );

      _restoreScrollPosition();
    } catch (e) {
      debugPrint(
        'WORKER PROFILE SAVE ERROR: $e',
      );

      if (!mounted) return;

      _showMessage(
        _friendlyWorkerProfileError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        _restoreScrollPosition();
      }
    }
  }

  int _timeToMinutes(
    TimeOfDay time,
  ) {
    return time.hour * 60 +
        time.minute;
  }

  TimeOfDay _minutesToTime(
    int minutes,
  ) {
    if (minutes >= 1440) {
      return const TimeOfDay(
        hour: 0,
        minute: 0,
      );
    }

    return TimeOfDay(
      hour: minutes ~/ 60,
      minute: minutes % 60,
    );
  }

  String _formatMinutes(
    int minutes,
  ) {
    if (minutes >= 1440) {
      return '12:00 AM';
    }

    final hour24 =
        minutes ~/ 60;

    final minute =
        minutes % 60;

    final period =
        hour24 >= 12
            ? 'PM'
            : 'AM';

    int hour12 =
        hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final minuteText =
        minute.toString().padLeft(
              2,
              '0',
            );

    return '$hour12:$minuteText $period';
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

  Future<void> _showPhotoOptions() async {
    if (_isUploadingPhoto) return;

    final action = await showModalBottomSheet<_WorkerPhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text('Profile photo', style: AppText.heading(size: 18)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(LucideIcons.x, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _WorkerPhotoOptionTile(
                  icon: LucideIcons.image,
                  title: 'Choose from gallery',
                  subtitle: 'Select a photo from your device',
                  onTap: () => Navigator.pop(sheetContext, _WorkerPhotoAction.gallery),
                ),
                const SizedBox(height: 10),
                _WorkerPhotoOptionTile(
                  icon: LucideIcons.camera,
                  title: 'Take a photo',
                  subtitle: 'Use your device camera',
                  onTap: () => Navigator.pop(sheetContext, _WorkerPhotoAction.camera),
                ),
                if (_photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _WorkerPhotoOptionTile(
                    icon: LucideIcons.trash2,
                    title: 'Remove photo',
                    subtitle: 'Show your initials instead',
                    destructive: true,
                    onTap: () => Navigator.pop(sheetContext, _WorkerPhotoAction.remove),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _WorkerPhotoAction.gallery:
        await _pickAndUploadPhoto(ImageSource.gallery);
        break;
      case _WorkerPhotoAction.camera:
        await _pickAndUploadPhoto(ImageSource.camera);
        break;
      case _WorkerPhotoAction.remove:
        await _removeProfilePhoto();
        break;
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_isUploadingPhoto) return;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Profile photo must be smaller than 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);
      final photoUrl = await _profileService.uploadProfilePhoto(
        bytes: bytes,
        extension: _getImageExtension(image.name),
      );
      if (!mounted) return;
      setState(() => _photoUrl = photoUrl);
      _showMessage('Profile photo updated.');
    } catch (e) {
      debugPrint('WORKER PHOTO UPLOAD ERROR: $e');
      if (!mounted) return;
      _showMessage(_friendlyWorkerPhotoError(e));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    if (_isUploadingPhoto || _photoUrl.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove profile photo?', style: AppText.heading(size: 19)),
        content: Text(
          'Your initials will be shown instead.',
          style: AppText.body(size: 12.5, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: AppText.label(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      await _profileService.removeProfilePhoto();
      if (!mounted) return;
      setState(() => _photoUrl = '');
      _showMessage('Profile photo removed.');
    } catch (e) {
      debugPrint('WORKER PHOTO REMOVE ERROR: $e');
      if (!mounted) return;
      _showMessage(_friendlyWorkerPhotoError(e));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String _getImageExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return 'jpg';
    final extension = parts.last;
    if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'webp') {
      return extension;
    }
    return 'jpg';
  }

  String _getInitials() {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      return 'W';
    }

    final parts =
        name
            .split(' ')
            .where(
              (part) =>
                  part.trim().isNotEmpty,
            )
            .toList();

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
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
            _buildHeader(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
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
                          const EdgeInsets.fromLTRB(
                        20,
                        24,
                        20,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHero(),

                          const SizedBox(
                            height: 28,
                          ),

                          _buildReviewsSection(),

                          const SizedBox(
                            height: 30,
                          ),

                          Text(
                            'Basic information',
                            style:
                                AppText.heading(
                              size: 20,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const _Label(
                            text:
                                'FULL NAME',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _Field(
                            controller:
                                _nameController,
                            icon:
                                LucideIcons.user,
                            hint:
                                'Enter your full name',
                            maxLength: 60,
                            errorText:
                                _nameError,
                            onChanged: (value) {
                              setState(() {
                                _nameError =
                                    _nameError == null
                                        ? null
                                        : _validateName(
                                            value,
                                          );
                              });
                            },
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const _Label(
                            text:
                                'EMAIL ADDRESS',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _ReadOnlyField(
                            value:
                                _email,
                            icon:
                                LucideIcons.mail,
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const _Label(
                            text:
                                'PHONE NUMBER',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _Field(
                            controller:
                                _phoneController,
                            icon:
                                LucideIcons.phone,
                            hint:
                                'e.g. 017XXXXXXXX',
                            keyboardType:
                                TextInputType.phone,
                            maxLength: 20,
                            errorText:
                                _phoneError,
                            onChanged: (value) {
                              if (_phoneError != null) {
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
                            height: 18,
                          ),

                          const _Label(
                            text:
                                'LOCATION / AREA',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _Field(
                            controller:
                                _locationController,
                            icon:
                                LucideIcons.mapPin,
                            hint:
                                'e.g. Amberkhana, Sylhet',
                            maxLength: 100,
                            errorText:
                                _locationError,
                            onChanged: (value) {
                              setState(() {
                                if (_locationError != null) {
                                  _locationError =
                                      _validateLocation(
                                    value,
                                  );
                                }
                              });
                            },
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          Text(
                            'Professional details',
                            style:
                                AppText.heading(
                              size: 20,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Your skills and experience will be used to find suitable jobs.',
                            style:
                                AppText.body(
                              size: 12,
                              color:
                                  AppColors.muted,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const _Label(
                            text:
                                'SKILLS',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _Field(
                            controller:
                                _skillsController,
                            icon:
                                LucideIcons.sparkles,
                            hint:
                                'e.g. Wiring, Fan repair, CCTV',
                            maxLines: 2,
                            maxLength: 250,
                            errorText:
                                _skillsError,
                            onChanged: (value) {
                              if (_skillsError != null) {
                                setState(() {
                                  _skillsError =
                                      _validateSkills(
                                    value,
                                  );
                                });
                              }
                            },
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          Text(
                            'Separate multiple skills with commas.',
                            style:
                                AppText.body(
                              size: 10.5,
                              color:
                                  AppColors.muted,
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          const _Label(
                            text:
                                'EXPERIENCE',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _buildExperienceCard(),

                          const SizedBox(
                            height: 24,
                          ),

                          const _Label(
                            text:
                                'WORK CATEGORIES',
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _categories.map(
                              (category) {
                                final selected =
                                    _selectedCategories
                                        .contains(
                                  category,
                                );

                                return FilterChip(
                                  label:
                                      Text(
                                    category,
                                  ),
                                  selected:
                                      selected,
                                  onSelected:
                                      (value) {
                                    setState(() {
                                      if (value) {
                                        _selectedCategories
                                            .add(
                                          category,
                                        );
                                      } else {
                                        _selectedCategories
                                            .remove(
                                          category,
                                        );
                                      }
                                    });
                                  },
                                  backgroundColor:
                                      AppColors.surface,
                                  selectedColor:
                                      AppColors.goldSoft,
                                  side:
                                      BorderSide(
                                    color: selected
                                        ? AppColors.gold
                                        : AppColors.line,
                                  ),
                                  labelStyle:
                                      AppText.label(
                                    size: 10.5,
                                  ),
                                  showCheckmark:
                                      false,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      30,
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),

                          const SizedBox(
                            height: 32,
                          ),

                          Text(
                            'Availability',
                            style:
                                AppText.heading(
                              size: 20,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Set the exact days and hours when you can accept work.',
                            style:
                                AppText.body(
                              size: 12,
                              color:
                                  AppColors.muted,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          _buildAcceptingJobsCard(),

                          const SizedBox(
                            height: 18,
                          ),

                          ..._days.map(
                            _buildDayCard,
                          ),

                          const SizedBox(
                            height: 28,
                          ),

                          const _Label(
                            text:
                                'ABOUT YOU',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _Field(
                            controller:
                                _bioController,
                            icon:
                                LucideIcons.alignLeft,
                            hint:
                                'Write a short professional introduction...',
                            maxLines: 4,
                            maxLength: 300,
                            errorText:
                                _bioError,
                            onChanged: (value) {
                              if (_bioError != null) {
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
                            height: 32,
                          ),

                          SizedBox(
                            width:
                                double.infinity,
                            height: 58,
                            child:
                                ElevatedButton(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : _saveProfile,
                              style:
                                  ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    AppColors.ink,
                                foregroundColor:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              LucideIcons.save,
                                              size: 17,
                                            ),
                                            const SizedBox(
                                              width: 9,
                                            ),
                                            Text(
                                              'Save worker profile',
                                              style:
                                                  AppText.label(
                                                color:
                                                    Colors.white,
                                                size: 13,
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
                                  _isSaving
                                      ? null
                                      : _openSettings,
                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.ink,
                                backgroundColor:
                                    AppColors.surface,
                                side:
                                    const BorderSide(
                                  color:
                                      AppColors.line,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.settings,
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
                            height: 8,
                          ),

                          Center(
                            child: Text(
                              _email.isEmpty
                                  ? 'Signed in account'
                                  : 'Signed in as $_email',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  AppText.body(
                                size: 9.5,
                                color:
                                    AppColors.muted,
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

  Widget _buildHeader() {
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
                    LucideIcons.arrowLeft,
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
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Worker profile',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),

                Text(
                  'Skills, availability & work preferences',
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
                  _isSaving
                      ? null
                      : _openSettings,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: Container(
                width: 42,
                height: 42,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
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
                  size: 17,
                  color:
                      AppColors.ink,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppColors.goldSoft,
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: Text(
              'WORKER',
              style:
                  AppText.label(
                size: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink,
                            ),
                          )
                        : _photoUrl.isNotEmpty
                            ? Image.network(
                                _photoUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(_getInitials(), style: AppText.display(size: 22)),
                                ),
                              )
                            : Text(_getInitials(), style: AppText.display(size: 22)),
                  ),
                ),
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Material(
                  color: AppColors.gold,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(LucideIcons.camera, size: 14, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Worker profile'
                      : _nameController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading(size: 19, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  _acceptingJobs ? 'Accepting new jobs' : 'Not accepting jobs',
                  style: AppText.body(size: 11, color: Colors.white54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 13, color: AppColors.gold),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _locationController.text.trim().isEmpty
                            ? 'Location not set'
                            : _locationController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 10.5, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                  child: Text(
                    _photoUrl.isEmpty ? 'Add profile photo' : 'Change profile photo',
                    style: AppText.label(size: 10, color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reviewService.getWorkerReviews(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.line,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Ratings & reviews',
                  style: AppText.heading(
                    size: 18,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  'Unable to load reviews right now.',
                  style: AppText.body(
                    size: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          );
        }

        final reviews =
            snapshot.data ?? [];

        double averageRating = 0;

        if (reviews.isNotEmpty) {
          final total =
              reviews.fold<double>(
            0,
            (
              totalSoFar,
              review,
            ) {
              final stars =
                  review['stars'];

              if (stars is num) {
                return totalSoFar +
                    stars.toDouble();
              }

              return totalSoFar;
            },
          );

          averageRating =
              total / reviews.length;
        }

        final recentReviews =
            reviews.take(3).toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Ratings & reviews',
              style: AppText.heading(
                size: 20,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Feedback from clients after completed jobs.',
              style: AppText.body(
                size: 12,
                color: AppColors.muted,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _buildRatingSummary(
              averageRating:
                  averageRating,
              reviewCount:
                  reviews.length,
            ),

            const SizedBox(
              height: 18,
            ),

            if (reviews.isEmpty)
              Container(
                width: double.infinity,
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
                    20,
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.line,
                  ),
                ),
                child:
                    Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
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
                      child:
                          const Icon(
                        LucideIcons.star,
                        size: 18,
                        color:
                            AppColors.gold,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No reviews yet',
                            style:
                                AppText.heading(
                              size: 13.5,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            'Client reviews will appear here after completed jobs.',
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
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent reviews',
                      style:
                          AppText.heading(
                        size: 15,
                      ),
                    ),
                  ),

                  Text(
                    '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                    style:
                        AppText.body(
                      size: 10.5,
                      color:
                          AppColors.muted,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              ...recentReviews.map(
                (review) =>
                    Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child:
                      _buildReviewCard(
                    review,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRatingSummary({
    required double averageRating,
    required int reviewCount,
  }) {
    final displayRating =
        reviewCount == 0
            ? 'New'
            : averageRating.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 31,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayRating,
                      style: AppText.display(
                        size: 27,
                        color: Colors.white,
                      ),
                    ),

                    if (reviewCount > 0) ...[
                      const SizedBox(
                        width: 4,
                      ),

                      Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 4,
                        ),
                        child: Text(
                          '/ 5',
                          style: AppText.body(
                            size: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                if (reviewCount > 0)
                  Row(
                    children:
                        List.generate(
                      5,
                      (
                        index,
                      ) {
                        final starValue =
                            index + 1;

                        final filled =
                            averageRating >=
                                starValue -
                                    0.25;

                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 17,
                          color: AppColors.gold,
                        );
                      },
                    ),
                  )
                else
                  Text(
                    'No ratings yet',
                    style: AppText.body(
                      size: 11,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
            child: Text(
              '$reviewCount ${reviewCount == 1 ? 'REVIEW' : 'REVIEWS'}',
              style: AppText.label(
                size: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> review,
  ) {
    final stars =
        (review['stars'] as num?)
                ?.toInt() ??
            0;

    final jobTitle =
        review['jobTitle']
                ?.toString()
                .trim() ??
            '';

    final comment =
        review['comment']
                ?.toString()
                .trim() ??
            '';

    final createdAt =
        review['createdAt'];

    String dateText =
        'Recently';

    if (createdAt is Timestamp) {
      dateText =
          _formatReviewDate(
        createdAt.toDate(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  LucideIcons.messageSquareText,
                  size: 16,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle.isEmpty
                          ? 'Completed job'
                          : jobTitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: AppText.heading(
                        size: 12.5,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      dateText,
                      style: AppText.body(
                        size: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.gold,
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Text(
                      '$stars/5',
                      style: AppText.label(
                        size: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children:
                List.generate(
              5,
              (
                index,
              ) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 2,
                  ),
                  child: Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 17,
                    color: AppColors.gold,
                  ),
                );
              },
            ),
          ),

          if (comment.isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              comment,
              style: AppText.body(
                size: 11.5,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  Widget _buildExperienceCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.briefcaseBusiness,
            size: 19,
            color:
                AppColors.gold,
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$_experienceYears ${_experienceYears == 1 ? 'year' : 'years'}',
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),

                Text(
                  'Professional experience',
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

          IconButton(
            onPressed:
                _experienceYears > 0
                    ? () {
                        setState(() {
                          _experienceYears--;
                        });
                      }
                    : null,
            icon:
                const Icon(
              LucideIcons.minus,
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                if (_experienceYears <
                    50) {
                  _experienceYears++;
                }
              });
            },
            icon:
                const Icon(
              LucideIcons.plus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptingJobsCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
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
            width: 42,
            height: 42,
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
            child:
                const Icon(
              LucideIcons.briefcase,
              size: 18,
              color:
                  AppColors.ink,
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
                  'Accepting new jobs',
                  style:
                      AppText.heading(
                    size: 13.5,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _acceptingJobs
                      ? 'Your schedule can be used for job matching.'
                      : 'Matching is temporarily paused.',
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

          Switch(
            value:
                _acceptingJobs,
            activeTrackColor:
                AppColors.gold,
            onChanged:
                (value) {
              setState(() {
                _acceptingJobs =
                    value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    String day,
  ) {
    final slots =
        _availability[day] ?? [];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        16,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dayLabels[day]!,
                  style:
                      AppText.heading(
                    size: 14,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      slots.isEmpty
                          ? AppColors.background
                          : AppColors.goldSoft,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  slots.isEmpty
                      ? 'UNAVAILABLE'
                      : '${slots.length} ${slots.length == 1 ? 'SLOT' : 'SLOTS'}',
                  style:
                      AppText.label(
                    size: 8.5,
                    color:
                        slots.isEmpty
                            ? AppColors.muted
                            : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),

          if (slots.isEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'No working hours added.',
                style:
                    AppText.body(
                  size: 11,
                  color:
                      AppColors.muted,
                ),
              ),
            ),
          ],

          if (slots.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            ...List.generate(
              slots.length,
              (index) {
                final slot =
                    slots[index];

                return Padding(
                  padding:
                      EdgeInsets.only(
                    bottom:
                        index ==
                                slots.length -
                                    1
                            ? 0
                            : 10,
                  ),
                  child:
                      _buildTimeSlotRow(
                    day,
                    index,
                    slot,
                  ),
                );
              },
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          Material(
            color:
                AppColors.background,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: () {
                _addTimeSlot(
                  day,
                );
              },
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 15,
                      color:
                          AppColors.ink,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      slots.isEmpty
                          ? 'Add working hours'
                          : 'Add another time',
                      style:
                          AppText.label(
                        size: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(
    String day,
    int index,
    _AvailabilitySlot slot,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimeButton(
              label:
                  'FROM',
              time:
                  _formatMinutes(
                slot.startMinutes,
              ),
              onTap: () {
                _editStartTime(
                  day,
                  index,
                );
              },
            ),
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Icon(
              LucideIcons.arrowRight,
              size: 16,
              color:
                  AppColors.muted,
            ),
          ),

          Expanded(
            child: _TimeButton(
              label:
                  'TO',
              time:
                  _formatMinutes(
                slot.endMinutes,
              ),
              onTap: () {
                _editEndTime(
                  day,
                  index,
                );
              },
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          IconButton(
            tooltip:
                'Remove time',
            onPressed: () {
              _removeSlot(
                day,
                index,
              );
            },
            icon:
                const Icon(
              LucideIcons.trash2,
              size: 17,
              color:
                  AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyWorkerProfileError(
  Object error,
) {
  final text = error.toString();

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

  return 'Unable to update worker profile. Please try again.';
}

enum _WorkerPhotoAction { gallery, camera, remove }

class _WorkerPhotoOptionTile extends StatelessWidget {
  const _WorkerPhotoOptionTile({
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
  Widget build(BuildContext context) {
    final foreground = destructive ? Colors.redAccent : AppColors.ink;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: destructive
                      ? Colors.redAccent.withValues(alpha: 0.08)
                      : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: foreground),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.heading(size: 13.5, color: foreground)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.body(size: 10.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 17,
                color: destructive ? Colors.redAccent : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyWorkerPhotoError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('5 mb')) return 'Profile photo must be smaller than 5 MB.';
  if (text.contains('network') || text.contains('unavailable') || text.contains('socket')) {
    return 'Please check your internet connection and try again.';
  }
  if (text.contains('upload preset')) {
    return 'Profile photo upload configuration is not available.';
  }
  return 'Unable to update profile photo. Please try again.';
}

class _AvailabilitySlot {
  final int startMinutes;
  final int endMinutes;

  const _AvailabilitySlot({
    required this.startMinutes,
    required this.endMinutes,
  });
}

class _TimeButton
    extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        13,
      ),
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration:
              BoxDecoration(
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
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    AppText.label(
                  size: 7.5,
                  color:
                      AppColors.muted,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                time,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppText.heading(
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label
    extends StatelessWidget {
  final String text;

  const _Label({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          AppText.label(
        size: 9.5,
        color:
            AppColors.inkSoft,
      ),
    );
  }
}

class _Field
    extends StatelessWidget {
  final TextEditingController
      controller;

  final IconData icon;

  final String hint;

  final int maxLines;

  final TextInputType?
      keyboardType;

  final ValueChanged<String>?
      onChanged;

  final int? maxLength;

  final String? errorText;

  const _Field({
    required this.controller,
    required this.icon,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.maxLength,
    this.errorText,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      maxLines:
          maxLines,
      keyboardType:
          keyboardType,
      maxLength:
          maxLength,
      onChanged:
          onChanged,
      textCapitalization:
          TextCapitalization.sentences,
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
              errorText != null
                  ? Colors.redAccent
                  : AppColors.muted,
        ),
        prefixIcon:
            Icon(
          icon,
          size: 18,
          color:
              AppColors.muted,
        ),
        errorStyle:
            AppText.body(
          size: 10,
          color:
              Colors.redAccent,
        ),
        filled:
            true,
        fillColor:
            AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(
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
                    ? Colors.redAccent
                    : AppColors.line,
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

class _ReadOnlyField
    extends StatelessWidget {
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.value,
    required this.icon,
  });

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
        border:
            Border.all(
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
              value.isEmpty
                  ? 'No email'
                  : value,
              style:
                  AppText.body(
                size: 13.5,
                color:
                    AppColors.inkSoft,
              ),
            ),
          ),

          const Icon(
            LucideIcons.lockKeyhole,
            size: 14,
            color:
                AppColors.muted,
          ),
        ],
      ),
    );
  }
}