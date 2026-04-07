class Appointment {
  final String id;
  final String doctorName;
  final String? patientName;
  final String? patientId;
  final bool isTransferred;
  final String? transferredFrom;
  final String specialization;
  final DateTime date;
  final String status;
  final String type;
  final String? imageUrl;
  final String? issue; // Changed from symptoms
  final String? consultationNotes; // Changed from diagnosis
  final String? prescription; // Changed from treatmentPlan
  final List<String> notes;
  final String? doctorUserId; // New field for ratings

  Appointment({
    required this.id,
    required this.doctorName,
    this.patientName,
    this.patientId,
    this.isTransferred = false,
    this.transferredFrom,
    required this.specialization,
    required this.date,
    required this.status,
    required this.type,
    this.imageUrl,
    this.issue,
    this.consultationNotes,
    this.prescription,
    this.notes = const [],
    this.doctorUserId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorName: json['doctor'] != null ? "${json['doctor']['user']['firstName']} ${json['doctor']['user']['lastName']}" : (json['doctorName'] ?? 'Unknown Doctor'),
      patientName: json['patientName'] ?? (json['patient'] != null ? "${json['patient']['user']['firstName']} ${json['patient']['user']['lastName']}" : null),
      patientId: json['patient']?['user']?['id']?.toString() ?? json['patientId']?.toString(),
      isTransferred: json['isTransferred'] ?? false,
      transferredFrom: json['transferredFrom'],
      specialization: json['doctor']?['specialty'] ?? json['specialization'] ?? 'General',
      date: DateTime.parse(json['scheduledTime'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      type: json['appointmentType'] ?? json['type'] ?? 'in-person',
      imageUrl: json['imageUrl'],
      issue: json['issue'],
      consultationNotes: json['consultationNotes'],
      prescription: json['prescription'],
      notes: (json['notes'] as List? ?? []).map((e) => e.toString()).toList(),
      doctorUserId: json['doctor']?['user']?['id']?.toString(),
    );
  }
}
