import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/hospital_model.dart';

final healthcareRepositoryProvider = Provider((ref) => HealthcareRepository());

class HealthcareRepository {
  static const String _getAllStoresQuery = r'''
    query GetAllStores($storeType: String, $search: String) {
      stores {
        allStores(isActive: true, storeType: $storeType, search: $search) {
          id
          name
          slug
          description
          email
          phoneNumber
          formattedAddress
          city
          latitude
          longitude
          storeType
          isActive
        }
      }
    }
  ''';

  Future<List<Hospital>> fetchStores({String? type, String? search}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_getAllStoresQuery),
      variables: {
        if (type != null) 'storeType': type.toUpperCase(),
        if (search != null && search.isNotEmpty) 'search': search,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      // If storeType argument is not supported, fallback to all
      if (result.exception!.graphqlErrors.any((e) => e.message.contains('Unknown argument'))) {
         return fetchStores(type: null, search: search);
      }
      throw result.exception!;
    }

    final dynamic allStoresData = result.data?['stores']?['allStores'];
    List storesJson = [];

    if (allStoresData is Map && allStoresData.containsKey('edges')) {
      storesJson = (allStoresData['edges'] as List)
          .map((edge) => edge['node'])
          .toList();
    } else if (allStoresData is List) {
      storesJson = allStoresData;
    }

    return storesJson.map((json) => Hospital.fromJson(json)).toList();
  }

  Future<Hospital?> getHospitalDetail(String idOrSlug) async {
    const String hospitalDetailQuery = r'''
      query GetHospitalDetail($id: ID, $slug: String) {
        storeByIdOrSlug(id: $id, slug: $slug) {
          id
          name
          slug
          phoneNumber
          city
          storeType
          description
          formattedAddress
          children {
            edges {
              node {
                id
                name
                slug
                storeType
                city
              }
            }
          }
          doctors {
            id
            specialty
            isVerified
            user {
              username
              firstName
              lastName
            }
          }
          servicesList {
            id
            name
            description
          }
          labTests {
             id
             name
             description
             price
             turnaroundTime
             sampleType
          }
          products {
             id
             price
             product {
               name
               slug
               image {
                 imageUrl
               }
             }
          }
          ownerId
        }
      }
    ''';

    final isNumericId = RegExp(r'^\d+$').hasMatch(idOrSlug);
    // If it's a global ID (Base64), it will be passed as 'id'. 
    // If it's a slug (alphanumeric/hyphenated), it will be passed as 'slug'.
    // If it's a numeric ID, it will be passed as 'id'.
    final isGlobalId = !isNumericId && idOrSlug.length > 8 && idOrSlug.contains(RegExp(r'[A-Z]'));

    final QueryOptions options = QueryOptions(
      document: gql(hospitalDetailQuery),
      variables: (isNumericId || isGlobalId) ? {'id': idOrSlug} : {'slug': idOrSlug},
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['storeByIdOrSlug'];
    if (data == null) return null;
    return Hospital.fromJson(data);
  }

  Future<Map<String, dynamic>> createStore({
    required String name,
    required String storeType,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? phoneNumber,
    String? email,
  }) async {
    const String createStoreMutation = r'''
      mutation CreateStore($input: StoreInput!) {
        stores {
          createStore(input: $input) {
            success
            errors
            store {
              id
              name
              slug
            }
          }
        }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(createStoreMutation),
      variables: {
        'input': {
          'name': name,
          'storeType': storeType.toLowerCase(),
          'addressLine1': address,
          'latitude': latitude,
          'longitude': longitude,
          'description': description,
          'phone_number': phoneNumber,
          'email': email,
          'isActive': true,
        }
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    
    return result.data?['stores']?['createStore'] ?? {'success': false, 'errors': ['Unknown error']};
  }
}

final hospitalsProvider = FutureProvider.family<List<Hospital>, ({String? type, String? search})>((ref, args) async {
  final repository = ref.watch(healthcareRepositoryProvider);
  return repository.fetchStores(type: args.type, search: args.search);
});

final hospitalDetailProvider = FutureProvider.family<Hospital?, String>((ref, idOrSlug) async {
  final repository = ref.watch(healthcareRepositoryProvider);
  return repository.getHospitalDetail(idOrSlug);
});
