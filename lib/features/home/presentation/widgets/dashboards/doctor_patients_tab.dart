import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/auth/data/models/user_model.dart';
import 'package:afyalink/features/appointments/data/repositories/appointment_repository.dart';
import 'package:afyalink/features/home/presentation/pages/patient_history_page.dart';

class DoctorPatientsTab extends ConsumerWidget {
  final User user;
  const DoctorPatientsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(myPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(child: Text('No patient records found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal.withAlpha(25),
                    child: Text(p['name']?[0] ?? 'P', style: const TextStyle(color: AppTheme.primaryTeal)),
                  ),
                  title: Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p['condition'] ?? 'No condition mentioned'),
                  trailing: const Icon(Icons.history_outlined),
                  onTap: () {
                    final patientUser = User(
                      id: p['id'], 
                      username: p['id'], // Fallback for required field
                      email: '', // Fallback for required field
                      firstName: p['name'].split(' ')[0], 
                      lastName: p['name'].split(' ').last
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => 
                      PatientHistoryPage(patientId: patientUser.id, patientName: '${patientUser.firstName} ${patientUser.lastName}')
                    ));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
