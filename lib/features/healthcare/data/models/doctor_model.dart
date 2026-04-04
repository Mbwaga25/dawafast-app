import '../../../auth/data/models/user_model.dart';

class Doctor {
  final String id;
  final String? specialty;
  final bool isVerified;
  final String? licenseNumber;
  final int? experience;
  final double? consultationFee;
  final List<String> languages;
  final double rating;
  final int reviewCount;
  final List<dynamic>? availability;
  final HospitalShort? hospital;
  final UserShort user;

  Doctor({
    required this.id,
    this.specialty,
    this.isVerified = false,
    this.licenseNumber,
    this.experience,
    this.consultationFee,
    this.languages = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.availability,
    this.hospital,
    required this.user,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      specialty: json['specialty'],
      isVerified: json['isVerified'] ?? false,
      licenseNumber: json['licenseNumber']?.toString(),
      experience: json['experience'],
      consultationFee: json['consultationFee'] != null 
          ? (json['consultationFee'] as num).toDouble() 
          : null,
      languages: json['languages'] != null 
          ? List<String>.from(json['languages']) 
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      availability: json['availability'],
      hospital: json['hospital'] != null 
          ? HospitalShort.fromJson(json['hospital']) 
          : null,
      user: UserShort.fromJson(json['user']),
    );
  }

  String get fullName => '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
}

class HospitalShort {
  final String id;
  final String name;
  final String slug;
  final String? city;
  final String? addressLine1;

  HospitalShort({
    required this.id,
    required this.name,
    required this.slug,
    this.city,
    this.addressLine1,
  });

  factory HospitalShort.fromJson(Map<String, dynamic> json) {
    return HospitalShort(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unnamed Facility',
      slug: json['slug'] ?? '',
      city: json['city'],
      addressLine1: json['addressLine1'],
    );
  }
}

class UserShort {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? username;
  final ProfileShort? profile;

  UserShort({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
    this.profile,
  });

  factory UserShort.fromJson(Map<String, dynamic> json) {
    return UserShort(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      username: json['username'],
      profile: json['profile'] != null 
          ? ProfileShort.fromJson(json['profile']) 
          : null,
    );
  }
}

class ProfileShort {
  final String? bio;
  final String? avatar;
  final String? phoneNumber;

  ProfileShort({
    this.bio,
    this.avatar,
    this.phoneNumber,
  });

  factory ProfileShort.fromJson(Map<String, dynamic> json) {
    return ProfileShort(
      bio: json['bio'],
      avatar: json['avatar'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
