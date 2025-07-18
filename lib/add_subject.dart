import 'package:flutter/material.dart';
import 'package:skedule3/main.dart';
import 'dart:async'; 

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectIdController = TextEditingController();
  final _subjectTitleController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _subjects = [];

  
  bool _isSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _subjectIdController.dispose();
    _subjectTitleController.dispose();
    _successTimer?.cancel(); 
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('subject')
          .select()
          .eq('userId', userId)
          .order('subject_title', ascending: true);

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading subjects: $e', isError: true);
      }
    }
  }

  Future<void> _submitSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false; 
    });
    _successTimer?.cancel(); 

    try {
      final subjectId = _subjectIdController.text.trim();
      final subjectTitle = _subjectTitleController.text.trim();
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('subject').insert({
        'subject_id': subjectId,
        'subject_title': subjectTitle,
        'userId': userId,
      });

      if (mounted) {
        showSnackBar(context, 'Subject added successfully!');
        _subjectIdController.clear();
        _subjectTitleController.clear();
        await _fetchSubjects(); 

        setState(() {
          _isSuccess = true;
        });
        _successTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to add subject.';
        if (e.toString().contains('23505')) {
          errorMessage = 'Subject already exists. Please choose a different one.';
        } else {
          errorMessage = 'Failed to add subject: $e';
        }
        showSnackBar(context, errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSubject(String subjectId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete subject "$subjectId"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await supabase.from('subject').delete().eq('subject_id', subjectId);
        if (mounted) {
          showSnackBar(context, 'Subject deleted!');
          await _fetchSubjects(); 
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Failed to delete subject: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final Color resolvedBackgroundColor = _isSuccess
        ? Colors.green
        : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? Theme.of(context).colorScheme.primary;

    final Color resolvedForegroundColor = _isSuccess
        ? Colors.white
        : Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Theme.of(context).colorScheme.onPrimary;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Subject'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Card(
              elevation: 4, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
              ),
              margin: const EdgeInsets.only(bottom: 24), 
              child: Padding(
                padding: const EdgeInsets.all(20.0), 
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Subject Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectIdController,
                        decoration: InputDecoration(
                          labelText: 'Subject ID (e.g., LCC500)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a Subject ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectTitleController,
                        decoration: InputDecoration(
                          labelText: 'Subject Title (e.g., Introduction to Computer Science)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a Subject Title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitSubject,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Adding Subject...' : 'Add Subject'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: resolvedBackgroundColor,
                          foregroundColor: resolvedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Your Subjects:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            if (_subjects.isEmpty)
              const Text('No subjects added yet.')
            else
              ListView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        subject['subject_title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        subject['subject_id'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSubject(subject['subject_id']),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
