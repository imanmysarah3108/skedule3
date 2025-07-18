import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skedule3/main.dart'; // For supabase instance and showSnackBar

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes for hover-like effect
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add listeners to focus nodes to rebuild widget on focus change
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (mounted) {
          showSnackBar(context, 'Logged in successfully!');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // This else block might be hit if the user is not confirmed yet (e.g., email verification pending)
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials or verify your email.';
        });
        if (mounted) {
          showSnackBar(context, _errorMessage!, isError: true);
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) {
        showSnackBar(context, 'Login failed: ${e.message}', isError: true);
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
        title: const Text('Login'),
        automaticallyImplyLeading: false, // Ensure no back arrow on login
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) "Welcome Back" title
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary, // Purple color (primary)
                    ),
              ),
              const SizedBox(height: 8),
              // 2) "Login to your account" subtitle
              Text(
                'Login to your account',
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
                    // 3) Email and Password sections with pop-up/hover effect
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

                    // 4) Login button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity, // Make button stretch
                            height: 56, // Make button box big a little bit
                            child: ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary, // Base color purple
                                foregroundColor: Colors.white, // Text color white
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Match card roundedness
                                ),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5) "Don't have an account?" text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey, // Grey color
                        ),
                  ),
                  // 6) "Sign up" with line and blue text color
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/signup');
                    },
                    child: Text(
                      'Sign Up',
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
