import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:app/core/api_client.dart';
import '../models/hospital_model.dart';

class MutationResult {
  final bool success;
  final String? message;
  final dynamic data;

  MutationResult({required this.success, this.message, this.data});
}

class PharmacyReport {
  final int pendingCount;
  final int accomplishedCount;
  final int transferredCount;
  final int missedCount;
  final double totalRevenue;
  final List<dynamic> pendingItems;
  final List<dynamic> accomplishedItems;
  final List<dynamic> transferredItems;
  final List<dynamic> missedItems;

  PharmacyReport({
    required this.pendingCount,
    required this.accomplishedCount,
    required this.transferredCount,
    required this.missedCount,
    required this.totalRevenue,
    this.pendingItems = const [],
    this.accomplishedItems = const [],
    this.transferredItems = const [],
    this.missedItems = const [],
  });

  factory PharmacyReport.fromJson(Map<String, dynamic> json) {
    return PharmacyReport(
      pendingCount: json['pendingCount'] ?? 0,
      accomplishedCount: json['accomplishedCount'] ?? 0,
      transferredCount: json['transferredCount'] ?? 0,
      missedCount: json['missedCount'] ?? 0,
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      pendingItems: json['pendingItems'] ?? [],
      accomplishedItems: json['accomplishedItems'] ?? [],
      transferredItems: json['transferredItems'] ?? [],
      missedItems: json['missedItems'] ?? [],
    );
  }
}

class CurrencySettings {
  final String code;
  final String symbol;

  CurrencySettings({required this.code, required this.symbol});

  factory CurrencySettings.fromJson(Map<String, dynamic> json) {
    // Map code to symbol if not provided by backend
    final code = json['baseCurrency'] ?? 'TZS';
    final symbols = {'TZS': '/=', 'USD': '\$', 'KES': 'KSh', 'UGX': 'USh', 'EUR': '€', 'GBP': '£'};
    return CurrencySettings(
      code: code,
      symbol: symbols[code] ?? code,
    );
  }
}

final pharmacyRepositoryProvider = Provider((ref) => PharmacyRepository());

class PharmacyRepository {
  static const String _searchProductsQuery = r'''
    query SearchGlobalProducts($search: String) {
      products {
        allProducts(search: $search, isApproved: true, limit: 20) {
          id
          name
          slug
          description
          price
          image {
            imageUrl
          }
          variants {
            id
            name
            price
          }
        }
      }
    }
  ''';

  static const String _submitProductMutation = r'''
    mutation SubmitProductForReview($name: String!, $categoryId: ID, $description: String, $basePrice: Decimal) {
      stores {
        submitProductForReview(name: $name, categoryId: $categoryId, description: $description, basePrice: $basePrice) {
          success
          message
        }
      }
    }
  ''';

  static const String _toggleStoreProductAvailabilityMutation = r'''
    mutation ToggleAvailability($id: ID!, $available: Boolean!) {
      stores {
        toggleStoreProductAvailability(storeProductId: $id, isAvailable: $available) {
          success
          message
        }
      }
    }
  ''';

  static const String _updateStoreProfileMutation = r'''
    mutation UpdateProfile($id: ID!, $description: String, $image: String, $isSmart: Boolean) {
      stores {
        updateStoreProfile(id: $id, description: $description, image: $image, isSmart: $isSmart) {
          success
          message
        }
      }
    }
  ''';

  static const String _allCategoriesQuery = r'''
    query GetAllCategories {
      products {
        allCategories(module: "pharmacy") {
          id
          name
          slug
        }
      }
    }
  ''';

  static const String _allBrandsQuery = r'''
    query GetAllBrands {
      products {
        allBrands(limit: 100) {
          id
          name
        }
      }
    }
  ''';

  static const String _getPrescriptionsQuery = r'''
    query GetPharmacyPrescriptions($storeId: ID!) {
      consultations {
        myPharmacyPrescriptions(storeId: $storeId) {
          id
          status
          createdAt
          notes
          consultation {
            patient { firstName lastName }
            doctor { user { firstName lastName } }
          }
          items {
            id
            medicineName
            dosage
            duration
            instructions
          }
        }
      }
    }
  ''';

  static const String _dispensePrescriptionMutation = r'''
    mutation DispensePrescription($id: ID!, $notes: String!) {
      consultations {
        dispensePrescription(id: $id, notes: $notes) {
          success
          errors
        }
      }
    }
  ''';

