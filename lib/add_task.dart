import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skedule3/main.dart';
import 'dart:async'; // Import for Timer

class AddTaskPage extends StatefulWidget {
  final Assignment? taskToEdit;
  const AddTaskPage({super.key, this.taskToEdit});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubjectId;

  DateTime? _dueDate;
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  List<Map<String, String>> _userSubjects = [];
  bool _isLoadingSubjects = true;

  final List<String> _priorityLevels = ['high', 'medium', 'low'];

  // New state variables for button feedback
  bool _isSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.assignmentTitle;
      _descriptionController.text = widget.taskToEdit!.desc;
      _selectedSubjectId = widget.taskToEdit!.subjectId;
      _dueDate = widget.taskToEdit!.dueDate;
      _selectedPriority = widget.taskToEdit!.priority;
    }
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _successTimer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        showSnackBar(context, 'User not logged in. Cannot load subjects.', isError: true);
        setState(() {
          _isLoadingSubjects = false;
        });
      }
      return;
    }

    try {
      final response = await supabase
          .from('subject')
          .select('subject_id, subject_title')
          .eq('userId', userId)
          .order('subject_title');

      setState(() {
        _userSubjects = (response as List)
            .map((item) => {
                  'subject_id': item['subject_id'].toString(),
                  'subject_title': item['subject_title'].toString(),
                })
            .toList();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to load subjects: $e', isError: true);
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      showSnackBar(context, 'Please select a due date.', isError: true);
      return;
    }
    if (_selectedSubjectId == null) {
      showSnackBar(context, 'Please select a subject.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false; // Reset success state
    });
    _successTimer?.cancel(); // Cancel any previous timer

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      showSnackBar(context, 'User not logged in.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final taskData = {
        'assignment_title': _titleController.text.trim(),
        'desc': _descriptionController.text.trim(),
        'subject_id': _selectedSubjectId!,
        'due_date': _dueDate!.toIso8601String().split('T')[0],
        'id': userId,
        'priority': _selectedPriority,
        'is_completed': widget.taskToEdit?.isCompleted ?? false,
      };

      if (widget.taskToEdit == null) {
        await supabase.from('assignment').insert(taskData);
        if (mounted) {
          showSnackBar(context, 'Task added successfully!');
        }
      } else {
        await supabase
            .from('assignment')
            .update(taskData)
            .eq('assignment_id', widget.taskToEdit!.assignmentId);
        if (mounted) {
          showSnackBar(context, 'Task updated successfully!');
        }
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
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to save task: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.taskToEdit == null ? 'Add New Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Adjusted padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards
            children: [
              // --- Task Details Section ---
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
                        'Task Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          prefixIcon: Icon(Icons.assignment_outlined), // Added icon
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter task title' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(
                              labelText: 'Description (Optional)',
                              prefixIcon: Icon(Icons.description_outlined), // Added icon
                            ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // --- Assignment Specifics Section ---
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
                        'Assignment Specifics',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _isLoadingSubjects
                          ? const Center(child: CircularProgressIndicator())
                          : _userSubjects.isEmpty
                              ? const Text('No subjects available for this user. Please add one first.')
                              : DropdownButtonFormField<String>(
                                  value: _selectedSubjectId,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                    prefixIcon: Icon(Icons.book_outlined),
                                  ),
                                  hint: const Text('Choose a subject'),
                                  items: _userSubjects.map((subject) {
                                    final id = subject['subject_id'] ?? '';
                                    final title = subject['subject_title'] ?? '';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text('$id - $title'),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedSubjectId = value),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'Please select a subject'
                                      : null,
                                ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDueDate(context),
                        child: InputDecorator( // Use InputDecorator for consistent styling
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: const Icon(Icons.date_range_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                          ),
                          child: Text(
                            _dueDate == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy').format(_dueDate!),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.priority_high_outlined),
                        ),
                        items: _priorityLevels.map((String priority) {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: Text(priority.capitalize()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPriority = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _saveTask,
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
                          child: Text(widget.taskToEdit == null
                              ? 'Add Task'
                              : 'Update Task'),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
