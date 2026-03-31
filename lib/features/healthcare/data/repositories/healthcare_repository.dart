import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/hospital_model.dart';

final healthcareRepositoryProvider = Provider((ref) => HealthcareRepository());

class HealthcareRepository {
  static const String _getAllStoresQuery = r'''
    query GetAllStores($storeType: String) {
      stores {
        allStores(isActive: true, storeType: $storeType) {
          edges {
            node {
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
      }
    }
  ''';

  Future<List<Hospital>> fetchStores({String? type}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_getAllStoresQuery),
      variables: type != null ? {'storeType': type.toUpperCase()} : {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      // If storeType argument is not supported, fallback to all
      if (result.exception!.graphqlErrors.any((e) => e.message.contains('Unknown argument'))) {
         return fetchStores(type: null);
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
            id
            name
            slug
            storeType
            city
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
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(hospitalDetailQuery),
      variables: int.tryParse(idOrSlug) != null ? {'id': idOrSlug} : {'slug': idOrSlug},
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['storeByIdOrSlug'];
    if (data == null) return null;
    return Hospital.fromJson(data);
  }
}

final hospitalsProvider = FutureProvider.family<List<Hospital>, String?>((ref, type) async {
  final repository = ref.watch(healthcareRepositoryProvider);
  return repository.fetchStores(type: type);
});

final hospitalDetailProvider = FutureProvider.family<Hospital?, String>((ref, idOrSlug) async {
  final repository = ref.watch(healthcareRepositoryProvider);
  return repository.getHospitalDetail(idOrSlug);
});