  static const String _toggleAvailabilityMutation = r'''
    mutation ToggleAvailability($id: ID!, $available: Boolean!) {
      stores {
        toggleStoreProductAvailability(storeProductId: $id, isAvailable: $available) {
          success
          message
          storeProduct {
            id
            isAvailable
          }
        }
      }
    }
  ''';

  static const String _pharmacyReportQuery = r'''
    query GetPharmacyReport($storeId: ID!) {
      stores {
        pharmacyReport(storeId: $storeId) {
          pendingCount
          accomplishedCount
          transferredCount
          missedCount
          totalRevenue
          pendingItems { id clientName status totalAmount orderDate }
          accomplishedItems { id clientName status totalAmount orderDate }
          transferredItems { id clientName status totalAmount orderDate }
          missedItems { id clientName status totalAmount orderDate }
        }
      }
    }
  ''';

  static const String _activeCurrencyQuery = r'''
    query GetActiveCurrency {
      stores {
        activeCurrency {
          baseCurrency
        }
      }
    }
  ''';

  static const String _updateProfileMutation = r'''
    mutation UpdateStoreProfile($id: ID!, $description: String, $image: String, $isSmart: Boolean) {
      stores {
        updateStoreProfile(id: $id, description: $description, image: $image, isSmart: $isSmart) {
          success
          message
          store {
            id
            description
            isSmart
          }
        }
      }
    }
  ''';

  static const String _referPatientMutation = r'''
    mutation ReferPatient($patientId: ID!, $providerType: String!, $providerId: ID!, $reason: String!, $notes: String) {
      referPatient(patientId: $patientId, providerType: $providerType, providerId: $providerId, reason: $reason, notes: $notes) {
        success
        errors
      }
    }
  ''';

  static const String _searchDoctorsQuery = r'''
    query SearchDoctors($search: String) {
      users {
        allUsers(role: "DOCTOR", search: $search) {
          edges {
            node {
              id
              username
              doctorProfile {
                id
                specialization
                user { firstName lastName }
              }
            }
          }
        }
      }
    }
  ''';

  static const String _getStoreProductsQuery = r'''
    query GetStoreProducts($storeId: ID) {
      stores {
        storeProducts(storeId: $storeId) {
          id
          price
          quantity
          isAvailable
          product {
            id
            name
            slug
            image {
              imageUrl
            }
          }
        }
      }
    }
  ''';

  static const String _patientHistoryQuery = r'''
    query GetPatientHistory($patientId: String!) {
      appointments {
        patientHistory(patientId: $patientId) {
          id
          scheduledTime
          status
          reason
          clinicalNotes
          doctor {
            user {
              firstName
              lastName
            }
          }
        }
        receivedReferrals {
          id
          referringDoctor { user { firstName lastName } }
          reason
          createdAt
          status
          responseNotes
        }
      }
    }
  ''';

  static const String _updateReferralStatusMutation = r'''
    mutation UpdateReferralStatus($id: ID!, $status: String!, $notes: String) {
      updateReferralStatus(referralId: $id, status: $status, responseNotes: $notes) {
        success
        errors
      }
    }
  ''';

