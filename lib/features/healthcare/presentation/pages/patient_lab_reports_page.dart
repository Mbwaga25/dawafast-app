import 'package:flutter/material.dart';
import 'package:afyalink/core/theme.dart';
import 'package:intl/intl.dart';

class PatientLabReportsPage extends StatelessWidget {
  const PatientLabReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock lab reports
    final mockReports = [
      {
        'title': 'Complete Blood Count (CBC)',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Ready',
        'facility': 'Muhimbili Central Lab',
      },
      {
        'title': 'Metabolic Panel',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'status': 'Ready',
        'facility': 'Downtown Clinic Lab',
      },
      {
        'title': 'Lipid Profile',
        'date': DateTime.now().subtract(const Duration(days: 45)),
        'status': 'Ready',
        'facility': 'Aga Khan Lab Services',
      },
      {
        'title': 'Thyroid Function Test',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Pending',
        'facility': 'Muhimbili Central Lab',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lab Reports', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: mockReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.biotech, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No lab reports available', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockReports.length,
              itemBuilder: (context, index) {
                final report = mockReports[index];
                return _buildReportCard(context, report);
              },
            ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isReady = report['status'] == 'Ready';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey[200]!)
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReady ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    report['status'] as String, 
                    style: TextStyle(
                      color: isReady ? Colors.green : Colors.orange, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                Text(
                  dateFormat.format(report['date'] as DateTime), 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(report['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(report['facility'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            
            const Divider(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isReady ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading report...'))
                      );
                    } : null,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady ? AppTheme.primaryTeal.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      foregroundColor: isReady ? AppTheme.primaryTeal : Colors.grey,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
