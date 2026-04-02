import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:app/core/api_client.dart';
import '../models/order_model.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());

class OrderRepository {
  static const String _myOrdersQuery = r'''
    query GetMyOrders($status: String) {
      orders {
        myOrders(status: $status) {
          id
          clientName
          status
          totalAmount
          orderDate
          user {
            firstName
            lastName
          }
          items {
            quantity
            finalPricePerUnit
            product {
              name
            }
          }
        }
      }
    }
  ''';

  Future<List<Order>> fetchMyOrders({String? status}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_myOrdersQuery),
      variables: status != null ? {'status': status} : {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['orders']?['myOrders'] as List?;
    if (data == null) return [];

    return data.map((json) => Order.fromJson(json)).toList();
  }
}

final myOrdersProvider = FutureProvider.family<List<Order>, String?>((ref, status) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchMyOrders(status: status);
});
