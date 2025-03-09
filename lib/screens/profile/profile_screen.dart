import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/features/auth/auth_page.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/services/shared_preferences_service.dart';
import 'package:glam_connect/utils/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _signOut() async {
    // Clear shared preferences
    final prefsService = await ref.read(sharedPreferencesServiceFutureProvider.future);
    await prefsService.clearAll();

    // Reset main provider state
    ref.read(mainProvider.notifier).logout();

    if (mounted) {
      // Navigate to auth page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Personal Profile',
            onTap: () {
              // TODO: Navigate to personal profile screen
            },
          ),
          _buildSettingsItem(
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            onTap: () {
              // TODO: Navigate to contact us screen
            },
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About App',
            onTap: () {
              // TODO: Navigate to about app screen
            },
          ),
          _buildSettingsItem(
            icon: Icons.gavel_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              // TODO: Navigate to terms screen
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // TODO: Navigate to privacy policy screen
            },
          ),
          _buildNotificationItem(),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: _signOut,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColor.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1, indent: 70, endIndent: 20),
      ],
    );
  }

  Widget _buildNotificationItem() {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(Icons.notifications_outlined, color: AppColor.primary),
          title: const Text('Notifications'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
      ],
    );
  }
}
