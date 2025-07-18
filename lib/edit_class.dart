import 'package:flutter/material.dart';
import 'package:skedule3/main.dart';
import 'dart:developer';
import 'dart:async'; // Import for Timer

class AddEditClassPage extends StatefulWidget {
  final Class? classToEdit;

  const AddEditClassPage({super.key, this.classToEdit});

  @override
  State<AddEditClassPage> createState() => _AddEditClassPageState();
}

class _AddEditClassPageState extends State<AddEditClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _classTypeController = TextEditingController();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _lecturerController = TextEditingController();

  List<Subject> _subjects = [];
  String? _selectedSubjectId;

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedColor = '#42A5F5';
  bool _setReminder = true;
  bool _isLoading = false;

  // New state variables for button feedback
  bool _isSuccess = false;
  Timer? _successTimer;

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<String> _availableColors = [
    '#42A5F5', '#66BB6A', '#FFA726', '#EF5350', '#AB47BC', '#26A69A'
  ];

  @override
  void initState() {
    super.initState();
    log('AddEditClassPage: initState called.');
    _loadSubjects();
    if (widget.classToEdit != null) {
      log('AddEditClassPage: Editing existing class: ${widget.classToEdit!.subjectId}');
      _selectedSubjectId = widget.classToEdit!.subjectId;
      _classTypeController.text = widget.classToEdit!.classType;
      _buildingController.text = widget.classToEdit!.building;
      _roomController.text = widget.classToEdit!.room;
      _lecturerController.text = widget.classToEdit!.lecturer;
      _selectedDay = widget.classToEdit!.day;
      _startTime = widget.classToEdit!.startTime;
      _endTime = widget.classToEdit!.endTime;
      _selectedColor = widget.classToEdit!.colorHex;
      _setReminder = widget.classToEdit!.reminder;
    } else {
      log('AddEditClassPage: Adding new class.');
    }
  }

  @override
  void dispose() {
    _classTypeController.dispose();
    _buildingController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    _successTimer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      log('AddEditClassPage: No user ID, cannot load subjects.');
      return;
    }

    try {
      final response = await supabase
          .from('subject')
          .select()
          .eq('userId', userId)
          .order('subject_title');

      setState(() {
        _subjects = (response as List).map((json) => Subject.fromJson(json)).toList();
        log('AddEditClassPage: Loaded ${_subjects.length} subjects for user $userId.');
      });
    } catch (e) {
      log('AddEditClassPage: Error loading subjects: $e', error: e);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        log('AddEditClassPage: Time updated. Start: $_startTime, End: $_endTime');
      });
    }
  }

  void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) {
      log('AddEditClassPage: Form validation failed.');
      return;
    }

    if (_selectedSubjectId == null || _selectedDay == null || _startTime == null || _endTime == null) {
      showSnackBar(context, 'Please complete all fields.', isError: true);
      log('AddEditClassPage: Missing required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false; // Reset success state
    });
    _successTimer?.cancel(); // Cancel any previous timer

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      showSnackBar(context, 'User not logged in.', isError: true); // Corrected 'isStates' to 'isError'
      setState(() => _isLoading = false);
      log('AddEditClassPage: User not logged in, cannot save.');
      return;
    }

    final classData = {
      'subject_id': _selectedSubjectId,
      'class_type': _classTypeController.text.trim(),
      'building': _buildingController.text.trim(),
      'room': _roomController.text.trim(),
      'lecturer': _lecturerController.text.trim(),
      'day': _selectedDay,
      'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
      'color_hex': _selectedColor,
      'reminder': _setReminder,
      'id': userId,
    };

    try {
      if (widget.classToEdit == null) {
        await supabase.from('class').insert(classData);
        showSnackBar(context, 'Class added successfully!');
        log('AddEditClassPage: Class added successfully.');
      } else {
        await supabase
            .from('class')
            .update(classData)
            .eq('class_id', widget.classToEdit!.classId);
        showSnackBar(context, 'Class updated successfully!');
        log('AddEditClassPage: Class updated successfully for class_id: ${widget.classToEdit!.classId}');
      }

      // Set success state and start timer to revert
      setState(() {
        _isSuccess = true;
      });
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isSuccess = false;
          });
          // Pop the page after the color feedback is shown
          Navigator.of(context).pop(true);
        }
      });

    } catch (e) {
      showSnackBar(context, 'Failed to save class: $e', isError: true);
      log('AddEditClassPage: Failed to save class: $e', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        log('AddEditClassPage: _saveClass finished, isLoading = false.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    log('AddEditClassPage: build called.');
    // Determine the button's background color based on _isSuccess
    final Color resolvedBackgroundColor = _isSuccess
        ? Colors.green
        : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? Theme.of(context).colorScheme.primary;

    // Determine the button's foreground color (text/icon)
    final Color resolvedForegroundColor = _isSuccess
        ? Colors.white
        : Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classToEdit == null ? 'Add Class' : 'Edit Class'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- Class Information Section ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Information',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSubjectId,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              prefixIcon: Icon(Icons.book_outlined),
                              isDense: true,
                            ),
                            items: _subjects.map((subject) {
                              return DropdownMenuItem<String>(
                                value: subject.subjectId,
                                child: Text(
                                  '${subject.subjectId} - ${subject.subjectTitle}',
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedSubjectId = value),
                            validator: (value) => value == null ? 'Please select a subject' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _classTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Class Type - Lecture, Lab, Tutorial',
                              prefixIcon: Icon(Icons.type_specimen_outlined),
                              isDense: true,
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter class type' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lecturerController,
                            decoration: const InputDecoration(
                              labelText: 'Lecturer',
                              prefixIcon: Icon(Icons.person_outline),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Location Details Section ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Details',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _buildingController,
                            decoration: const InputDecoration(
                              labelText: 'Building',
                              prefixIcon: Icon(Icons.location_city_outlined),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _roomController,
                            decoration: const InputDecoration(
                              labelText: 'Room',
                              prefixIcon: Icon(Icons.door_front_door_outlined),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Schedule & Time Section ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule & Time',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDay,
                            decoration: const InputDecoration(
                              labelText: 'Day',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              isDense: true,
                            ),
                            items: _daysOfWeek.map((day) {
                              return DropdownMenuItem(value: day, child: Text(day));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedDay = value),
                            validator: (value) => value == null ? 'Please select a day' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell( // Use InkWell for tap feedback
                                  onTap: () => _selectTime(context, true),
                                  child: InputDecorator( // Makes it look like a TextFormField
                                    decoration: InputDecoration(
                                      labelText: 'Start Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                      isDense: true,
                                    ),
                                    child: Text(
                                      _startTime == null
                                          ? 'Select Time'
                                          : _startTime!.format(context),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell( // Use InkWell for tap feedback
                                  onTap: () => _selectTime(context, false),
                                  child: InputDecorator( // Makes it look like a TextFormField
                                    decoration: InputDecoration(
                                      labelText: 'End Time',
                                      prefixIcon: const Icon(Icons.access_time),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                      isDense: true,
                                    ),
                                    child: Text(
                                      _endTime == null
                                          ? 'Select Time'
                                          : _endTime!.format(context),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Display & Reminders Section ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Display & Reminders',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose a display color:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap( // Use Wrap for better responsiveness on smaller screens
                            spacing: 8.0, // horizontal spacing
                            runSpacing: 8.0, // vertical spacing
                            children: _availableColors.map((colorHex) {
                              final isSelected = _selectedColor == colorHex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = colorHex),
                                child: Container(
                                  width: 36, // Increased size
                                  height: 36, // Increased size
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(int.parse(colorHex.replaceFirst('#', '0xff'))),
                                    border: Border.all(
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, // Highlight with primary color
                                        width: 3), // Thicker border for selection
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check, color: Colors.white, size: 20) // Checkmark when selected
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _setReminder,
                            onChanged: (value) => setState(() => _setReminder = value),
                            title: const Text('Set Reminder'),
                            secondary: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Save Button ---
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveClass,
                            child: Text(widget.classToEdit == null ? 'Add Class' : 'Update Class'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              // Conditional background color and foreground color
                              backgroundColor: resolvedBackgroundColor,
                              foregroundColor: resolvedForegroundColor,
                              // Removed overlayColor
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
