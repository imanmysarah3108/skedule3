import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skedule3/main.dart'; // For supabase instance and showSnackBar

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes for hover-like effect
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add listeners to focus nodes to rebuild widget on focus change
    _nameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      // Rebuilds the widget to update elevation/shadow based on focus
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // --- CRITICAL: Create user profile entry after successful signup ---
        // This addresses the "Key (userId) not present in user_profile" error
        await supabase.from('user_profile').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'name': _nameController.text.trim(), // Use the name from the form
          'created_at': DateTime.now().toIso8601String(),
        });
        // --- End of critical fix ---

        if (mounted) {
          showSnackBar(context, 'Account created successfully! Please check your email for verification if required.');
          // Navigate to home or login based on your app's flow after signup
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // This else block might be hit if email verification is required and
        // the user isn't immediately signed in. Supabase's signUp often
        // sends a verification email and doesn't sign in until confirmed.
        if (mounted) {
          showSnackBar(context, 'Registration successful! Please check your email to verify your account.', isError: false);
          Navigator.of(context).pushReplacementNamed('/login'); // Go back to login to await verification
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) {
        showSnackBar(context, 'Sign up failed: ${e.message}', isError: true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
      if (mounted) {
        showSnackBar(context, 'An unexpected error occurred: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to build an elevated input card
  Widget _buildElevatedInputCard({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required FocusNode focusNode,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final bool isFocused = focusNode.hasFocus;
    return Card(
      elevation: isFocused ? 8 : 4, // Increased elevation on focus
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFocused ? Theme.of(context).colorScheme.primary : Colors.transparent, // Highlight border on focus
          width: 2,
        ),
      ),
      shadowColor: isFocused ? Theme.of(context).colorScheme.primary.withOpacity(0.4) : Theme.of(context).shadowColor.withOpacity(0.1), // Dynamic shadow color
      margin: const EdgeInsets.only(bottom: 16), // Consistent spacing between input cards
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding inside the card
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: Icon(icon),
            border: InputBorder.none, // Remove default border as Card provides it
            contentPadding: const EdgeInsets.symmetric(vertical: 12), // Adjust content padding
          ),
          validator: validator,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        automaticallyImplyLeading: false, // Ensure no back arrow on signup
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) "Register" title with "Create your new account" subtitle
              Text(
                'Register',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary, // Purple color
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your new account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey, // Grey color
                    ),
              ),
              const SizedBox(height: 48), // Increased space

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 2) Name, Email, Password sections with pop-up/hover effect
                    _buildElevatedInputCard(
                      controller: _nameController,
                      labelText: 'Username',
                      icon: Icons.person_outline,
                      focusNode: _nameFocusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    _buildElevatedInputCard(
                      controller: _emailController,
                      labelText: 'Email',
                      icon: Icons.email_outlined,
                      focusNode: _emailFocusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _buildElevatedInputCard(
                      controller: _passwordController,
                      labelText: 'Password',
                      icon: Icons.lock_outline,
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error message display
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // 3) Sign Up button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity, // Make button stretch
                            height: 56, // Make button box big a little bit
                            child: ElevatedButton(
                              onPressed: _signUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Match card roundedness
                                ),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4) "Already have account?" text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey, // Grey color
                        ),
                  ),
                  // 5) "Log in" with line and blue text color
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Log in',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary, // Blue color (primary color)
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline, // Underline
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
