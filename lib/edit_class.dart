import 'package:flutter/material.dart';
import 'package:skedule3/main.dart';
import 'dart:developer'; // Import for log function

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

  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedColor = '#42A5F5';
  bool _setReminder = true;
  bool _isLoading = false;

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
          .order('subject_title');

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
        log('AddEditClassPage: Loaded ${_subjects.length} subjects.');
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

    setState(() => _isLoading = true);
    log('AddEditClassPage: _saveClass started, isLoading = true.');

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      showSnackBar(context, 'User not logged in.', isError: true);
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
        // Add new class
        await supabase.from('class').insert(classData);
        showSnackBar(context, 'Class added successfully!');
        log('AddEditClassPage: Class added successfully.');
      } else {
        // Update existing class
        // IMPORTANT: Ensure 'class_id' is the primary key for updates
        await supabase
            .from('class')
            .update(classData)
            .eq('class_id', widget.classToEdit!.classId); // Use classId for update
        showSnackBar(context, 'Class updated successfully!');
        log('AddEditClassPage: Class updated successfully for class_id: ${widget.classToEdit!.classId}');
      }
      if (mounted) {
        log('AddEditClassPage: Popping with true result.');
        Navigator.of(context).pop(true); // Pop with 'true' on success
      }
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
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.book_outlined),
                      isDense: true,
                    ),
                    items: _subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject['subject_id'],
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${subject['subject_id']} - ${subject['subject_title']}',
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
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
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lecturerController,
                    decoration: const InputDecoration(
                      labelText: 'Lecturer',
                      prefixIcon: Icon(Icons.person_outline),
                      isDense: true,
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
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(
                            _startTime == null
                                ? 'Select Start Time'
                                : 'Start: ${_startTime!.format(context)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text(
                            _endTime == null
                                ? 'Select End Time'
                                : 'End: ${_endTime!.format(context)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: _availableColors.map((colorHex) {
                      final isSelected = _selectedColor == colorHex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorHex),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent, width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Color(int.parse(colorHex.replaceFirst('#', '0xff'))),
                            radius: 14,
                          ),
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
                  ),
                  const SizedBox(height: 24),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveClass,
                            child: Text(widget.classToEdit == null ? 'Add Class' : 'Update Class'),
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