import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/healthcare/presentation/pages/doctor_detail_page.dart';
import 'package:app/features/healthcare/presentation/pages/meeting_page.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

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
      body: Column(
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
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                final filtered = doctors.where((d) => 
                  d.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (d.specialty?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

                if (filtered.isEmpty) return const Center(child: Text('No doctors available for video call'));

                return ListView.builder(
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
          ),
        ],
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
}

class _TeleDoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _TeleDoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
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
                  backgroundImage: const AssetImage('lib/assets/images/doctor_placeholder.png'),
                  backgroundColor: AppTheme.backgroundGray,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(doctor.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Badge(
                            label: Text('Online'),
                            backgroundColor: Colors.green,
                          ),
                        ],
                      ),
                      Text(doctor.specialty ?? 'General Physician', style: const TextStyle(color: AppTheme.textSecondary)),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MeetingPage(doctor: doctor)
                        ));
                      },
                      icon: const Icon(Icons.videocam, size: 18),
                      label: const Text('Start Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DoctorDetailPage(doctorId: doctor.id)
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
