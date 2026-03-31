import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data from current user
    Future.microtask(() {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final success = await ref.read(userRepositoryProvider).updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
      );

      if (success) {
        ref.invalidate(currentUserProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              Tab(icon: Icon(Icons.palette_outlined), text: 'Appearance'),
              Tab(icon: Icon(Icons.security_outlined), text: 'Security'),
            ],
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(),
            _buildAppearanceTab(),
            _buildSecurityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: AppTheme.headingStyle),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Display Preferences', style: AppTheme.headingStyle),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.brightness_medium_outlined, color: AppTheme.primaryTeal),
          title: const Text('Theme Mode'),
          subtitle: const Text('System Default'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        const SizedBox(height: 24),
        const Text('Backend Configuration', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, child) {
          final settings = ref.watch(currencySettingsProvider);
          return settings.when(
            data: (conf) => ListTile(
              leading: const Icon(Icons.attach_money, color: AppTheme.primaryTeal),
              title: const Text('System Currency'),
              subtitle: Text('${conf?.name} (${conf?.symbol})'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error loading settings: $e'),
          );
        }),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuOption(Icons.lock_outline, 'Change Password', 'Update your login protection'),
        _buildMenuOption(Icons.fingerprint, 'Biometric Login', 'Use face or fingerprint ID'),
        _buildMenuOption(Icons.devices, 'Managed Devices', 'Devices logged into your account'),
      ],
    );
  }

  Widget _buildMenuOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
