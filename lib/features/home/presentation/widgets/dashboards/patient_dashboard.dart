import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/orders/data/repositories/order_repository.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/healthcare/presentation/pages/telemedicine_page.dart';
import 'package:app/features/healthcare/presentation/pages/healthcare_page.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/orders/data/models/order_model.dart';
import 'package:app/features/healthcare/presentation/widgets/instant_call_button.dart';
import 'package:app/features/notifications/data/repositories/notification_repository.dart';
import 'package:app/features/notifications/presentation/pages/notification_page.dart';
import 'package:app/features/appointments/presentation/pages/chat_page.dart';
import 'package:app/features/home/presentation/pages/patient_appointments_page.dart';
import 'package:app/features/home/presentation/pages/patient_orders_page.dart';
import 'package:app/features/home/presentation/pages/patient_referrals_page.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/healthcare/presentation/pages/pharmacies_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/features/profile/presentation/pages/settings_page.dart';
import 'package:app/features/auth/data/repositories/auth_repository.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';

class PatientDashboard extends ConsumerWidget {
  final User user;
  const PatientDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      // Minimal app bar for the Dashboard specifically
      appBar: AppBar(
        title: Text('My Dashboard', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        actions: [
          ref.watch(unreadNotificationsCountProvider).when(
            data: (count) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            loading: () => IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  ref.read(tabIndexProvider.notifier).state = 4;
                  break;
                case 'appointments':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsPage()));
                  break;
                case 'orders':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientOrdersPage()));
                  break;
                case 'referrals':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientReferralsPage()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  break;
                case 'logout':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authRepositoryProvider).logout();
                    ref.invalidate(currentUserProvider);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 8), Text('My Profile')])),
              const PopupMenuItem(value: 'appointments', child: Row(children: [Icon(Icons.calendar_today_outlined, size: 20), SizedBox(width: 8), Text('Appointments')])),
              const PopupMenuItem(value: 'orders', child: Row(children: [Icon(Icons.shopping_bag_outlined, size: 20), SizedBox(width: 8), Text('My Orders')])),
              const PopupMenuItem(value: 'referrals', child: Row(children: [Icon(Icons.assignment_outlined, size: 20), SizedBox(width: 8), Text('Referrals')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_outlined, size: 20), SizedBox(width: 8), Text('Settings')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildWelcomeHeader(),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 20),
          ),
          SliverToBoxAdapter(
            child: _buildFindServicesStrip(context, ref),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: _buildAppointmentsSection(context, ref),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 32),
          ),
          SliverToBoxAdapter(
            child: _buildRecentOrdersSection(context, ref),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 48), // Padding bottom
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user.firstName ?? user.username} 👋',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'What do you need help with today?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFindServicesStrip(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Find', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceButton(context, 
                title: 'Doctor', 
                icon: Icons.person_search_outlined, 
                color: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage())),
              ),
              _buildServiceButton(context, 
                title: 'Lab Test', 
                icon: Icons.science_outlined, 
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthcarePage())),
              ),
              _buildServiceButton(context, 
                title: 'Pharmacy', 
                icon: Icons.local_pharmacy_outlined, 
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesPage())),
              ),
              _buildServiceButton(context, 
                title: 'Medicines', 
                icon: Icons.health_and_safety_outlined, 
                color: Colors.redAccent,
                onTap: () {
                  ref.read(tabIndexProvider.notifier).state = 1;
                },
              ),
              _buildServiceButton(context, 
                title: 'Referrals', 
                icon: Icons.assignment_outlined, 
                color: Colors.blueGrey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientReferralsPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsPage())),
                child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text('Upcoming', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          const SizedBox(height: 8),
          upcomingAsync.when(
            data: (appts) {
              if (appts.isEmpty) {
                return _buildEmptyState('No upcoming appointments', Icons.calendar_today);
              }
              return Column(
                children: appts.map((a) => _buildAppointmentCard(context, a)).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (err, stack) => const Text('Failed to load appointments', style: TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 16),
          const Text('Accomplished', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          pastAsync.when(
            data: (appts) {
              if (appts.isEmpty) {
                return _buildEmptyState('No past records', Icons.history);
              }
              return Column(
                children: appts.map((a) => _buildAppointmentCard(context, a, isPast: true)).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary.withOpacity(0.5), size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment a, {bool isPast = false}) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final isVideo = a.type == 'telemedicine';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: isPast ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isVideo ? Colors.blue.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.video_camera_front : Icons.local_hospital,
              color: isVideo ? Colors.blue : Colors.teal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(a.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildStatusChip(a.status),
                  ],
                ),
                Text(a.specialization, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppTheme.primaryTeal),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(a.date), style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (!isPast) ...[
            const SizedBox(width: 8),
            if (isVideo && a.status.toLowerCase() == 'confirmed')
              InstantCallButton(appointmentId: a.id)
            else if (a.status.toLowerCase() == 'confirmed')
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: AppTheme.primaryTeal),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(appointmentId: a.id))),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientOrdersPage())),
                child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal)),
              ),
            ],
          ),
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return _buildEmptyState('No recent orders', Icons.shopping_bag_outlined);
              }
              // Just show first 3
              final recent = orders.take(3).toList();
              return Column(
                children: recent.map((o) => _buildOrderTile(o)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildEmptyState('Could not load orders', Icons.error_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Order order) {
    // Generate a quick summary of items
    final itemCount = order.items.length;
    final summary = order.items.isNotEmpty ? order.items.map((i) => i.productName).take(2).join(', ') : 'Order items';
    final hasMore = itemCount > 2 ? ' +${itemCount - 2} more' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.id.substring(0, order.id.length > 6 ? 6 : order.id.length)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(order.status, style: TextStyle(
                      color: order.status.toLowerCase() == 'completed' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold, fontSize: 12
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$summary$hasMore', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(DateFormat('MMM d, yyyy').format(order.orderDate), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == 'confirmed' || s == 'completed') color = Colors.green;
    if (s == 'pending' || s == 'processing') color = Colors.orange;
    if (s == 'cancelled' || s == 'failed') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
