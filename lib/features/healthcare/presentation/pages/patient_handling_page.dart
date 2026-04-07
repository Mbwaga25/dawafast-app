import 'package:flutter/material.dart';
import 'package:app/core/theme.dart';

class PatientHandlingPage extends StatelessWidget {
  final String appointmentId;
  final String patientName;

  const PatientHandlingPage({
    super.key,
    required this.appointmentId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Handle Patient: $patientName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Details', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Age', '34'),
                    _buildDetailRow('Blood Type', 'O+'),
                    _buildDetailRow('Allergies', 'Penicillin'),
                    _buildDetailRow('Medical History', 'Asthma, Mild Hypertension'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Current Issue
            Text('Current Appointment Issue', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Patient is experiencing severe headaches and slight fever over the past 3 days.'),
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            Text('Smart Handling Actions', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Private Chat Page (Assume ChatPage exists or would be pushed)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting private chat session...')),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Start Private Chat'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.video_call),
              label: const Text('Start Video Call'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.medical_services),
              label: const Text('Refer Patient'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
