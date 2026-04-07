import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/core/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/healthcare/presentation/pages/meeting_page.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/healthcare/data/models/hospital_model.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:app/features/notifications/data/repositories/notification_repository.dart';
import 'package:app/features/notifications/presentation/pages/notification_page.dart';
import 'package:app/features/appointments/presentation/pages/chat_page.dart';
import 'package:app/features/healthcare/data/models/referral_model.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/profile/presentation/pages/doctor_profile_page.dart';
import 'package:app/features/healthcare/presentation/widgets/referral_wizard.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/auth/data/repositories/auth_repository.dart';

// Provides dummy live notifications count
final docNotificationsProvider = StateProvider<List<String>>((ref) => []);

class DoctorDashboard extends ConsumerStatefulWidget {
  final User user;
  const DoctorDashboard({super.key, required this.user});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> with TickerProviderStateMixin {
  late TabController _appointmentTabController;

  @override
  void initState() {
    super.initState();
    _appointmentTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _appointmentTabController.dispose();
    super.dispose();
  }

  void _showNotificationsPanel() {
    final notifications = ref.read(docNotificationsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Clinical Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            if (notifications.isEmpty)
               const Expanded(child: Center(child: Text('All caught up! No recent notifications.', style: TextStyle(color: Colors.grey)))),
            if (notifications.isNotEmpty)
               Expanded(
                 child: ListView.builder(
                   itemCount: notifications.length,
                   itemBuilder: (ctx, idx) => ListTile(
                     leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: const Icon(Icons.description, color: Colors.teal)),
                     title: Text(notifications[idx], style: const TextStyle(fontWeight: FontWeight.w500)),
                     subtitle: const Text('Just now'),
                   )
                 ),
               ),
            if (notifications.isNotEmpty)
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {
                ref.read(docNotificationsProvider.notifier).state = []; // Clear
                Navigator.pop(context);
              }, child: const Text('Mark All as Read')))
          ],
        )
      )
    );
  }


  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(docNotificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Clinical Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(currentUserProvider);
            },
          ),
        ],
      ),
      body: _buildDashboardTab(),
    );
  }

  Widget _buildDashboardTab() {
     return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWelcomeHeader()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildInstantActionsStrip(context)),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildRecentActivityHeader()),
          _buildRecentActivityList(),
        ],
     );
  }

  Widget _buildRecentActivityHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text('Next Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildRecentActivityList() {
    final apptsAsync = ref.watch(doctorAppointmentsProvider);
    return apptsAsync.when(
      data: (appts) {
        final upcoming = appts.where((a) => a.status.toLowerCase() == 'confirmed').toList();
        if (upcoming.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Text('No upcoming appts', style: TextStyle(color: Colors.grey))));
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAppointmentCard(upcoming[index]),
              childCount: upcoming.length > 2 ? 2 : upcoming.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }

  Widget _buildWelcomeHeader() {
    final patientListAsync = ref.watch(myPatientsProvider);
    final totalPatients = patientListAsync.valueOrNull?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryTeal,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${widget.user.lastName ?? widget.user.firstName ?? 'Specialist'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.user.doctorProfile?.specialty ?? 'Medical Practitioner', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfilePage(user: widget.user))),
                child: CircleAvatar(
                  radius: 25, 
                  backgroundColor: Colors.white.withOpacity(0.2), 
                  child: const Icon(Icons.person, color: Colors.white)
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Assigned', '$totalPatients'),
              _buildModernStat('Reviews', '4.9 ★'),
              _buildModernStat('Status', 'Active'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildInstantActionsStrip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              title: 'Instant Meeting',
              icon: Icons.video_call, color: Colors.teal,
              onTap: () {
                final dummyDoctor = Doctor(id: widget.user.id, specialty: widget.user.doctorProfile?.specialty ?? 'General', user: UserShort(id: widget.user.id, firstName: widget.user.firstName, lastName: widget.user.lastName, username: widget.user.username));
                Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingPage(doctor: dummyDoctor, appointmentId: 'instant_meeting')));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              title: 'Global Search',
              icon: Icons.search, color: Colors.blueAccent,
              onTap: () {
                 // Navigation to the chat tab's search functionality could be triggered here
                 // for now just a mockup snackbar as it's a tab switch
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the Chat tab to start new conversations')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
      ),
    );
  }

  void _showReferralSheet({String? patientId, String? patientName, String? appointmentId}) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReferralWizard(
          patientId: patientId,
          patientName: patientName,
          appointmentId: appointmentId,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment a, {bool isPast = false, bool showActions = false}) {
    final dateFormat = DateFormat('h:mm a • MMM d');
    final isVideo = a.type == 'telemedicine';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isVideo ? Colors.blue.withOpacity(0.1) : Colors.teal.withOpacity(0.1), 
            child: Icon(isVideo ? Icons.video_camera_front : Icons.local_hospital, color: isVideo ? Colors.blue : Colors.teal)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(a.type.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateFormat.format(a.date), style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
              if (a.status.toLowerCase() == 'confirmed')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.chat_outlined, color: AppTheme.primaryTeal, size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(appointmentId: a.id))),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final doc = Doctor(
                          id: widget.user.id,
                          specialty: widget.user.doctorProfile?.specialty,
                          user: UserShort(
                            id: widget.user.id,
                            firstName: widget.user.firstName,
                            lastName: widget.user.lastName,
                            username: widget.user.username,
                          ),
                        );
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingPage(doctor: doc, appointmentId: a.id)));
                      },
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryTeal, borderRadius: BorderRadius.circular(12)), child: const Text('Start', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'COMPLETED': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

// End of file
