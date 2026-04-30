import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/auth/data/models/user_model.dart';
import 'package:afyalink/features/auth/data/repositories/user_repository.dart';
import 'package:afyalink/features/offers/data/models/product_model.dart';
import 'package:afyalink/features/offers/data/models/brand_model.dart';
import 'package:afyalink/features/offers/data/repositories/marketplace_repository.dart';
import 'package:afyalink/features/profile/data/repositories/settings_repository.dart';
import 'package:afyalink/features/offers/presentation/pages/category_page.dart';
import 'package:afyalink/features/offers/presentation/pages/offers_page.dart';
import 'package:afyalink/features/auth/data/repositories/auth_repository.dart';
import 'package:afyalink/features/home/presentation/pages/product_detail_page.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/patient_dashboard.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/doctor_dashboard.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/doctor_schedule_tab.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/doctor_patients_tab.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/doctor_chat_tab.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/lab_dashboard.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/pharmacy_dashboard.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/admin_dashboard.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/hospital_dashboard.dart';
import 'package:afyalink/features/healthcare/presentation/pages/healthcare_page.dart';
import 'package:afyalink/features/cart/presentation/providers/cart_provider.dart';
import 'package:afyalink/features/cart/presentation/pages/cart_page.dart';
import 'package:afyalink/features/cart/data/models/cart_model.dart';
import 'package:afyalink/features/home/presentation/pages/search_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/telemedicine_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/labs_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/pharmacies_page.dart';
import 'package:afyalink/features/offers/presentation/pages/brands_page.dart';
import 'package:afyalink/features/profile/presentation/pages/settings_page.dart';
import 'package:afyalink/features/profile/presentation/pages/profile_page.dart';
import 'package:afyalink/features/profile/presentation/pages/doctor_profile_page.dart';
import 'package:afyalink/features/auth/presentation/pages/login_page.dart';
import 'package:afyalink/core/widgets/product_image.dart';
import 'package:afyalink/core/providers/location_provider.dart';
import 'package:afyalink/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:afyalink/features/home/presentation/widgets/location_picker_sheet.dart';
import 'package:afyalink/features/home/presentation/widgets/guest_home_content.dart';
import 'package:afyalink/core/widgets/afyalink_loader.dart';
import 'package:go_router/go_router.dart';

// ─── Bottom Nav Index Provider ────────────────────────────────────────────────
final tabIndexProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final tabIndex = ref.watch(tabIndexProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return userAsync.when(
      data: (user) {
        // If not logged in or is a patient, show the 5-tab e-commerce shell
        if (user == null || user.role == null || user.role!.toUpperCase() == 'PATIENT') {
          return _buildMainShell(context, ref, tabIndex, user: user);
        }
        // Otherwise show the specialized dashboard for their role
        return _buildRoleDashboard(context, ref, user);
      },
      loading: () => const AfyaLinkScaffoldLoader(message: 'Initializing AfyaLink...'),
      error: (err, stack) => _buildMainShell(context, ref, tabIndex),
    );
  }

  // ─── Role-based dashboards (pharmacist, doctor etc.) ─────────────────────
  Widget _buildRoleDashboard(BuildContext context, WidgetRef ref, User user) {
    if (user.role?.toUpperCase() == 'DOCTOR') {
      return _buildDoctorShell(context, ref, user);
    }

    Widget dashboard;
    String title = 'Dashboard';

    switch (user.role?.toUpperCase()) {
      case 'LAB_TECHNICIAN':
      case 'LAB':
        dashboard = LabDashboard(user: user);
        title = 'Lab Panel';
        break;
      case 'PHARMACIST':
      case 'PHARMACY':
        dashboard = PharmacyDashboard(user: user);
        title = 'Pharmacy Panel';
        break;
      case 'HOSPITAL_ADMIN':
      case 'HOSPITAL':
        dashboard = HospitalDashboard(user: user);
        title = 'Hospital Panel';
        break;
      case 'ADMIN':
      case 'STAFF':
      case 'SUPERUSER':
        dashboard = AdminDashboard(user: user);
        title = 'Admin Panel';
        break;
      default:
        return _buildMainShell(context, ref, ref.read(tabIndexProvider));
    }

    return dashboard;
  }

  Widget _buildDoctorShell(BuildContext context, WidgetRef ref, User user) {
    final tabIndex = ref.watch(tabIndexProvider);
    final tabs = [
      DoctorDashboard(user: user),
      _buildDoctorScheduleTab(user),
      _buildDoctorPatientsTab(user),
      _buildDoctorChatTab(user),
      DoctorProfilePage(user: user),
    ];

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
        selectedItemColor: AppTheme.primaryTeal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDoctorScheduleTab(User user) {
    return DoctorScheduleTab(user: user);
  }

  Widget _buildDoctorPatientsTab(User user) {
    return DoctorPatientsTab(user: user);
  }

  Widget _buildDoctorChatTab(User user) {
    return const DoctorChatTab();
  }

  // ─── Main shell with 5-tab bottom nav ────────────────────────────────────
  Widget _buildMainShell(BuildContext context, WidgetRef ref, int tabIndex, {User? user}) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final tabs = [
      (user != null && user.role?.toUpperCase() == 'PATIENT') ? PatientDashboard(user: user) : const GuestHomeContent(),
      const OffersPage(),
      const HealthcarePage(),
      const TelemedicinePage(),
      _buildProfileTab(context, ref),
    ];

    return Scaffold(
      appBar: _buildAppBar(context, ref, selectedLocation),
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomNavigationBar: _buildBottomNav(context, ref, tabIndex),
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, String location) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: AppTheme.borderColor,
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _showLocationPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryTeal, size: 14),
                  const SizedBox(width: 3),
                  const Text('Deliver to', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                children: [
                  Flexible(child: Text(location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primaryTeal),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        const NotificationBell(),
        Consumer(
          builder: (context, ref, child) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.maybeWhen(
              data: (user) {
                if (user == null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => context.push('/login'),
                      child: const Text('Login', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        Consumer(
          builder: (context, ref, child) {
            final cartCount = ref.watch(cartProvider).items.length;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => context.push('/cart'),
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPickerSheet(),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int index) {
    final user = ref.watch(currentUserProvider).value;
    
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: 'Medicines'),
      const BottomNavigationBarItem(icon: Icon(Icons.biotech_outlined), activeIcon: Icon(Icons.biotech), label: 'Health Services'),
      const BottomNavigationBarItem(icon: Icon(Icons.video_call_outlined), activeIcon: Icon(Icons.video_call), label: 'Consult'),
      if (user != null)
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];

    return BottomNavigationBar(
      currentIndex: index > items.length - 1 ? 0 : index,
      onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 8,
      items: items,
    );
  }

  Widget _buildProfileTab(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const LoginPage();
    }
    return const ProfilePage();
  }
}

