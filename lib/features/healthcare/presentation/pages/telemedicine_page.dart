import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/healthcare/presentation/pages/doctor_detail_page.dart';
import 'package:app/features/healthcare/presentation/pages/meeting_page.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/core/ui_utils.dart';
import 'package:app/features/healthcare/presentation/pages/hospital_create_page.dart';

class TelemedicinePage extends ConsumerStatefulWidget {
  const TelemedicinePage({super.key});

  @override
  ConsumerState<TelemedicinePage> createState() => _TelemedicinePageState();
}

class _TelemedicinePageState extends ConsumerState<TelemedicinePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsProvider((search: null, specialty: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemedicine'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.video_camera_front, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Virtual Medical Consultations',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with doctors instantly from home. Secure, private, and convenient.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          
          _buildRegistrationPromo(context),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('500+', 'Online'),
                _buildStat('50k+', 'Consults'),
                _buildStat('98%', 'Happy'),
                _buildStat('24/7', 'Support'),
              ],
            ),
          ),

          const Divider(),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available Specialists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Show All')),
              ],
            ),
          ),

          // Doctors List
          doctorsAsync.when(
              data: (doctors) {
                final filtered = doctors.where((d) => 
                  d.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (d.specialty?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

                if (filtered.isEmpty) return const Center(child: Text('No doctors available for video call'));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doctor = filtered[index];
                    return _TeleDoctorCard(doctor: doctor);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRegistrationPromo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppTheme.accentTeal, shape: BoxShape.circle),
            child: const Icon(Icons.add_business, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Own a Facility?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Register your Hospital, Lab, or Pharmacy on DawaFast.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalCreatePage())),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

class _TeleDoctorCard extends ConsumerStatefulWidget {
  final Doctor doctor;

  const _TeleDoctorCard({required this.doctor});

  @override
  ConsumerState<_TeleDoctorCard> createState() => _TeleDoctorCardState();
}

class _TeleDoctorCardState extends ConsumerState<_TeleDoctorCard> {
  bool _isLoading = false;

  Future<void> _handleStartCall(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.role?.toUpperCase() == 'GUEST') {
      UIUtils.showAuthGuardDialog(context, message: 'You need an account to request a video consultation.');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(doctorsRepositoryProvider);
      final appointments = await repo.fetchMyAppointments();
      
      // Check for existing confirmed video appointment for this doctor
      final existing = appointments.where((a) => 
        a['doctor']['id'] == widget.doctor.id && 
        a['status']?.toString().toUpperCase() == 'CONFIRMED' &&
        a['appointmentType']?.toString().toUpperCase() == 'VIDEO'
      ).toList();

      if (existing.isNotEmpty) {
        // Start session and navigate
        final session = await repo.startCallSession(existing.first['id']);
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MeetingPage(doctor: widget.doctor, appointmentId: existing.first['id'])
          ));
        }
      } else {
        // No confirmed appointment - ask for instant
        if (mounted) {
          _showInstantBookingDialog(context, ref);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInstantBookingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instant Consultation'),
        content: Text('You don\'t have a confirmed appointment with Dr. ${widget.doctor.fullName} right now. Would you like to request an instant video consultation for Tsh 30,000?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _requestInstantConsultation(context, ref);
            },
            child: const Text('Request Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestInstantConsultation(BuildContext context, WidgetRef ref) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(doctorsRepositoryProvider);
      
      // Create dynamic slot and book
      final now = DateTime.now().toIso8601String();
      final dynamicId = "dynamic_${widget.doctor.id}_$now";
      
      final appointment = await repo.bookAppointment(
        availabilityId: dynamicId,
        appointmentType: 'VIDEO',
        patientName: ref.read(currentUserProvider).value?.fullName,
      );

      final appId = appointment['id'];
      if (appId != null) {
        // Step 2: Confirm the appointment (Status must be CONFIRMED for instant calls)
        await repo.confirmAppointment(appId);

        // Step 3: Request instant flag and notification
        await repo.requestInstantCall(appId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consultation requested! Waiting for doctor confirmation.')),
          );
          // Navigate to meeting page in "waiting" mode
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MeetingPage(doctor: widget.doctor, appointmentId: appId)
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isGuest = user?.role?.toUpperCase() == 'GUEST';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.blue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.doctor.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Badge(
                            label: Text('Online'),
                            backgroundColor: Colors.green,
                          ),
                        ],
                      ),
                      Text(widget.doctor.specialty ?? 'General Physician', style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const Text(' 4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(' (120 reviews)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Video Fee', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Text('Tsh 30,000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                  ],
                ),
                Row(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: isGuest ? null : () => _handleStartCall(context, ref),
                        icon: const Icon(Icons.videocam, size: 18),
                        label: Text(isGuest ? 'Login to Call' : 'Start Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGuest ? Colors.grey : const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DoctorDetailPage(doctorId: widget.doctor.id)
                        ));
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
