import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:afyalink/features/healthcare/data/models/doctor_model.dart';
import 'package:afyalink/features/healthcare/presentation/pages/doctor_detail_page.dart';

class DoctorsPage extends ConsumerWidget {
  const DoctorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(doctorSearchQueryProvider);
    final specialtyFilter = ref.watch(doctorSpecialtyFilterProvider);
    
    final doctorsAsync = ref.watch(doctorsProvider((specialty: specialtyFilter, search: searchQuery)));
    final specialtiesAsync = ref.watch(specialtiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctors by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
              ),
              onChanged: (value) => ref.read(doctorSearchQueryProvider.notifier).state = value,
            ),
          ),

          // Specialty Filters
          specialtiesAsync.when(
            data: (specialties) => SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialties.length + 1,
                itemBuilder: (context, index) {
                  final label = index == 0 ? 'All' : specialties[index - 1];
                  final isSelected = specialtyFilter == label;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(doctorSpecialtyFilterProvider.notifier).state = label;
                        }
                      },
                      selectedColor: AppTheme.primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Doctors List
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const Center(child: Text('No doctors found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _DoctorCard(doctor: doctor);
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

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailPage(doctorId: doctor.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: doctor.user.profile?.avatar != null
                      ? Image.network(doctor.user.profile!.avatar!, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 40, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.fullName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty ?? 'General Practitioner',
                      style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} Reviews)',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exp: ${doctor.experience ?? 0} Years',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Fee: \$${doctor.consultationFee?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
