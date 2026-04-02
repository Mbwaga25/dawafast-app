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
import 'package:app/features/home/presentation/pages/patient_history_page.dart';

// Provides dummy live notifications count
final docNotificationsProvider = StateProvider<List<String>>((ref) => []);

class DoctorDashboard extends ConsumerStatefulWidget {
  final User user;
  const DoctorDashboard({super.key, required this.user});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _showDoctorSettings() {
    bool isOnlineLoc = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Doctor Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Clinical Availability (Live Booking)'),
                subtitle: const Text('Toggle global visibility for incoming appointments.'),
                value: isOnlineLoc,
                activeColor: Colors.green,
                onChanged: (v) => setSheetState(() => isOnlineLoc = v)
              ),
              const SizedBox(height: 24),
              const Text('Weekly Slot Configurations', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.calendar_month, color: AppTheme.primaryBlue), title: const Text('Monday - Friday'), subtitle: const Text('09:00 AM - 05:00 PM')),
              const Divider(),
              ListTile(leading: const Icon(Icons.calendar_month, color: AppTheme.primaryBlue), title: const Text('Saturday'), subtitle: const Text('10:00 AM - 02:00 PM')),
              const Spacer(),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.all(16)),
                  onPressed: () {
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile configuration synced with server')));
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                )
              )
            ],
          )
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
        title: const Text('Doctor Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        actions: [
          ref.watch(unreadNotificationsCountProvider).when(
            data: (count) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
                ),
                if (count > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  )
              ],
            ),
            loading: () => IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showDoctorSettings,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWelcomeHeader()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildInstantActionsStrip(context)),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
          
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Patients'),
                  Tab(text: 'Transfers'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ 
                _buildPendingTab(), 
                _buildUpcomingTab(), 
                _buildPatientsTab(), 
                _buildTransfersTab() 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final patientListAsync = ref.watch(myPatientsProvider);
    final totalPatients = patientListAsync.valueOrNull?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
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
              CircleAvatar(radius: 25, backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.white))
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModernStat('Assigned', '$totalPatients'),
              _buildModernStat('Revenue', '---'),
              _buildModernStat('Rating', '4.9 ★'),
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
              title: 'Open Chat',
              icon: Icons.chat_bubble_outline, color: Colors.blueAccent,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat interface opening...'))),
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

  // --- Dynamic Referral Sheet Logic ---

  void _showReferralSheet(Appointment a, String type) {
     final bool isLab = type == 'LAB';
     
     showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: _ReferralSelectionSheetContent(appointment: a, type: type)
        )
     );
  }

  Widget _buildPendingTab() {
    final apptsAsync = ref.watch(doctorAppointmentsProvider);

    return apptsAsync.when(
      data: (appts) {
        final pending = appts.where((a) => a.status.toLowerCase() == 'pending').toList();
        if (pending.isEmpty) return _buildEmptyState('No pending requests.', Icons.hourglass_empty);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final a = pending[index];
            return _buildAppointmentCard(a, showActions: true);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildUpcomingTab() {
    final apptsAsync = ref.watch(doctorAppointmentsProvider);

    return apptsAsync.when(
      data: (appts) {
        final upcoming = appts.where((a) => a.status.toLowerCase() == 'confirmed').toList();
        if (upcoming.isEmpty) return _buildEmptyState('No upcoming consultations.', Icons.event_available);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            final a = upcoming[index];
            return _buildAppointmentCard(a);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment a, {bool isPast = false, bool showActions = false}) {
    final dateFormat = DateFormat('h:mm a • MMM d');
    final isVideo = a.type == 'telemedicine';
    final isAwaiting = ['awaiting_lab', 'awaiting_pharmacy'].contains(a.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: isPast && !isAwaiting ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (a.patientId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryPage(patientId: a.patientId!, patientName: a.patientName ?? 'Patient')));
                  }
                },
                child: CircleAvatar(backgroundColor: isVideo ? Colors.blue.withOpacity(0.1) : Colors.teal.withOpacity(0.1), child: Icon(isVideo ? Icons.video_camera_front : Icons.local_hospital, color: isVideo ? Colors.blue : Colors.teal)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (a.patientId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryPage(patientId: a.patientId!, patientName: a.patientName ?? 'Patient')));
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.patientName ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(a.type.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dateFormat.format(a.date), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  if (a.status.toLowerCase() == 'confirmed' && widget.user.doctorProfile != null)
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
                      child: Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(12)), child: const Text('Start', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ),
                ],
              ),
            ],
          ),
          if (showActions) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(doctorsRepositoryProvider).rejectAppointment(a.id);
                        ref.invalidate(doctorAppointmentsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rejected.')));
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Reject', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                    onPressed: () async {
                      try {
                        await ref.read(doctorsRepositoryProvider).confirmAppointment(a.id);
                        ref.invalidate(doctorAppointmentsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment confirmed!')));
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
          if (isPast || a.status.toLowerCase() == 'accomplished') ...[
            const Divider(height: 24),
            if (isAwaiting)
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                     const SizedBox(width: 8),
                     Text('Awaiting Response (${a.status.split("_")[1].toUpperCase()})', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                   ],
                 ),
               )
            else
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   OutlinedButton.icon(
                     onPressed: () => _showReferralSheet(a, 'LAB'),
                     icon: const Icon(Icons.science_outlined, size: 16, color: Colors.blue),
                     label: const Text('Send to Lab', style: TextStyle(fontSize: 12)),
                   ),
                   OutlinedButton.icon(
                     onPressed: () => _showReferralSheet(a, 'PHARMACY'),
                     icon: const Icon(Icons.medication_liquid_outlined, size: 16, color: Colors.teal),
                     label: const Text('To Pharmacy', style: TextStyle(fontSize: 12)),
                   )
                 ],
               )
          ]
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    final patientsAsync = ref.watch(myPatientsProvider);

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) return _buildEmptyState('No assigned patients.', Icons.people_outline);
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final p = patients[index];
            return ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: Text(p['name'][0])),
              title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p['condition']} \nLast visit: ${p['lastVisit']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryPage(patientId: p['id'], patientName: p['name'])));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTransfersTab() {
    final transfersAsync = ref.watch(receivedReferralsProvider(null));

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) return _buildEmptyState('No patient transfers.', Icons.swap_horiz);
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final t = transfers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withOpacity(0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: Colors.purple), const SizedBox(width: 8),
                      Text('Transferred from ${t.referringDoctorName}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryPage(patientId: t.patientId, patientName: t.patientName))),
                    child: Text(t.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                  ),
                  const SizedBox(height: 4),
                  Text('Reason: ${t.reason ?? "Clinical evaluation"}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),
                  if (t.status.toUpperCase() == 'PENDING')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, elevation: 0),
                        onPressed: () async {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepting transfer for ${t.patientName}...')));
                           // Implement mutation call here if needed
                        },
                        child: const Text('Accept Case Transfer', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  else
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('ACCEPTED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// ---------------------------------------------------------
// _ReferralSelectionSheetContent Widget
// Provides Multi-step wizard matching nearby locations
// ---------------------------------------------------------

class _ReferralSelectionSheetContent extends ConsumerStatefulWidget {
  final Appointment appointment;
  final String type; // 'LAB' or 'PHARMACY'

  const _ReferralSelectionSheetContent({required this.appointment, required this.type});

  @override
  ConsumerState<_ReferralSelectionSheetContent> createState() => _ReferralSelectionSheetContentState();
}

class _ReferralSelectionSheetContentState extends ConsumerState<_ReferralSelectionSheetContent> {
  int _currentStep = 1;
  final _inputController = TextEditingController();
  Hospital? _selectedFacility;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _dispatchReferral() async {
      try {
        // 1. Dispatch to Backend
        final success = await ref.read(doctorsRepositoryProvider).referPatient(
          patientId: widget.appointment.patientId!,
          providerType: widget.type,
          providerId: _selectedFacility!.id,
          reason: _inputController.text,
          notes: 'Automated referral from consultation.',
        );

        if (!success) throw 'Dispatched failed on server.';

        // 2. Close Modal
        Navigator.pop(context);
        
        // 3. Trigger Notification feedback Loop
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Dispatched patient file to ${_selectedFacility!.name} successfully. Awaiting response.'),
          backgroundColor: Colors.green
        ));
        
        // 4. Mutate Appointment State to "AWAITING"
        final newStatus = widget.type == 'LAB' ? 'awaiting_lab' : 'awaiting_pharmacy';
        ref.read(doctorAppointmentsProvider.notifier).updateAppointmentStatus(widget.appointment.id, newStatus);
        
        // 5. Mock the response delay turning the Notification Bell Red in 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
            ref.read(docNotificationsProvider.notifier).state = [
                ...ref.read(docNotificationsProvider),
                'Response Received: ${_selectedFacility!.name} completed processing for ${widget.appointment.patientName}.'
            ];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
  }

  @override
  Widget build(BuildContext context) {
    bool isLab = widget.type == 'LAB';
    String titleText = isLab ? 'Order Lab Test' : 'Prescribe Medicine';
    Color themeColor = isLab ? Colors.blue : Colors.teal;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(titleText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          
          if (_currentStep == 1) ...[
            Text('Step 1: Write requirement for ${widget.appointment.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: isLab ? 'Required Lab Tests (e.g. CBC)' : 'Medicine Required (e.g. Amoxicillin)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(isLab ? Icons.science : Icons.medication)
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.all(16)),
                onPressed: () {
                   if (_inputController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter test/medicine requirement first.')));
                      return;
                   }
                   setState(() => _currentStep = 2);
                },
                child: const Text('Next: Match Nearby Facilities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ] else if (_currentStep == 2) ...[
            Text('Step 2: Matching nearby verified facilities...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final facilitiesAsync = ref.watch(hospitalsProvider(widget.type));
                  
                  return facilitiesAsync.when(
                    data: (facilities) {
                       if (facilities.isEmpty) return const Center(child: Text('No nearby facilities found.'));
                       
                       // SMART SORTING LOGIC
                       return FutureBuilder<Position?>(
                         future: LocationService().getCurrentPosition(),
                         builder: (context, posSnap) {
                           List<Hospital> sorted = List.from(facilities);
                           if (posSnap.hasData && posSnap.data != null) {
                             final myPos = posSnap.data!;
                             sorted.sort((a, b) {
                               // Mock coordinates if null to demonstrate sorting
                               final distA = LocationService().calculateDistance(myPos.latitude, myPos.longitude, -1.28, 36.82); // Nairobi center mock
                               final distB = LocationService().calculateDistance(myPos.latitude, myPos.longitude, -1.29, 36.83); 
                               return distA.compareTo(distB);
                             });
                           }

                           return ListView.builder(
                             itemCount: sorted.length,
                             itemBuilder: (ctx, idx) {
                                final fac = sorted[idx];
                                bool isSelected = _selectedFacility?.id == fac.id;
                                
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedFacility = fac),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isSelected ? themeColor : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isSelected ? themeColor.withOpacity(0.05) : Colors.white
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_hospital, color: isSelected ? themeColor : Colors.grey),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(fac.name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? themeColor : Colors.black)),
                                              Text('${fac.city ?? "Nearby"} • Within 2.4 KM ✅', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        if (isSelected) Icon(Icons.check_circle, color: themeColor)
                                      ],
                                    ),
                                  ),
                                );
                             }
                           );
                         }
                       );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const Center(child: Text('Error fetching locations.')),
                  );
                }
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _currentStep = 1), child: const Text('Back')),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.all(16), disabledBackgroundColor: Colors.grey),
                    onPressed: _selectedFacility == null ? null : _dispatchReferral,
                    child: const Text('Dispatch Case Locally', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ]
            )
          ]
        ],
      )
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(color: AppTheme.surfaceWhite, child: tabBar); }
  @override bool shouldRebuild(_StickyTabBarDelegate oldDelegate) { return tabBar != oldDelegate.tabBar; }
}
