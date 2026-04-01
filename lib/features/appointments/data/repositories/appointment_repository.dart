import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/auth/data/models/user_model.dart';
// Providers
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  // MOCK: Delay to simulate API
  await Future.delayed(const Duration(milliseconds: 600));
  
  return [
    Appointment(
      id: 'A123',
      doctorName: 'Dr. Sarah Johnson',
      specialization: 'Cardiology',
      date: DateTime.now().add(const Duration(days: 2)),
      status: 'pending',
      type: 'telemedicine',
    ),
    Appointment(
      id: 'A124',
      doctorName: 'City Lab Diagnostics',
      specialization: 'Blood Test',
      date: DateTime.now().add(const Duration(days: 5)),
      status: 'pending',
      type: 'lab',
    ),
  ];
});

final pastAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  // MOCK: Delay to simulate API
  await Future.delayed(const Duration(milliseconds: 600));
  
  return [
    Appointment(
      id: 'A099',
      doctorName: 'Dr. Mike Ross',
      specialization: 'General Physician',
      date: DateTime.now().subtract(const Duration(days: 14)),
      status: 'accomplished',
      type: 'in-person',
    ),
  ];
});

// ------------- DOCTOR PROVIDERS ------------- //

class DoctorAppointmentsNotifier extends StateNotifier<AsyncValue<List<Appointment>>> {
  final Future<User?> Function() getCurrentUser;
  
  DoctorAppointmentsNotifier(this.getCurrentUser) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user.role?.toUpperCase() != 'DOCTOR') {
        state = const AsyncValue.data([]);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 600));

      final data = [
        Appointment(
          id: 'D001',
          doctorName: user.fullName,
          patientName: 'John Doe',
          patientId: 'P01',
          specialization: 'Cardiology',
          date: DateTime.now().add(const Duration(hours: 2)),
          status: 'pending',
          type: 'telemedicine',
        ),
        Appointment(
          id: 'D002',
          doctorName: user.fullName,
          patientName: 'Robert Smith',
          patientId: 'P02',
          specialization: 'Cardiology',
          date: DateTime.now().subtract(const Duration(hours: 4)),
          status: 'accomplished',
          type: 'in-person',
        ),
      ];
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateAppointmentStatus(String appointmentId, String newStatus) {
    if (state is AsyncData) {
      final list = state.value!;
      final updatedList = list.map((a) {
        if (a.id == appointmentId) {
          // Creating a copy with new status
          return Appointment(
            id: a.id,
            doctorName: a.doctorName,
            patientName: a.patientName,
            patientId: a.patientId,
            isTransferred: a.isTransferred,
            transferredFrom: a.transferredFrom,
            specialization: a.specialization,
            date: a.date,
            status: newStatus,
            type: a.type,
            imageUrl: a.imageUrl,
          );
        }
        return a;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}

final doctorAppointmentsProvider = StateNotifierProvider<DoctorAppointmentsNotifier, AsyncValue<List<Appointment>>>((ref) {
  return DoctorAppointmentsNotifier(() => ref.read(currentUserProvider.future));
});

final myPatientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {'id': 'P01', 'name': 'John Doe', 'condition': 'Hypertension', 'lastVisit': '2023-11-01', 'status': 'Assigned'},
    {'id': 'P02', 'name': 'Sarah Connor', 'condition': 'Routine Checkup', 'lastVisit': '2023-10-15', 'status': 'Attended'},
    {'id': 'P03', 'name': 'Michael Jordan', 'condition': 'Sports Injury Evaluation', 'lastVisit': '2023-11-10', 'status': 'Assigned'},
  ];
});

final transferredPatientsProvider = FutureProvider<List<Appointment>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return [
    Appointment(
      id: 'T001',
      doctorName: 'Me',
      patientName: 'Jane Smith',
      isTransferred: true,
      transferredFrom: 'Dr. Emily Chen',
      specialization: 'Cardiology',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'accomplished',
      type: 'in-person',
    ),
  ];
});

class AppointmentRepository {
  // Can be mapped to GraphQL later
}

final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());
