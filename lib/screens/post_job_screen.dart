import 'dart:async';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/job_service.dart';
import '../services/category_service.dart';

import '../widgets/premium_ui.dart';

class PostJobScreen extends StatefulWidget {

  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() =>
      _PostJobScreenState();

}



class _PostJobScreenState extends State<PostJobScreen> {

  final JobService _jobService = JobService();

  final CategoryService _categoryService = CategoryService();



  final TextEditingController _titleController =

      TextEditingController();



  final TextEditingController _skillsController =

      TextEditingController();



  final TextEditingController _descriptionController =

      TextEditingController();



  final TextEditingController _locationController =

      TextEditingController();



  final TextEditingController _budgetController =

      TextEditingController();



  List<String> _categories =
      List<String>.from(
    CategoryService.defaultCategories,
  );

  StreamSubscription<List<String>>? _categorySubscription;



  String? _selectedCategory;



  DateTime? _selectedDate;

  TimeOfDay? _selectedTime;



  int _durationHours = 2;



  bool _isSubmitting = false;
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
          _categories = categories;

          if (_selectedCategory != null &&
              !_categories.contains(
                _selectedCategory,
              )) {
            _selectedCategory = null;
          }
        });
      },
      onError: (error) {
        debugPrint(
          'POST JOB CATEGORY STREAM ERROR: $error',
        );
      },
    );
  }




  @override

  void dispose() {
    _categorySubscription?.cancel();

    _titleController.dispose();

    _skillsController.dispose();

    _descriptionController.dispose();

    _locationController.dispose();

    _budgetController.dispose();



    super.dispose();

  }



  Future<void> _pickDate() async {

    final now = DateTime.now();



    final picked = await showDatePicker(

      context: context,

      initialDate: _selectedDate ?? now,

      firstDate: DateTime(

        now.year,

        now.month,

        now.day,

      ),

      lastDate: now.add(

        const Duration(days: 365),

      ),

      builder: (context, child) {

        return Theme(

          data: Theme.of(context).copyWith(

            colorScheme: const ColorScheme.light(

              primary: AppColors.ink,

              onPrimary: Colors.white,

              surface: AppColors.surface,

              onSurface: AppColors.ink,

            ),

          ),

          child: child!,

        );

      },

    );



    if (picked != null) {

      setState(() {

        _selectedDate = picked;

      });

    }

  }



  Future<void> _pickTime() async {

    final picked = await showTimePicker(

      context: context,

      initialTime:

          _selectedTime ?? TimeOfDay.now(),

      builder: (context, child) {

        return Theme(

          data: Theme.of(context).copyWith(

            colorScheme: const ColorScheme.light(

              primary: AppColors.ink,

              onPrimary: Colors.white,

              surface: AppColors.surface,

              onSurface: AppColors.ink,

            ),

          ),

          child: child!,

        );

      },

    );



    if (picked != null) {

      setState(() {

        _selectedTime = picked;

      });

    }

  }



  List<String> _parseSkills() {

    return _skillsController.text

        .split(',')

        .map((skill) => skill.trim())

        .where((skill) => skill.isNotEmpty)

        .toSet()

        .toList();

  }



  Future<void> _submitJob() async {

    FocusScope.of(context).unfocus();



    final title =

        _titleController.text.trim();



    final description =

        _descriptionController.text.trim();



    final location =

        _locationController.text.trim();



    final skills = _parseSkills();



    final budget = double.tryParse(

      _budgetController.text.trim(),

    );



    if (title.isEmpty) {

      _showMessage(

        'Please enter a job title.',

      );

      return;

    }



    if (_selectedCategory == null) {

      _showMessage(

        'Please select a category.',

      );

      return;

    }



    if (skills.isEmpty) {

      _showMessage(

        'Please enter at least one required skill.',

      );

      return;

    }



    if (description.length < 20) {

      _showMessage(

        'Please write a little more about the job.',

      );

      return;

    }



    if (location.isEmpty) {

      _showMessage(

        'Please enter the job location.',

      );

      return;

    }



    if (_selectedDate == null) {

      _showMessage(

        'Please select a work date.',

      );

      return;

    }



    if (_selectedTime == null) {

      _showMessage(

        'Please select a start time.',

      );

      return;

    }



    if (budget == null || budget <= 0) {

      _showMessage(

        'Please enter a valid budget.',

      );

      return;

    }



    setState(() {

      _isSubmitting = true;

    });



    try {

      final formattedTime =

          '${_selectedTime!.hour.toString().padLeft(2, '0')}:'

          '${_selectedTime!.minute.toString().padLeft(2, '0')}';



      await _jobService.createJob(

        title: title,

        category: _selectedCategory!,

        requiredSkills: skills,

        description: description,

        location: location,

        workDate: _selectedDate!,

        startTime: formattedTime,

        durationHours: _durationHours,

        budget: budget,

      );



      if (!mounted) return;



      await _showSuccessDialog();



      if (!mounted) return;



      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error: $e',
      );

      debugPrint(
        'POST JOB ERROR: $e',
      );
    } finally {

      if (mounted) {

        setState(() {

          _isSubmitting = false;

        });

      }

    }

  }



  Future<void> _showSuccessDialog() async {

    await showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) {

        return Dialog(

          backgroundColor: AppColors.surface,

          shape: RoundedRectangleBorder(

            borderRadius:

                BorderRadius.circular(28),

          ),

          child: Padding(

            padding: const EdgeInsets.all(26),

            child: Column(

              mainAxisSize:

                  MainAxisSize.min,

              children: [

                Container(

                  width: 64,

                  height: 64,

                  decoration:

                      const BoxDecoration(

                    color:

                        AppColors.goldSoft,

                    shape:

                        BoxShape.circle,

                  ),

                  child: const Icon(

                    LucideIcons.circleCheck,

                    size: 30,

                    color:

                        AppColors.ink,

                  ),

                ),



                const SizedBox(height: 20),



                Text(

                  'Job posted',

                  style: AppText.heading(

                    size: 22,

                  ),

                ),



                const SizedBox(height: 8),



                Text(

                  'Your job is now available for matching with suitable workers.',

                  textAlign:

                      TextAlign.center,

                  style: AppText.body(

                    size: 13,

                  ),

                ),



                const SizedBox(height: 24),



                SizedBox(

                  width:

                      double.infinity,

                  child:

                      ElevatedButton(

                    onPressed: () {

                      Navigator.pop(

                        context,

                      );

                    },

                    style:

                        ElevatedButton.styleFrom(

                      elevation: 0,

                      backgroundColor:

                          AppColors.ink,

                      foregroundColor:

                          Colors.white,

                      padding:

                          const EdgeInsets.symmetric(

                        vertical: 15,

                      ),

                      shape:

                          RoundedRectangleBorder(

                        borderRadius:

                            BorderRadius.circular(

                          15,

                        ),

                      ),

                    ),

                    child: Text(

                      'Done',

                      style:

                          AppText.label(

                        color:

                            Colors.white,

                        size: 13,

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ),

        );

      },

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

        content: Text(message),

        behavior:

            SnackBarBehavior.floating,

      ),

    );

  }



  String _formattedDate() {

    if (_selectedDate == null) {

      return 'Select date';

    }



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



    return '${_selectedDate!.day} '

        '${months[_selectedDate!.month - 1]} '

        '${_selectedDate!.year}';

  }



  String _formattedTime() {

    if (_selectedTime == null) {

      return 'Select time';

    }



    return _selectedTime!

        .format(context);

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

              child:

                  SingleChildScrollView(

                padding:

                    const EdgeInsets.fromLTRB(

                  20,

                  26,

                  20,

                  40,

                ),

                child: Column(

                  crossAxisAlignment:

                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Job details',

                      style:

                          AppText.heading(

                        size: 20,

                      ),

                    ),



                    const SizedBox(

                      height: 6,

                    ),



                    Text(

                      'Give workers enough information to understand the work clearly.',

                      style:

                          AppText.body(

                        size: 12.5,

                      ),

                    ),



                    const SizedBox(

                      height: 24,

                    ),



                    const _PremiumLabel(

                      label:

                          'JOB TITLE',

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    _PremiumTextField(

                      controller:

                          _titleController,

                      hint:

                          'e.g. Repair bedroom ceiling fan',

                      icon:

                          LucideIcons.briefcase,

                    ),



                    const SizedBox(

                      height: 20,

                    ),



                    const _PremiumLabel(

                      label:

                          'CATEGORY',

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    _buildCategoryDropdown(),



                    const SizedBox(

                      height: 20,

                    ),



                    const _PremiumLabel(

                      label:

                          'REQUIRED SKILLS',

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    _PremiumTextField(

                      controller:

                          _skillsController,

                      hint:

                          'e.g. Electrical, Fan Repair',

                      icon:

                          LucideIcons.sparkles,

                    ),



                    const SizedBox(

                      height: 7,

                    ),



                    Text(

                      'Separate multiple skills with commas.',

                      style:

                          AppText.body(

                        size: 11,

                        color:

                            AppColors.muted,

                      ),

                    ),



                    const SizedBox(

                      height: 20,

                    ),



                    const _PremiumLabel(

                      label:

                          'DESCRIPTION',

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    _PremiumTextField(

                      controller:

                          _descriptionController,

                      hint:

                          'Describe the problem, expected work and any important details...',

                      icon:

                          LucideIcons.alignLeft,

                      maxLines: 5,

                    ),



                    const SizedBox(

                      height: 20,

                    ),



                    const _PremiumLabel(

                      label:

                          'LOCATION',

                    ),



                    const SizedBox(

                      height: 8,

                    ),



                    _PremiumTextField(

                      controller:

                          _locationController,

                      hint:

                          'e.g. Amberkhana, Sylhet',

                      icon:

                          LucideIcons.mapPin,

                    ),



                    const SizedBox(

                      height: 28,

                    ),



                    Text(

                      'Schedule',

                      style:

                          AppText.heading(

                        size: 20,

                      ),

                    ),



                    const SizedBox(

                      height: 14,

                    ),



                    Row(

                      children: [

                        Expanded(

                          child:

                              _SelectionCard(

                            icon:

                                LucideIcons.calendarDays,

                            label:

                                'DATE',

                            value:

                                _formattedDate(),

                            onTap:

                                _pickDate,

                          ),

                        ),



                        const SizedBox(

                          width: 12,

                        ),



                        Expanded(

                          child:

                              _SelectionCard(

                            icon:

                                LucideIcons.clock3,

                            label:

                                'START TIME',

                            value:

                                _formattedTime(),

                            onTap:

                                _pickTime,

                          ),

                        ),

                      ],

                    ),



                    const SizedBox(

                      height: 20,

                    ),



                    const _PremiumLabel(

                      label:

                          'ESTIMATED DURATION',

                    ),



                    const SizedBox(

                      height: 10,

                    ),



                    _buildDurationSelector(),



                    const SizedBox(

                      height: 28,

                    ),



                    Text(

                      'Budget',

                      style:

                          AppText.heading(

                        size: 20,

                      ),

                    ),



                    const SizedBox(

                      height: 14,

                    ),



                    _PremiumTextField(

                      controller:

                          _budgetController,

                      hint:

                          'Enter total budget',

                      icon:

                          LucideIcons.wallet,

                      keyboardType:

                          const TextInputType

                              .numberWithOptions(

                        decimal: true,

                      ),

                      prefixText:

                          '৳  ',

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

                            _isSubmitting

                                ? null

                                : _submitJob,

                        style:

                            ElevatedButton.styleFrom(

                          elevation: 0,

                          backgroundColor:

                              AppColors.ink,

                          foregroundColor:

                              Colors.white,

                          disabledBackgroundColor:

                              AppColors.inkSoft,

                          shape:

                              RoundedRectangleBorder(

                            borderRadius:

                                BorderRadius.circular(

                              18,

                            ),

                          ),

                        ),

                        child:

                            _isSubmitting

                                ? const SizedBox(

                                    width: 23,

                                    height: 23,

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

                                      Text(

                                        'Publish job',

                                        style:

                                            AppText.label(

                                          color:

                                              Colors.white,

                                          size: 13.5,

                                        ),

                                      ),

                                      const SizedBox(

                                        width: 10,

                                      ),

                                      const Icon(

                                        LucideIcons.arrowUpRight,

                                        size: 18,

                                      ),

                                    ],

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

        color: AppColors.background,

        border: Border(

          bottom: BorderSide(

            color: AppColors.line,

          ),

        ),

      ),

      child: Row(

        children: [

          Material(

            color:

                AppColors.surface,

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

              child: Container(

                width: 44,

                height: 44,

                alignment:

                    Alignment.center,

                decoration:

                    BoxDecoration(

                  border:

                      Border.all(

                    color:

                        AppColors.line,

                  ),

                  borderRadius:

                      BorderRadius.circular(

                    14,

                  ),

                ),

                child:

                    const Icon(

                  LucideIcons.arrowLeft,

                  size: 19,

                  color:

                      AppColors.ink,

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

                  'Post a job',

                  style:

                      AppText.heading(

                    size: 19,

                  ),

                ),

                Text(

                  'Create a new opportunity',

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

              'CLIENT',

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



  Widget _buildCategoryDropdown() {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 16,

      ),

      decoration: BoxDecoration(

        color: AppColors.surface,

        borderRadius:

            BorderRadius.circular(18),

        border: Border.all(

          color: AppColors.line,

        ),

      ),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<String>(

          value: _selectedCategory,

          isExpanded: true,

          dropdownColor:

              const Color(0xFFFFFEFB),

          borderRadius:

              BorderRadius.circular(18),

          icon: const Icon(

            LucideIcons.chevronDown,

            size: 18,

            color: AppColors.ink,

          ),

          hint: Row(

            children: [

              Container(

                width: 34,

                height: 34,

                decoration: BoxDecoration(

                  color:

                      AppColors.goldSoft,

                  borderRadius:

                      BorderRadius.circular(

                    10,

                  ),

                ),

                child: const Icon(

                  LucideIcons.layers3,

                  size: 16,

                  color:

                      AppColors.ink,

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Text(

                  'Choose a category',

                  overflow:

                      TextOverflow.ellipsis,

                  style: AppText.body(

                    size: 13.5,

                    color:

                        AppColors.inkSoft,

                    weight:

                        FontWeight.w600,

                  ),

                ),

              ),

            ],

          ),

          selectedItemBuilder: (context) {

            return _categories

                .map(

              (category) {

                return Row(

                  children: [

                    Container(

                      width: 34,

                      height: 34,

                      decoration:

                          BoxDecoration(

                        color:

                            AppColors.goldSoft,

                        borderRadius:

                            BorderRadius.circular(

                          10,

                        ),

                      ),

                      child: const Icon(

                        LucideIcons.layers3,

                        size: 16,

                        color:

                            AppColors.ink,

                      ),

                    ),

                    const SizedBox(

                      width: 12,

                    ),

                    Expanded(

                      child: Text(

                        category,

                        overflow:

                            TextOverflow.ellipsis,

                        style:

                            AppText.body(

                          color:

                              AppColors.ink,

                          size: 13.5,

                          weight:

                              FontWeight.w700,

                        ),

                      ),

                    ),

                  ],

                );

              },

            ).toList();

          },

          items: _categories

              .map(

            (category) {

              return DropdownMenuItem<String>(

                value: category,

                child: Container(

                  width: double.infinity,

                  padding:

                      const EdgeInsets.symmetric(

                    vertical: 10,

                  ),

                  child: Row(

                    children: [

                      Container(

                        width: 34,

                        height: 34,

                        decoration:

                            BoxDecoration(

                          color:

                              AppColors.goldSoft,

                          borderRadius:

                              BorderRadius.circular(

                            10,

                          ),

                        ),

                        child: const Icon(

                          LucideIcons.layers3,

                          size: 16,

                          color:

                              AppColors.ink,

                        ),

                      ),

                      const SizedBox(

                        width: 12,

                      ),

                      Expanded(

                        child: Text(

                          category,

                          style:

                              AppText.body(

                            color:

                                AppColors.ink,

                            size: 13.5,

                            weight:

                                FontWeight.w700,

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              );

            },

          ).toList(),

          onChanged: (value) {

            setState(() {

              _selectedCategory =

                  value;

            });

          },

        ),

      ),

    );

  }



  Widget _buildDurationSelector() {

    final durations = [

      1,

      2,

      3,

      4,

      6,

      8,

    ];



    return Wrap(

      spacing: 9,

      runSpacing: 9,

      children: durations.map(

        (hours) {

          final selected =

              _durationHours == hours;



          return InkWell(

            onTap: () {

              setState(() {

                _durationHours =

                    hours;

              });

            },

            borderRadius:

                BorderRadius.circular(14),

            child: AnimatedContainer(

              duration: const Duration(

                milliseconds: 180,

              ),

              padding:

                  const EdgeInsets.symmetric(

                horizontal: 16,

                vertical: 11,

              ),

              decoration:

                  BoxDecoration(

                color: selected

                    ? AppColors.ink

                    : AppColors.surface,

                borderRadius:

                    BorderRadius.circular(

                  14,

                ),

                border:

                    Border.all(

                  color: selected

                      ? AppColors.ink

                      : AppColors.line,

                ),

              ),

              child: Text(

                '$hours hr',

                style:

                    AppText.label(

                  size: 11,

                  color: selected

                      ? Colors.white

                      : AppColors.inkSoft,

                ),

              ),

            ),

          );

        },

      ).toList(),

    );

  }

}



class _PremiumLabel extends StatelessWidget {

  final String label;



  const _PremiumLabel({

    required this.label,

  });



  @override

  Widget build(

    BuildContext context,

  ) {

    return Text(

      label,

      style: GoogleFonts.manrope(

        color: AppColors.inkSoft,

        fontSize: 10,

        fontWeight:

            FontWeight.w700,

        letterSpacing: 1.2,

      ),

    );

  }

}



class _PremiumTextField

    extends StatelessWidget {

  final TextEditingController controller;



  final String hint;

  final IconData icon;



  final int maxLines;



  final TextInputType?

      keyboardType;



  final String? prefixText;



  const _PremiumTextField({

    required this.controller,

    required this.hint,

    required this.icon,

    this.maxLines = 1,

    this.keyboardType,

    this.prefixText,

  });



  @override

  Widget build(

    BuildContext context,

  ) {

    return TextField(

      controller: controller,

      maxLines: maxLines,

      keyboardType:

          keyboardType,

      style: AppText.body(

        color: AppColors.ink,

        size: 13.5,

      ),

      decoration:

          InputDecoration(

        hintText: hint,

        hintStyle:

            AppText.body(

          color:

              AppColors.muted,

          size: 13,

        ),

        prefixText:

            prefixText,

        prefixIcon:

            Padding(

          padding:

              EdgeInsets.only(

            bottom:

                maxLines > 1

                    ? 75

                    : 0,

          ),

          child: Icon(

            icon,

            size: 18,

            color:

                AppColors.muted,

          ),

        ),

        filled: true,

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

                AppColors.gold,

            width: 1.3,

          ),

        ),

      ),

    );

  }

}



class _SelectionCard

    extends StatelessWidget {

  final IconData icon;



  final String label;

  final String value;



  final VoidCallback onTap;



  const _SelectionCard({

    required this.icon,

    required this.label,

    required this.value,

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

        18,

      ),

      child: InkWell(

        onTap: onTap,

        borderRadius:

            BorderRadius.circular(

          18,

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

              18,

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

              Icon(

                icon,

                size: 19,

                color:

                    AppColors.gold,

              ),



              const SizedBox(

                height: 14,

              ),



              Text(

                label,

                style:

                    AppText.label(

                  size: 9,

                  color:

                      AppColors.muted,

                ),

              ),
              
              const SizedBox(

                height: 5,

              ),



              Text(

                value,

                maxLines: 1,

                overflow:

                    TextOverflow.ellipsis,

                style:

                    AppText.heading(

                  size: 13,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}