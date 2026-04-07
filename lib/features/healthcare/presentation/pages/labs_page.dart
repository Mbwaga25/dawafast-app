import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:afyalink/features/healthcare/presentation/widgets/hospital_card.dart';
import 'package:afyalink/features/healthcare/presentation/pages/hospital_detail_page.dart';

class LabsPage extends ConsumerStatefulWidget {
  const LabsPage({super.key});

  @override
  ConsumerState<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends ConsumerState<LabsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final labsAsyncValue = ref.watch(hospitalsProvider((type: 'LAB', search: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Services'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.biotech, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Health Services',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find labs, book diagnostics, and get accurate results near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for tests or health services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Results
          Expanded(
            child: labsAsyncValue.when(
              data: (labs) {
                final filtered = labs.where((l) => 
                  l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (l.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No health services found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final lab = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => HospitalDetailPage(idOrSlug: lab.slug)
                        ));
                      },
                      child: HospitalCard(hospital: lab),
                    );
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
}
