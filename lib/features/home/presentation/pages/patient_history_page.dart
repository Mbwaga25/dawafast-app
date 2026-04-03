import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/data/models/referral_model.dart';

import 'package:app/features/healthcare/presentation/widgets/referral_wizard.dart';

class PatientHistoryPage extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const PatientHistoryPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  void _showTransferSheet(BuildContext context) {
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(patientHistoryProvider(patientId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text('$patientName - Clinical File', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            onPressed: () => _showTransferSheet(context),
            tooltip: 'Transfer Patient',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildPatientHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text('Consultation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ),
          ),
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('No previous records found.')));
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildHistoryCard(context, records[index]),
                    childCount: records.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryTeal,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.2), child: Text(patientName[0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Patient ID: DAP-X921', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTransferSheet(context),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInfoChip(Icons.bloodtype, 'B+', Colors.red),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.warning_amber, 'Penicillin Allergy', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, PatientHistoryRecord record) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateFormat.format(record.date), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              Text(record.doctorName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const Divider(height: 24),
          _buildRecordItem('Symptoms', record.issue),
          const SizedBox(height: 12),
          _buildRecordItem('Diagnosis', record.consultationNotes),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildRecordItem('Treatment', record.prescription, isLast: true)),
              TextButton.icon(
                onPressed: () => _showTransferSheet(context),
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Transfer Patient', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, String value, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
      ],
    );
  }
}
