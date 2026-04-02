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
  final String? symptoms;
  final String? diagnosis;
  final String? treatmentPlan;
  final List<String> notes;

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
    this.symptoms,
    this.diagnosis,
    this.treatmentPlan,
    this.notes = const [],
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorName: json['doctorName'] ?? 'Unknown Doctor',
      patientName: json['patientName'],
      patientId: json['patientId']?.toString(),
      isTransferred: json['isTransferred'] ?? false,
      transferredFrom: json['transferredFrom'],
      specialization: json['specialization'] ?? 'General',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'pending',
      type: json['type'] ?? 'in-person',
      imageUrl: json['imageUrl'],
      symptoms: json['consultationNotes'] != null ? json['consultationNotes'] : null,
      notes: (json['notes'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
