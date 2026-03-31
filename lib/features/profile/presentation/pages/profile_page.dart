import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'settings_page.dart';
import 'wishlist_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 80, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Please login to view your profile', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('Login / Signup'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildProfileContent(context, ref, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.surfaceWhite,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email, style: const TextStyle(color: AppTheme.textSecondary)),
                      if (user.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(user.phoneNumber!, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  }, 
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Menu Sections
          _buildSection(context, 'My Records', [
            _buildOption(Icons.receipt_long_outlined, 'My Orders', 'View and track orders', 
              () => _showPlaceholder(context, 'My Orders')),
            _buildOption(Icons.medical_services_outlined, 'My Consultations', 'History and upcoming',
              () => _showPlaceholder(context, 'My Consultations')),
            _buildOption(Icons.biotech_outlined, 'Lab Reports', 'Download your results',
              () => _showPlaceholder(context, 'Lab Reports')),
          ]),

          const SizedBox(height: 16),

          _buildSection(context, 'Healthcare Settings', [
            _buildOption(Icons.favorite_outline, 'My Favorites', 'Hospitals and products',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()))),
            _buildOption(Icons.location_on_outlined, 'Manage Addresses', 'Saved delivery addresses',
              () => _showPlaceholder(context, 'Manage Addresses')),
          ]),

          const SizedBox(height: 16),

          _buildSection(context, 'More', [
            _buildOption(Icons.help_outline, 'Help & Support', 'Get assistance',
              () => _showPlaceholder(context, 'Help & Support')),
            _buildOption(Icons.info_outline, 'About DawaFast', 'Learn more about us',
              () => _showPlaceholder(context, 'About DawaFast')),
          ]),
          
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).logout();
                ref.invalidate(currentUserProvider);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppTheme.accentBlue),
                foregroundColor: AppTheme.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
        ),
        Container(
          color: AppTheme.surfaceWhite,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title functionality coming soon!'), duration: const Duration(seconds: 1)),
    );
  }
}
