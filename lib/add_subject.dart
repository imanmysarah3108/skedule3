// add_subject.dart
import 'package:flutter/material.dart';
import 'package:skedule3/main.dart'; // Assuming supabase client and showSnackBar are defined here

/// A page for adding a new subject to the database.
class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  // Global key for the form, used for validation.
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for the input fields.
  final _subjectIdController = TextEditingController();
  final _subjectTitleController = TextEditingController();

  // State variable to manage loading indicator on the button.
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose controllers to free up resources when the widget is removed from the tree.
    _subjectIdController.dispose();
    _subjectTitleController.dispose();
    super.dispose();
  }

  /// Handles the submission of the new subject form.
  ///
  /// Validates the form, attempts to insert the subject into the Supabase
  /// 'subject' table, and provides user feedback via snackbars.
  Future<void> _submitSubject() async {
    // Validate all fields in the form. If any validator returns a non-null string,
    // the form is invalid.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state to true to show a progress indicator on the button.
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the trimmed text from the controllers.
      final subjectId = _subjectIdController.text.trim();
      final subjectTitle = _subjectTitleController.text.trim();
      

      // Insert the new subject data into the 'subject' table in Supabase.
      // The 'subject_id' and 'subject_title' are based on your database schema.
      await supabase.from('subject').insert({
        'subject_id': subjectId,
        'subject_title': subjectTitle,
      });

      // Check if the widget is still mounted before performing UI operations.
      if (mounted) {
        showSnackBar(context, 'Subject added successfully!');
        // Pop the current page from the navigation stack, returning to the previous one.
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle any errors that occur during the Supabase insertion.
      if (mounted) {
        String errorMessage = 'Failed to add subject.';
        // Check for specific PostgreSQL error code for unique violation (23505).
        // This occurs if a subject with the same subject_id already exists.
        if (e.toString().contains('23505')) {
          errorMessage = 'Subject already exists. Please choose a different one.';
        } else {
          // For any other error, display the generic error message.
          errorMessage = 'Failed to add subject: $e';
        }
        showSnackBar(context, errorMessage, isError: true);
      }
    } finally {
      // Ensure loading state is reset to false, regardless of success or failure.
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
          key: _formKey, // Assign the GlobalKey to the Form for validation.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally.
            children: [
              // Text field for Subject ID.
              TextFormField(
                controller: _subjectIdController,
                decoration: InputDecoration(
                  labelText: 'Subject ID (e.g., LCC500)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined), // Icon for ID/key.
                ),
                validator: (value) {
                  // Validator to ensure the Subject ID is not empty.
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Subject ID';
                  }
                  return null; // Return null if the input is valid.
                },
              ),
              const SizedBox(height: 16), // Spacer between text fields.
              // Text field for Subject Title.
              TextFormField(
                controller: _subjectTitleController,
                decoration: InputDecoration(
                  labelText: 'Subject Title (e.g., Introduction to Computer Science)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title), // Icon for title.
                ),
                validator: (value) {
                  // Validator to ensure the Subject Title is not empty.
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Subject Title';
                  }
                  return null; // Return null if the input is valid.
                },
              ),
              const SizedBox(height: 32), // Spacer before the button.
              // Elevated button to submit the form.
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitSubject, // Disable button when loading.
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save), // Show save icon when not loading.
                label: Text(_isLoading ? 'Adding Subject...' : 'Add Subject'), // Button text changes based on loading state.
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners for the button.
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
