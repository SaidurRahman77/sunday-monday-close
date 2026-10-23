import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/category_service.dart';

import '../widgets/premium_ui.dart';
import 'worker_public_profile_screen.dart';

class FindWorkersScreen extends StatefulWidget {
  const FindWorkersScreen({
    super.key,
  });

  @override
  State<FindWorkersScreen> createState() =>
      _FindWorkersScreenState();
}

class _FindWorkersScreenState
    extends State<FindWorkersScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final CategoryService _categoryService =
      CategoryService();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> _categories = [
    'All',
    ...CategoryService.defaultCategories,
  ];

  StreamSubscription<List<String>>? _categorySubscription;
  @override
  void initState() {
    super.initState();

    _categorySubscription =
        _categoryService
            .watchActiveCategoryNames()
            .listen(
      (categories) {
        if (!mounted) {
          return;
        }

        setState(() {
          _categories = [
            'All',
            ...categories,
          ];

          if (!_categories.contains(
            _selectedCategory,
          )) {
            _selectedCategory = 'All';
          }
        });
      },
      onError: (error) {
        debugPrint(
          'FIND WORKERS CATEGORY STREAM ERROR: $error',
        );
      },
    );
  }


  @override
  void dispose() {
    _categorySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openWorkerProfile({
    required String workerId,
    required String workerName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WorkerPublicProfileScreen(
          workerId: workerId,
          workerName: workerName,
        ),
      ),
    );
  }

  bool _matchesFilters(
    Map<String, dynamic> worker,
  ) {
    final name =
        worker['name']
                ?.toString()
                .toLowerCase() ??
            '';

    final location =
        worker['location']
                ?.toString()
                .toLowerCase() ??
            '';

    final bio =
        worker['bio']
                ?.toString()
                .toLowerCase() ??
            '';

    final rawProfile =
        worker['workerProfile'];

    final profile =
        rawProfile is Map
            ? Map<String, dynamic>.from(
                rawProfile,
              )
            : <String, dynamic>{};

    final rawSkills =
        profile['skills'];

    final skills =
        rawSkills is List
            ? rawSkills
                .map(
                  (item) =>
                      item
                          .toString()
                          .toLowerCase(),
                )
                .toList()
            : <String>[];

    final rawCategories =
        profile['categories'];

    final categories =
        rawCategories is List
            ? rawCategories
                .map(
                  (item) =>
                      item.toString(),
                )
                .toList()
            : <String>[];

    final query =
        _searchQuery.trim().toLowerCase();

    final searchMatch =
        query.isEmpty ||
            name.contains(query) ||
            location.contains(query) ||
            bio.contains(query) ||
            skills.any(
              (skill) =>
                  skill.contains(query),
            ) ||
            categories.any(
              (category) =>
                  category
                      .toLowerCase()
                      .contains(query),
            );

    final categoryMatch =
        _selectedCategory == 'All' ||
            categories.contains(
              _selectedCategory,
            );

    return searchMatch &&
        categoryMatch;
  }

  void _sortWorkers(
    List<Map<String, dynamic>> workers,
  ) {
    workers.sort(
      (a, b) {
        final aProfile =
            a['workerProfile'] is Map
                ? Map<String, dynamic>.from(
                    a['workerProfile'],
                  )
                : <String, dynamic>{};

        final bProfile =
            b['workerProfile'] is Map
                ? Map<String, dynamic>.from(
                    b['workerProfile'],
                  )
                : <String, dynamic>{};

        final aAccepting =
            aProfile['acceptingJobs'] ==
                    true ||
                aProfile['isAvailable'] ==
                    true;

        final bAccepting =
            bProfile['acceptingJobs'] ==
                    true ||
                bProfile['isAvailable'] ==
                    true;

        if (aAccepting !=
            bAccepting) {
          return aAccepting
              ? -1
              : 1;
        }

        final aRating =
            (aProfile['rating']
                        as num?)
                    ?.toDouble() ??
                0;

        final bRating =
            (bProfile['rating']
                        as num?)
                    ?.toDouble() ??
                0;

        final ratingCompare =
            bRating.compareTo(
          aRating,
        );

        if (ratingCompare != 0) {
          return ratingCompare;
        }

        final aExperience =
            (aProfile['experienceYears']
                        as num?)
                    ?.toInt() ??
                0;

        final bExperience =
            (bProfile['experienceYears']
                        as num?)
                    ?.toInt() ??
                0;

        return bExperience.compareTo(
          aExperience,
        );
      },
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
              onBack: () {
                Navigator.pop(
                  context,
                );
              },
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .snapshots(),
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
                    return _ErrorState(
                      message:
                          snapshot.error
                              .toString(),
                    );
                  }

                  final currentUid =
                      _auth.currentUser?.uid;

                  final workers =
                      snapshot.data?.docs
                              .where(
                                (doc) {
                                  if (doc.id ==
                                      currentUid) {
                                    return false;
                                  }

                                  final data =
                                      doc.data();

                                  return data[
                                          'workerProfileComplete'] ==
                                      true;
                                },
                              )
                              .map(
                                (doc) {
                                  return <
                                      String,
                                      dynamic>{
                                    ...doc
                                        .data(),
                                    'workerId':
                                        doc.id,
                                  };
                                },
                              )
                              .where(
                                _matchesFilters,
                              )
                              .toList() ??
                          <
                              Map<String,
                                  dynamic>>[];

                  _sortWorkers(
                    workers,
                  );

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      22,
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
                            _searchQuery =
                                value;
                          });
                        },
                        onClear: () {
                          _searchController
                              .clear();

                          setState(() {
                            _searchQuery =
                                '';
                          });
                        },
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        'Work category',
                        style:
                            AppText.heading(
                          size: 15,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 38,
                        child:
                            ListView.separated(
                          scrollDirection:
                              Axis.horizontal,
                          itemCount:
                              _categories
                                  .length,
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
                            final category =
                                _categories[
                                    index];

                            final selected =
                                category ==
                                    _selectedCategory;

                            return _CategoryChip(
                              label:
                                  category,
                              selected:
                                  selected,
                              onTap: () {
                                setState(() {
                                  _selectedCategory =
                                      category;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 26,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Workers',
                              style:
                                  AppText.heading(
                                size: 19,
                              ),
                            ),
                          ),
                          Text(
                            '${workers.length} found',
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
                        height: 14,
                      ),
                      if (workers.isEmpty)
                        const _EmptyState()
                      else
                        ...workers.map(
                          (worker) {
                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),
                              child:
                                  _WorkerCard(
                                worker:
                                    worker,
                                onTap: () {
                                  _openWorkerProfile(
                                    workerId:
                                        worker[
                                                    'workerId']
                                                ?.toString() ??
                                            '',
                                    workerName:
                                        worker[
                                                    'name']
                                                ?.toString() ??
                                            'Worker',
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
            color: AppColors.ink,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            child: InkWell(
              onTap: onBack,
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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Find workers',
                  style:
                      AppText.heading(
                    size: 19,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Discover skilled workers for your job',
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
    );
  }
}

class _SearchBox
    extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppText.body(
          size: 12.5,
        ),
        decoration:
            InputDecoration(
          hintText:
              'Search name, skill or location',
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
            color:
                AppColors.muted,
          ),
          suffixIcon:
              controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed:
                          onClear,
                      icon:
                          const Icon(
                        LucideIcons.x,
                        size: 17,
                      ),
                    ),
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip
    extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected
          ? AppColors.ink
          : AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        30,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        child: Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            border: Border.all(
              color: selected
                  ? AppColors.ink
                  : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppText.label(
              size: 9,
              color: selected
                  ? Colors.white
                  : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerCard
    extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.onTap,
  });

  final Map<String, dynamic> worker;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final name =
        worker['name']
                ?.toString()
                .trim() ??
            'Worker';

    final location =
        worker['location']
                ?.toString()
                .trim() ??
            '';

    final photoUrl =
        worker['photoUrl']
                ?.toString()
                .trim() ??
            '';

    final rawProfile =
        worker['workerProfile'];

    final profile =
        rawProfile is Map
            ? Map<String, dynamic>.from(
                rawProfile,
              )
            : <String, dynamic>{};

    final experience =
        (profile['experienceYears']
                    as num?)
                ?.toInt() ??
            0;

    final rating =
        (profile['rating']
                    as num?)
                ?.toDouble() ??
            0;

    final reviewCount =
        (profile['reviewCount']
                    as num?)
                ?.toInt() ??
            0;

    final acceptingJobs =
        profile['acceptingJobs'] ==
                true ||
            profile['isAvailable'] ==
                true;

    final rawSkills =
        profile['skills'];

    final skills =
        rawSkills is List
            ? rawSkills
                .map(
                  (item) =>
                      item.toString(),
                )
                .where(
                  (item) =>
                      item.trim().isNotEmpty,
                )
                .take(3)
                .toList()
            : <String>[];

    return Material(
      color: AppColors.surface,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            18,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border: Border.all(
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
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    clipBehavior:
                        Clip.antiAlias,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.ink,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
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
                                  return Text(
                                    _initials(
                                      name,
                                    ),
                                    style:
                                        AppText.label(
                                      size: 11,
                                      color:
                                          AppColors.gold,
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
                                  size: 11,
                                  color:
                                      AppColors.gold,
                                ),
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
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Text(
                                name,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    AppText.heading(
                                  size:
                                      15,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    8,
                                vertical:
                                    5,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: acceptingJobs
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
                                acceptingJobs
                                    ? 'AVAILABLE'
                                    : 'BUSY',
                                style:
                                    AppText.label(
                                  size:
                                      7.5,
                                  color: acceptingJobs
                                      ? AppColors
                                          .ink
                                      : AppColors
                                          .muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (location
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons
                                    .mapPin,
                                size: 12,
                                color:
                                    AppColors
                                        .muted,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child:
                                    Text(
                                  location,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      AppText.body(
                                    size:
                                        10,
                                    color:
                                        AppColors
                                            .muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  _Stat(
                    icon:
                        LucideIcons.star,
                    value: reviewCount ==
                            0
                        ? 'New'
                        : rating
                            .toStringAsFixed(
                              1,
                            ),
                    label:
                        '$reviewCount reviews',
                  ),
                  const SizedBox(
                    width: 22,
                  ),
                  _Stat(
                    icon:
                        LucideIcons.briefcase,
                    value:
                        '$experience yr',
                    label:
                        'Experience',
                  ),
                ],
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children:
                      skills.map(
                    (skill) {
                      return Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              9,
                          vertical:
                              6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .background,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child:
                            Text(
                          skill,
                          style:
                              AppText.label(
                            size:
                                8,
                            color:
                                AppColors
                                    .muted,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
              const SizedBox(
                height: 17,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      acceptingJobs
                          ? 'Accepting new jobs'
                          : 'Not accepting jobs right now',
                      style:
                          AppText.body(
                        size: 10,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Row(
                    children: [
                      Text(
                        'View profile',
                        style:
                            AppText.label(
                          size: 9,
                          color:
                              AppColors.ink,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      const Icon(
                        LucideIcons
                            .arrowUpRight,
                        size: 14,
                        color:
                            AppColors.ink,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(
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
      return 'W';
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
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              AppColors.gold,
        ),
        const SizedBox(
          width: 6,
        ),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style:
                  AppText.heading(
                size: 12,
              ),
            ),
            Text(
              label,
              style:
                  AppText.body(
                size: 8.5,
                color:
                    AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        28,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color:
              AppColors.line,
        ),
      ),
      child: Column(
        children: [
          const PremiumIconBox(
            icon:
                LucideIcons.users,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'No workers found',
            style:
                AppText.heading(
              size: 17,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Try another search term or work category.',
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
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

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
        child: Text(
          'Unable to load workers.\n$message',
          textAlign:
              TextAlign.center,
          style:
              AppText.body(
            size: 12,
            color:
                AppColors.muted,
          ),
        ),
      ),
    );
  }
}