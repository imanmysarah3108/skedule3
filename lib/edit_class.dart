// --- Add/Edit Class Screen ---
import 'package:flutter/material.dart';
import 'package:skedule3/main.dart';

class AddEditClassPage extends StatefulWidget {
  final Class? classToEdit; // Optional, for editing existing class
  const AddEditClassPage({super.key, this.classToEdit});

  @override
  State<AddEditClassPage> createState() => _AddEditClassPageState();
}

class _AddEditClassPageState extends State<AddEditClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectIdController = TextEditingController();
  final _classTypeController = TextEditingController();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _lecturerController = TextEditingController();

  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedColor = '#42A5F5'; // Default blue color
  bool _setReminder = true;
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> _availableColors = [
    '#42A5F5', // Blue
    '#66BB6A', // Green
    '#FFA726', // Orange
    '#EF5350', // Red
    '#AB47BC', // Purple
    '#26A69A', // Teal
  ];

  @override
  void initState() {
    super.initState();
    if (widget.classToEdit != null) {
      _subjectIdController.text = widget.classToEdit!.subjectId;
      _classTypeController.text = widget.classToEdit!.classType;
      _buildingController.text = widget.classToEdit!.building;
      _roomController.text = widget.classToEdit!.room;
      _lecturerController.text = widget.classToEdit!.lecturer;
      _selectedDay = widget.classToEdit!.day;
      _startTime = widget.classToEdit!.startTime;
      _endTime = widget.classToEdit!.endTime;
      _selectedColor = widget.classToEdit!.colorHex;
      _setReminder = widget.classToEdit!.reminder;
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDay == null || _startTime == null || _endTime == null) {
      showSnackBar(context, 'Please select day, start time, and end time.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      showSnackBar(context, 'User not logged in.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final classData = {
        'subject_id': _subjectIdController.text.trim(),
        'class_type': _classTypeController.text.trim(),
        'building': _buildingController.text.trim(),
        'room': _roomController.text.trim(),
        'lecturer': _lecturerController.text.trim(),
        'day': _selectedDay,
        'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
        'color_hex': _selectedColor,
        'reminder': _setReminder,
        'id': userId, // Link class to user
      };

      if (widget.classToEdit == null) {
        // Add new class
        await supabase.from('class').insert(classData);
        if (mounted) {
          showSnackBar(context, 'Class added successfully!');
          Navigator.of(context).pop();
        }
      } else {
        // Update existing class
        await supabase
            .from('class')
            .update(classData)
            .eq('class_id', widget.classToEdit!.classId);
        if (mounted) {
          showSnackBar(context, 'Class updated successfully!');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to save class: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classToEdit == null ? 'Add New Class' : 'Edit Class'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectIdController,
                decoration: const InputDecoration(labelText: 'Subject ID (e.g., CSC101)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subject ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classTypeController,
                decoration: const InputDecoration(labelText: 'Class Type (e.g., Lecture, Tutorial)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(labelText: 'Building'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter building';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(labelText: 'Lecturer Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter lecturer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: _daysOfWeek.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDay = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a day';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: const Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        child: Text(
                          _startTime == null ? 'Select Time' : _startTime!.format(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: const Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        child: Text(
                          _endTime == null ? 'Select Time' : _endTime!.format(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Class Color: ', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableColors.map((hexColor) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = hexColor;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(int.parse(hexColor.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: _selectedColor == hexColor
                                  ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set Reminder:', style: Theme.of(context).textTheme.titleMedium),
                  Switch(
                    value: _setReminder,
                    onChanged: (bool value) {
                      setState(() {
                        _setReminder = value;
                      });
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 48, 
                          child: ElevatedButton(
                            onPressed: _saveClass,
                            child: Text(widget.classToEdit == null ? 'Add Class' : 'Update Class'),
                          ),
                        ),
                    const SizedBox(height: 24),
                ],
              ), 
            ],
          ),
        ),
      ),
    );
  }
}