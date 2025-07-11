import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skedule3/main.dart'; 

class Assignment {
  final String assignmentId; 
  final String desc; 
  final String subjectId; 
  final DateTime dueDate; 
  final String id; 
  final String assignmentTitle; 
  final bool isCompleted; 
  final String priority; 

  Assignment({
    required this.assignmentId,
    required this.desc,
    required this.subjectId,
    required this.dueDate,
    required this.id,
    required this.assignmentTitle,
    required this.isCompleted,
    required this.priority,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: json['assignment_id'] as String,
      desc: json['desc'] as String,
      subjectId: json['subject_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      id: json['id'] as String,
      assignmentTitle: json['assignment_title'] as String,
      isCompleted: json['is_completed'] as bool,
      priority: json['priority'] as String,
    );
  }
}

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

    setState(() => _isLoading = true);

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
          Navigator.of(context).pop();
        }
      } else {
        await supabase
            .from('assignment')
            .update(taskData)
            .eq('assignment_id', widget.taskToEdit!.assignmentId); 
        if (mounted) {
          showSnackBar(context, 'Task updated successfully!');
          Navigator.of(context).pop();
        }
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Add New Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter task title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _isLoadingSubjects
                  ? const Center(child: CircularProgressIndicator())
                  : _userSubjects.isEmpty
                      ? const Text('No subjects available for this user.')
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
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: const Icon(Icons.date_range_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
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
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _saveTask,
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