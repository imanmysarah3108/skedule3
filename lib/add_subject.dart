
import 'package:flutter/material.dart';
import 'package:skedule3/main.dart'; 


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

  @override
  void dispose() {
   
    _subjectIdController.dispose();
    _subjectTitleController.dispose();
    super.dispose();
  }

  
  Future<void> _submitSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final subjectId = _subjectIdController.text.trim();
      final subjectTitle = _subjectTitleController.text.trim();
      
      await supabase.from('subject').insert({
        'subject_id': subjectId,
        'subject_title': subjectTitle,
        'id': supabase.auth.currentUser?.id,

      });

      if (mounted) {
        showSnackBar(context, 'Subject added successfully!');
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Subject'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
