import 'package:intl/intl.dart';

class Referral {
  final String id;
  final String patientId;
  final String patientName;
  final String referringDoctorName;
  final String providerType; // 'DOCTOR', 'LAB', 'PHARMACY'
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED'
  final String? reason;
  final String? notes;
  final DateTime createdAt;
  final List<ReferralItem> items;
  final List<ReferralAttachment> attachments;

  Referral({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.referringDoctorName,
    required this.providerType,
    required this.status,
    this.reason,
    this.notes,
    required this.createdAt,
    this.items = const [],
    this.attachments = const [],
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    final patientUser = json['patient']?['user'] ?? {};
    final referringUser = json['referringDoctor']?['user'] ?? {};
    
    return Referral(
      id: json['id'],
      patientId: json['patient']?['id'] ?? '',
      patientName: '${patientUser['firstName'] ?? ''} ${patientUser['lastName'] ?? ''}'.trim(),
      referringDoctorName: 'Dr. ${referringUser['firstName'] ?? ''} ${referringUser['lastName'] ?? ''}'.trim(),
      providerType: json['providerType'] ?? 'DOCTOR',
      status: json['status'] ?? 'PENDING',
      reason: json['reason'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      items: (json['items'] as List? ?? []).map((i) => ReferralItem.fromJson(i)).toList(),
      attachments: (json['attachments'] as List? ?? []).map((a) => ReferralAttachment.fromJson(a)).toList(),
    );
  }
}

class ReferralItem {
  final String id;
  final String itemName;
  final String itemType;
  final int quantity;
  final String? notes;

  ReferralItem({
    required this.id,
    required this.itemName,
    required this.itemType,
    this.quantity = 1,
    this.notes,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      itemType: json['itemType'] ?? '',
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
    );
  }
}

class ReferralAttachment {
  final String id;
  final String fileName;
  final String fileType;
  final String fileUrl;

  ReferralAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
  });

  factory ReferralAttachment.fromJson(Map<String, dynamic> json) {
    return ReferralAttachment(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}

class PatientHistoryRecord {
  final String id;
  final DateTime date;
  final String issue;
  final String consultationNotes;
  final String prescription;
  final String doctorName;

  PatientHistoryRecord({
    required this.id,
    required this.date,
    required this.issue,
    required this.consultationNotes,
    required this.prescription,
    required this.doctorName,
  });

  factory PatientHistoryRecord.fromJson(Map<String, dynamic> json) {
    final doctorUser = json['doctor']?['user'] ?? {};
    return PatientHistoryRecord(
      id: json['id'],
      date: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      issue: json['issue'] ?? '',
      consultationNotes: json['consultationNotes'] ?? '',
      prescription: json['prescription'] ?? '',
      doctorName: 'Dr. ${doctorUser['lastName'] ?? 'Specialist'}',
    );
  }
}