  Future<List<dynamic>> searchProducts(String query) async {
    final options = QueryOptions(
      document: gql(_searchProductsQuery),
      variables: {'search': query},
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['products']?['allProducts'] ?? [];
  }

  Future<MutationResult> cloneProduct({
    required String storeId,
    required String productId,
    String? variantId,
    required double price,
    required int stock,
  }) async {
    final options = MutationOptions(
      document: gql(_cloneProductMutation),
      variables: {
        'input': {
          'storeId': storeId,
          'productId': productId,
          'variantId': variantId,
          'price': price,
          'stock': stock,
          'isAvailable': true,
        }
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['stores']?['addOrUpdateStoreProduct'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: (data?['errors'] as List?)?.join(', ') ?? data?['warning'],
      data: data?['storeProduct'],
    );
  }

  Future<MutationResult> toggleAvailability(String storeProductId, bool isAvailable) async {
    final options = MutationOptions(
      document: gql(_toggleAvailabilityMutation),
      variables: {'id': storeProductId, 'available': isAvailable},
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['stores']?['toggleStoreProductAvailability'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: data?['message'] ?? (data?['errors'] as List?)?.join(', '),
    );
  }

  Future<PharmacyReport> getPharmacyReport(String storeId) async {
    final options = QueryOptions(
      document: gql(_pharmacyReportQuery),
      variables: {'storeId': storeId},
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return PharmacyReport.fromJson(result.data?['stores']?['pharmacyReport'] ?? {});
  }

  Future<CurrencySettings> getActiveCurrency() async {
    final options = QueryOptions(document: gql(_activeCurrencyQuery));
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) return CurrencySettings(code: 'TZS', symbol: '/=');
    return CurrencySettings.fromJson(result.data?['stores']?['activeCurrency'] ?? {});
  }

  Future<MutationResult> updateProfile(String id, {String? description, String? imageBase64, bool? isSmart}) async {
    final options = MutationOptions(
      document: gql(_updateProfileMutation),
      variables: {
        'id': id,
        'description': description,
        'image': imageBase64,
        'isSmart': isSmart,
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['stores']?['updateStoreProfile'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: data?['message'],
    );
  }

  Future<MutationResult> submitProductToAdmin({
    required String name,
    String? categoryId,
    String? description,
    double? price,
  }) async {
    final options = MutationOptions(
      document: gql(_submitProductMutation),
      variables: {
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'basePrice': price,
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['stores']?['submitProductForReview'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: data?['message'],
    );
  }

  Future<List<dynamic>> getStoreProducts(String storeId) async {
    final options = QueryOptions(
      document: gql(_getStoreProductsQuery),
      variables: {'storeId': storeId},
      fetchPolicy: FetchPolicy.networkOnly,
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['stores']?['storeProducts'] ?? [];
  }

  Future<MutationResult> updateStock({
    required String storeId,
    required String productId,
    required int stock,
    required double price,
  }) async {
    final options = MutationOptions(
      document: gql(_cloneProductMutation),
      variables: {
        'input': {
          'storeId': storeId,
          'productId': productId,
          'stock': stock,
          'price': price,
          'isAvailable': true,
        }
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['stores']?['addOrUpdateStoreProduct'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: (data?['errors'] as List?)?.join(', '),
    );
  }

  Future<List<dynamic>> getCategories() async {
    final options = QueryOptions(document: gql(_allCategoriesQuery));
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['products']?['allCategories'] ?? [];
  }

  Future<List<dynamic>> getBrands() async {
    final options = QueryOptions(document: gql(_allBrandsQuery));
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['products']?['allBrands'] ?? [];
  }

  Future<List<dynamic>> getPrescriptions(String storeId) async {
    final options = QueryOptions(
      document: gql(_getPrescriptionsQuery), 
      variables: {'storeId': storeId},
      fetchPolicy: FetchPolicy.networkOnly,
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['consultations']?['myPharmacyPrescriptions'] ?? [];
  }

  Future<MutationResult> dispensePrescription(String id, String notes) async {
    final options = MutationOptions(
      document: gql(_dispensePrescriptionMutation),
      variables: {'id': id, 'notes': notes},
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    final data = result.data?['consultations']?['dispensePrescription'];
    return MutationResult(
      success: data?['success'] ?? false,
      message: (data?['errors'] as List?)?.join(', '),
    );
  }

  Future<List<dynamic>> searchDoctors(String query) async {
    final options = QueryOptions(
      document: gql(_searchDoctorsQuery),
      variables: {'search': query},
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['allUsers']?['edges'] ?? [];
  }

  Future<bool> referToDoctor({
    required String patientId,
    required String doctorId,
    required String reason,
    String? notes,
  }) async {
    final options = MutationOptions(
      document: gql(_referPatientMutation),
      variables: {
        'patientId': patientId,
        'providerType': 'doctor',
        'providerId': doctorId,
        'reason': reason,
        'notes': notes,
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['referPatient']?['success'] ?? false;
  }

  Future<Map<String, List<dynamic>>> getPatientHistory(String patientId) async {
    final options = QueryOptions(
      document: gql(_patientHistoryQuery),
      variables: {'patientId': patientId},
    );
    final result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    
    final data = result.data?['appointments'] ?? {};
    return {
      'appointments': data['patientHistory'] ?? [],
      'referrals': data['receivedReferrals'] ?? [],
    };
  }

  Future<bool> updateReferralStatus(String id, String status, {String? notes}) async {
    final options = MutationOptions(
      document: gql(_updateReferralStatusMutation),
      variables: {
        'id': id,
        'status': status,
        'notes': notes,
      },
    );
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['updateReferralStatus']?['success'] ?? false;
  }
}

final pharmacyReportProvider = FutureProvider.family<PharmacyReport, String>((ref, storeId) async {
  return ref.watch(pharmacyRepositoryProvider).getPharmacyReport(storeId);
});

final activeCurrencyProvider = FutureProvider<CurrencySettings>((ref) async {
  return ref.watch(pharmacyRepositoryProvider).getActiveCurrency();
});
