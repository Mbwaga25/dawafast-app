class User {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;
  final PatientProfile? patientProfile;
  final DoctorProfile? doctorProfile;
  final PharmacistProfile? pharmacistProfile;
  final LabProfile? labProfile;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.role,
    this.patientProfile,
    this.doctorProfile,
    this.pharmacistProfile,
    this.labProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      patientProfile: json['patientProfile'] != null 
        ? PatientProfile.fromJson(json['patientProfile']) 
        : null,
      doctorProfile: json['doctorProfile'] != null 
        ? DoctorProfile.fromJson(json['doctorProfile']) 
        : null,
      pharmacistProfile: json['pharmacistProfile'] != null 
        ? PharmacistProfile.fromJson(json['pharmacistProfile']) 
        : null,
      labProfile: json['labProfile'] != null 
        ? LabProfile.fromJson(json['labProfile']) 
        : null,
    );
  }

  String get fullName => (firstName != null || lastName != null) 
    ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
    : username;

  bool get isPatient => patientProfile != null || role == 'PATIENT';
  bool get isDoctor => doctorProfile != null || role == 'DOCTOR';
  bool get isPharmacist => pharmacistProfile != null || role == 'PHARMACIST';
  bool get isLabTechnician => labProfile != null || role == 'LAB_TECHNICIAN';
}

class PatientProfile {
  final String id;
  final String? bloodType;
  final String? gender;
  final String? location;

  PatientProfile({
    required this.id,
    this.bloodType,
    this.gender,
    this.location,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
      bloodType: json['bloodType'],
      gender: json['gender'],
      location: json['location'],
    );
  }
}

class DoctorProfile {
  final String id;
  final String? specialty;
  final bool isVerified;

  DoctorProfile({
    required this.id,
    this.specialty,
    this.isVerified = false,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'],
      specialty: json['specialty'],
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class PharmacistProfile {
  final String id;
  final String? pharmacyName;
  final bool isVerified;

  PharmacistProfile({
    required this.id,
    this.pharmacyName,
    this.isVerified = false,
  });

  factory PharmacistProfile.fromJson(Map<String, dynamic> json) {
    return PharmacistProfile(
      id: json['id'],
      pharmacyName: json['pharmacyName'],
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class LabProfile {
  final String id;
  final String? labName;
  final bool isVerified;

  LabProfile({
    required this.id,
    this.labName,
    this.isVerified = false,
  });

  factory LabProfile.fromJson(Map<String, dynamic> json) {
    return LabProfile(
      id: json['id'],
      labName: json['labName'],
      isVerified: json['isVerified'] ?? false,
    );
  }
}
