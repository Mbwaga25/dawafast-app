import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/auth/data/models/user_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _genderController = TextEditingController();
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _pharmacyLabNameController = TextEditingController();
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
        
        if (user.patientProfile != null) {
          _bloodTypeController.text = user.patientProfile?.bloodType ?? '';
          _genderController.text = user.patientProfile?.gender ?? '';
          _locationController.text = user.patientProfile?.location ?? '';
        }
        
        if (user.doctorProfile != null) {
          _specialtyController.text = user.doctorProfile?.specialty ?? '';
        }
        
        if (user.pharmacistProfile != null) {
          _pharmacyLabNameController.text = user.pharmacistProfile?.pharmacyName ?? '';
        }
        
        if (user.labProfile != null) {
          _pharmacyLabNameController.text = user.labProfile?.labName ?? '';
        }
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
        bloodType: _bloodTypeController.text.isNotEmpty ? _bloodTypeController.text : null,
        gender: _genderController.text.isNotEmpty ? _genderController.text : null,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        specialty: _specialtyController.text.isNotEmpty ? _specialtyController.text : null,
        licenseNumber: _licenseNumberController.text.isNotEmpty ? _licenseNumberController.text : null,
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
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == 'DOCTOR';

    final tabs = [
      const Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
      if (isDoctor) const Tab(icon: Icon(Icons.work_outline), text: 'Professional'),
      const Tab(icon: Icon(Icons.palette_outlined), text: 'Appearance'),
      const Tab(icon: Icon(Icons.security_outlined), text: 'Security'),
    ];

    final views = [
      _buildProfileTab(user),
      if (isDoctor) _buildProfessionalTab(),
      _buildAppearanceTab(),
      _buildSecurityTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: TabBar(
            tabs: tabs,
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: AppTheme.textSecondary,
          ),
        ),
        body: TabBarView(
          children: views,
        ),
      ),
    );
  }

  Widget _buildProfessionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Information', style: AppTheme.headingStyle),
          const SizedBox(height: 24),
          const Text('Upload CV', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.upload_file), 
            label: const Text('Select CV (PDF)')
          ),
          const SizedBox(height: 16),
          const Text('Upload Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.card_membership), 
            label: const Text('Select Certificate')
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'License Number',
              border: OutlineInputBorder(),
              hintText: 'e.g. MED-12345',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _specialtyController,
            decoration: const InputDecoration(
              labelText: 'Specialization',
              border: OutlineInputBorder(),
              hintText: 'e.g. Cardiology, Pediatrics',
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Web Profile Bio',
              border: OutlineInputBorder(),
              hintText: 'Write a public bio for your profile...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          Text('Availability Slots', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Time Slot'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: const Text('Save Professional Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information', style: AppTheme.headingStyle),
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
          
          if (user?.patientProfile != null) ...[
            const SizedBox(height: 32),
            Text('Health Profile (Patient)', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(labelText: 'Blood Type', hintText: 'e.g. O+, A-', prefixIcon: Icon(Icons.bloodtype_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: 'Gender', hintText: 'Male / Female / Other', prefixIcon: Icon(Icons.transgender_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'General Location', hintText: 'City, Area', prefixIcon: Icon(Icons.map_outlined)),
            ),
          ],
          
          if (user?.pharmacistProfile != null || user?.labProfile != null) ...[
            const SizedBox(height: 32),
            Text('Facility Information', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _pharmacyLabNameController,
              decoration: InputDecoration(
                labelText: user?.pharmacistProfile != null ? 'Pharmacy Name' : 'Lab Name',
                prefixIcon: const Icon(Icons.business_outlined)
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Display Preferences', style: AppTheme.headingStyle),
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
    _bloodTypeController.dispose();
    _genderController.dispose();
    _locationController.dispose();
    _specialtyController.dispose();
    _licenseNumberController.dispose();
    _pharmacyLabNameController.dispose();
    super.dispose();
  }
}
