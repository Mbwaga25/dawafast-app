import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:afyalink/features/profile/presentation/pages/settings_page.dart';
import 'package:afyalink/features/profile/presentation/pages/wishlist_page.dart';
import 'package:afyalink/features/home/presentation/pages/patient_appointments_page.dart';
import 'package:afyalink/features/home/presentation/pages/patient_orders_page.dart';
import 'package:afyalink/features/home/presentation/pages/patient_referrals_page.dart';
import 'package:afyalink/features/profile/presentation/pages/addresses_page.dart';
import 'package:afyalink/features/profile/presentation/pages/about_afyalink_page.dart';
import 'package:afyalink/features/profile/presentation/pages/help_support_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/patient_lab_reports_page.dart';
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle, size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Health Hub',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log in to sync your medical records, track orders, and chat with doctors.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryTeal,
                          minimumSize: const Size(220, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Log in to My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildSection(context, 'Unlock Features', [
                  _buildOption(Icons.receipt_long_outlined, 'Order Tracking', 'Real-time updates on your medicine', () => _showLoginPrompt(context)),
                  _buildOption(Icons.biotech_outlined, 'Lab Reports', 'Access results from anywhere', () => _showLoginPrompt(context)),
                  _buildOption(Icons.favorite_outline, 'Wishlist', 'Save your favorite products', () => _showLoginPrompt(context)),
                ]),
                
                const SizedBox(height: 16),
                
                _buildSection(context, 'Support', [
                  _buildOption(Icons.help_outline, 'Help & Support', 'Get assistance', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()))),
                  _buildOption(Icons.info_outline, 'About AfyaLink', 'Learn more about our mission', 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAfyalinkPage()))),
                ]),
                
                const SizedBox(height: 48),
              ],
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
                  backgroundColor: AppTheme.primaryTeal,
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
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Menu Sections
          _buildSection(context, 'My Records', [
            _buildOption(Icons.receipt_long_outlined, 'My Orders', 'View and track orders', 
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientOrdersPage()))),
            _buildOption(Icons.medical_services_outlined, 'My Consultations', 'History and upcoming',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientAppointmentsPage()))),
            _buildOption(Icons.assignment_outlined, 'My Referrals', 'Professional referrals',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientReferralsPage()))),
            _buildOption(Icons.biotech_outlined, 'Lab Reports', 'Download your results',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientLabReportsPage()))),
          ]),

          const SizedBox(height: 16),

          _buildSection(context, 'Healthcare Settings', [
            _buildOption(Icons.favorite_outline, 'My Favorites', 'Hospitals and products',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()))),
            _buildOption(Icons.location_on_outlined, 'Manage Addresses', 'Saved delivery addresses',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesPage()))),
          ]),

          const SizedBox(height: 16),

          _buildSection(context, 'More', [
            _buildOption(Icons.help_outline, 'Help & Support', 'Get assistance',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()))),
            _buildOption(Icons.info_outline, 'About AfyaLink', 'Learn more about us',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAfyalinkPage()))),
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
                side: const BorderSide(color: AppTheme.accentTeal),
                foregroundColor: AppTheme.accentTeal,
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
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login to access this feature'),
        action: SnackBarAction(
          label: 'LOGIN',
          textColor: AppTheme.accentTeal,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          },
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title functionality coming soon!'), duration: const Duration(seconds: 1)),
    );
  }
}
