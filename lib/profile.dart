import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skedule3/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String _appVersion = "";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = "v${info.version}");
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        showSnackBar(context, 'User not logged in.', isError: true);
        return;
      }
      final data = await supabase
          .from('user_profile')
          .select()
          .eq('id', userId)
          .single();
      setState(() => _userProfile = UserProfile.fromJson(data));
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to load profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await supabase.auth.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (mounted) showSnackBar(context, 'Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editProfile() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final controller =
            TextEditingController(text: _userProfile?.name ?? "");
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, {"name": controller.text}),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null && result['name'] != null) {
      final newName = result['name']!.trim();
      if (newName.isEmpty) return;

      setState(() => _isLoading = true);
      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) throw Exception("User not logged in");

        await supabase
            .from('user_profile')
            .update({'name': newName})
            .eq('id', userId);

        setState(() {
          _userProfile = _userProfile?.copyWith(name: newName);
        });

        showSnackBar(context, 'Profile updated successfully.');
      } catch (e) {
        showSnackBar(context, 'Failed to update profile: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Could not load user profile.'))
              : Align(
                  alignment: const Alignment(0, -0.3),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                _userProfile!.name.isNotEmpty
                                    ? _userProfile!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 34, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: _editProfile,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_userProfile!.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_userProfile!.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          'Member since ${DateFormat('MMM yyyy').format(_userProfile!.createdAt)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 28),
                        _buildSettingCard(
                          context,
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          trailing: Switch(
                            value: isDarkMode,
                            onChanged: themeProvider.toggleTheme,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          context,
                          icon: Icons.privacy_tip,
                          label: 'Terms & Privacy',
                          onTap: () =>
                              Navigator.pushNamed(context, '/privacy-policy'),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          context,
                          icon: Icons.logout,
                          label: 'Log Out',
                          onTap: _signOut,
                          iconColor: Colors.redAccent,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _appVersion,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

extension on UserProfile {
  UserProfile copyWith({String? name}) => UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
      );
}
