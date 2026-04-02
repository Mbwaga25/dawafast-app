import 'package:flutter/material.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: _showNotificationsPanel),
              if (notifs.isNotEmpty)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${notifs.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )
            ],
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
                tabs: const [Tab(text: 'Appointments'), Tab(text: 'My Patients'), Tab(text: 'Transfers')],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [ _buildAppointmentsTab(), _buildPatientsTab(), _buildTransfersTab() ],
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

  Widget _buildAppointmentsTab() {
    final apptsAsync = ref.watch(doctorAppointmentsProvider);

    return apptsAsync.when(
      data: (appts) {
        if (appts.isEmpty) return const Center(child: Text('No appointments today.'));
        final pending = appts.where((a) => a.status == 'pending').toList();
        final attended = appts.where((a) => a.status == 'accomplished' || a.status == 'awaiting_lab' || a.status == 'awaiting_pharmacy').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...pending.map((a) => _buildAppointmentCard(a)),
            
            if (attended.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Attended Files (Actionable)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              ...attended.map((a) => _buildAppointmentCard(a, isPast: true)),
            ]
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error loading appointments')),
    );
  }

  Widget _buildAppointmentCard(Appointment a, {bool isPast = false}) {
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
              CircleAvatar(backgroundColor: isVideo ? Colors.blue.withOpacity(0.1) : Colors.teal.withOpacity(0.1), child: Icon(isVideo ? Icons.video_camera_front : Icons.local_hospital, color: isVideo ? Colors.blue : Colors.teal)),
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
                  Text(dateFormat.format(a.date), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  if (!isPast)
                    Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(12)), child: const Text('Join', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
          if (isPast) ...[
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
        if (patients.isEmpty) return const Center(child: Text('No assigned patients.'));
        
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
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: p['status'] == 'Attended' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(p['status'], style: TextStyle(color: p['status'] == 'Attended' ? Colors.green : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error')),
    );
  }

  Widget _buildTransfersTab() {
    final transfersAsync = ref.watch(transferredPatientsProvider);

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) return const Center(child: Text('No patient transfers.'));
        
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
                      Text('Transferred from ${t.transferredFrom ?? 'Unknown'}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Text(t.patientName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Status: ${t.status.toUpperCase()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, elevation: 0),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepted transfer for ${t.patientName}')));
                      },
                      child: const Text('Accept Case Transfer', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error')),
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

  void _dispatchReferral() {
      // 1. Close Modal
      Navigator.pop(context);
      
      // 2. Trigger Notification feedback Loop
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dispatched patient file to ${_selectedFacility!.name} successfully. Awaiting response.'),
        backgroundColor: Colors.green
      ));
      
      // 3. Mutate Appointment State to "AWAITING"
      final newStatus = widget.type == 'LAB' ? 'awaiting_lab' : 'awaiting_pharmacy';
      ref.read(doctorAppointmentsProvider.notifier).updateAppointmentStatus(widget.appointment.id, newStatus);
      
      // 4. Mock the response delay turning the Notification Bell Red in 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
          ref.read(docNotificationsProvider.notifier).state = [
              ...ref.read(docNotificationsProvider),
              'Response Received: ${_selectedFacility!.name} completed processing for ${widget.appointment.patientName}.'
          ];
      });
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
                       return ListView.builder(
                         itemCount: facilities.length,
                         itemBuilder: (ctx, idx) {
                            final fac = facilities[idx];
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
                                          Text('${fac.city ?? "Nearby"} • Available Services checked ✅', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
