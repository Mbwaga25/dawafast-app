class Hospital {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? storeType;
  final bool isActive;

  final List<Hospital>? children;
  final List<HospitalDoctor>? doctors;
  final List<HospitalService>? services;

  Hospital({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.storeType,
    required this.isActive,
    this.children,
    this.doctors,
    this.services,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    // Helper to extract node list from Relay connection
    List<dynamic> _extractNodes(dynamic data) {
      if (data is Map && data.containsKey('edges')) {
        return (data['edges'] as List).map((edge) => edge['node']).toList();
      } else if (data is List) {
        return data;
      }
      return [];
    }

    return Hospital(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['formattedAddress'] ?? json['addressLine1'],
      city: json['city'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      storeType: json['storeType'],
      isActive: json['isActive'] ?? true,
      children: json['children'] != null 
        ? _extractNodes(json['children']).map((i) => Hospital.fromJson(i)).toList()
        : null,
      doctors: json['doctors'] != null 
        ? _extractNodes(json['doctors']).map((i) => HospitalDoctor.fromJson(i)).toList()
        : null,
      services: (json['servicesList'] ?? json['services']) != null 
        ? (json['servicesList'] ?? json['services'] as List).map((i) => HospitalService.fromJson(i)).toList()
        : null,
    );
  }
}

class HospitalDoctor {
  final String id;
  final String fullName;
  final String specialty;
  final bool isVerified;

  HospitalDoctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    this.isVerified = false,
  });

  factory HospitalDoctor.fromJson(Map<String, dynamic> json) {
    // Handling nested user data from backend
    final userJson = json['user'] ?? {};
    return HospitalDoctor(
      id: json['id'],
      fullName: '${userJson['firstName'] ?? ''} ${userJson['lastName'] ?? ''}'.trim().isNotEmpty 
        ? '${userJson['firstName'] ?? ''} ${userJson['lastName'] ?? ''}'.trim()
        : userJson['username'] ?? 'Doctor',
      specialty: json['specialty'] ?? 'Specialist',
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class HospitalService {
  final String id;
  final String name;
  final String? description;

  HospitalService({
    required this.id,
    required this.name,
    this.description,
  });

  factory HospitalService.fromJson(Map<String, dynamic> json) {
    return HospitalService(
      id: json['id'],
      name: json['name'] ?? 'Service',
      description: json['description'],
    );
  }
}
