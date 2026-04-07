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
  final List<LabTest>? labTests;
  final List<HospitalProduct>? products;

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
    this.labTests,
    this.products,
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
        ? _extractNodes(json['servicesList'] ?? json['services']).map((i) => HospitalService.fromJson(i)).toList()
        : null,
      labTests: json['labTests'] != null 
        ? _extractNodes(json['labTests']).map((i) => LabTest.fromJson(i)).toList()
        : null,
      products: json['products'] != null 
        ? _extractNodes(json['products']).map((i) => HospitalProduct.fromJson(i)).toList()
        : null,
    );
  }
}

class LabTest {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? turnaroundTime;
  final String? sampleType;

  LabTest({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.turnaroundTime,
    this.sampleType,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      name: json['name'] ?? 'Test',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      turnaroundTime: json['turnaroundTime'],
      sampleType: json['sampleType'],
    );
  }
}

class HospitalProduct {
  final String id;
  final String name;
  final String slug;
  final double price;
  final List<String> images;

  HospitalProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.images,
  });

  factory HospitalProduct.fromJson(Map<String, dynamic> json) {
    // Corrected to handle nested 'product' field from StoreProductType
    final productData = json['product'] ?? json;
    final List<String> imageUrls = [];
    
    // Check both plural 'images' and singular 'image' (from StoreProductType.product)
    if (productData['images'] != null) {
      for (var img in (productData['images'] as List)) {
        imageUrls.add(img['imageUrl'] ?? '');
      }
    } else if (productData['image'] != null) {
        imageUrls.add(productData['image']['imageUrl'] ?? '');
    } else if (json['image'] != null) {
        imageUrls.add(json['image']['imageUrl'] ?? '');
    }

    return HospitalProduct(
      id: json['id'] ?? productData['id'],
      name: productData['name'] ?? 'Product',
      slug: productData['slug'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      images: imageUrls,
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
