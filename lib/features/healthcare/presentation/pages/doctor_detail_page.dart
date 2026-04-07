import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/core/ui_utils.dart';

class DoctorDetailPage extends ConsumerWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorDetailProvider(doctorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
      ),
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return const Center(child: Text('Doctor not found'));
          }
          return _buildContent(context, doctor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: _buildBottomBar(context, doctorAsync.value),
    );
  }

  Widget _buildContent(BuildContext context, Doctor doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Header (Avatar + Basic Info)
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.backgroundWhite,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: doctor.user.profile?.avatar != null
                      ? Image.network(doctor.user.profile!.avatar!, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 50, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.fullName}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.specialty ?? 'General Physician',
                      style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} Reviews)',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Stats (Experience, Fee, Patients)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Experience', '${doctor.experience ?? 0} Years'),
              _buildStatItem('Patients', '1k+'), // Mock data
              _buildStatItem('Fee', '\$${doctor.consultationFee?.toStringAsFixed(0) ?? '0'}'),
            ],
          ),

          const SizedBox(height: 30),

          // Bio / About
          const Text(
            'About Doctor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            doctor.user.profile?.bio ?? 'This doctor hasn\'t provided a bio yet. They are a dedicated healthcare professional committed to providing the best patient care.',
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
          ),

          const SizedBox(height: 30),

          // Hospital Location
          if (doctor.hospital != null) ...[
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_hospital, color: AppTheme.primaryTeal),
                title: Text(doctor.hospital!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${doctor.hospital!.addressLine1 ?? ''}, ${doctor.hospital!.city ?? ''}'),
                trailing: const Icon(Icons.map_outlined),
              ),
            ),
          ],

          const SizedBox(height: 80), // Padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Doctor? doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryTeal),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (doctor != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BookingBottomSheet(doctor: doctor),
                    );
                  }
                },
                child: const Text('Book Consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingBottomSheet extends ConsumerStatefulWidget {
  final Doctor doctor;

  const BookingBottomSheet({super.key, required this.doctor});

  @override
  ConsumerState<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<BookingBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlotId;
  String _appointmentType = 'VIDEO'; // Default to video

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotsAsync = ref.watch(availableSlotsProvider((doctorId: widget.doctor.id, date: dateStr)));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Book Appointment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Date Selection
          const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == dateStr;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryTeal : AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(DateFormat('d').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appointment Type
          const Text('Appointment Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip('VIDEO', Icons.videocam_outlined),
              const SizedBox(width: 12),
              _buildTypeChip('IN_PERSON', Icons.local_hospital_outlined),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Time Slots
          const Text('Available Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          slotsAsync.when(
            data: (slots) {
              if (slots.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No slots available for this date.', style: TextStyle(color: AppTheme.textSecondary)));
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: slots.map((slot) {
                  final isSelected = _selectedSlotId == slot['id'];
                  final isBooked = slot['isBooked'] ?? false;
                  return GestureDetector(
                    onTap: isBooked ? null : () => setState(() => _selectedSlotId = slot['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : (isBooked ? AppTheme.backgroundWhite.withOpacity(0.5) : AppTheme.backgroundWhite),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        DateFormat('hh:mm a').format(DateTime.parse(slot['startTime'])),
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isBooked ? AppTheme.textSecondary.withOpacity(0.5) : Colors.black),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (e, s) => Text('Error loading slots: $e'),
          ),
          
          const SizedBox(height: 32),
          
          // Confirmation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlotId == null ? null : _handleBooking,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, IconData icon) {
    final isSelected = _appointmentType == value;
    return GestureDetector(
      onTap: () => setState(() => _appointmentType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primaryTeal : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(value.replaceAll('_', ' '), style: TextStyle(color: isSelected ? AppTheme.primaryTeal : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || user.role?.toUpperCase() == 'GUEST') {
      UIUtils.showAuthGuardDialog(context, message: 'You need an account to book an appointment with a doctor.');
      return;
    }
    
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final result = await ref.read(doctorsRepositoryProvider).bookAppointment(
        availabilityId: _selectedSlotId!,
        appointmentType: _appointmentType,
      );
      
      Navigator.pop(context); // Pop loading
      Navigator.pop(context); // Pop bottom sheet
      
      _showSuccessDialog(result);
    } catch (e) {
      Navigator.pop(context); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppTheme.accentTeal));
    }
  }

  void _showSuccessDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('Appointment Booked!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Your appointment is scheduled for ${DateFormat('MMM dd, yyyy').format(DateTime.parse(appointment['scheduledTime']))} at ${DateFormat('hh:mm a').format(DateTime.parse(appointment['scheduledTime']))}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
