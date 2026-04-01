class Appointment {
  final String id;
  final String doctorName;
  final String? patientName; // Added for Doctor Dashboard
  final String? patientId;   // Added for Doctor Dashboard
  final bool isTransferred;  // Added for transfers tracking
  final String? transferredFrom; // Name of doctor who transferred
  final String specialization;
  final DateTime date;
  final String status; // 'pending', 'accomplished', 'cancelled'
  final String type; // 'telemedicine', 'in-person', 'lab'
  final String? imageUrl;

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
    );
  }
}
