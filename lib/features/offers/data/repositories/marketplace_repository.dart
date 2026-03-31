import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';
import '../models/product_model.dart';
import '../models/brand_model.dart';

final marketplaceRepositoryProvider = Provider((ref) => MarketplaceRepository());

class MarketplaceRepository {
  static const String _categoriesQuery = r'''
    query GetCategories($module: String) {
      allCategories(module: $module) {
        id
        name
        slug
        description
        image
        children {
          id
          name
          slug
          image
        }
      }
    }
  ''';

  static const String _allSegmentsQuery = r'''
    query GetAllSegments {
      allSegments {
        id
        title
        slug
        products {
          id
          name
          slug
          price
          originalPrice
          rating
          image {
            imageUrl
          }
          images {
            imageUrl
          }
        }
      }
    }
  ''';

  Future<List<ProductSegment>> fetchSegments() async {
    final QueryOptions options = QueryOptions(
      document: gql(_allSegmentsQuery),
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List segments = result.data?['allSegments'] ?? [];
    return segments.map((json) => ProductSegment.fromJson(json)).toList();
  }

  static const String _allProductsQuery = r'''
    query GetAllProducts($limit: Int, $offset: Int, $categorySlugs: [String], $brandSlugs: [String]) {
      allProducts(limit: $limit, offset: $offset, categorySlugs: $categorySlugs, brandSlugs: $brandSlugs) {
        id
        name
        slug
        price
        originalPrice
        rating
        description
        category {
          name
          slug
        }
        brand {
          name
          slug
        }
        images {
          imageUrl
          altText
          isPrimary
        }
      }
    }
  ''';

  Future<List<Category>> fetchCategories({String? module}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_categoriesQuery),
      variables: {'module': module},
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List categories = result.data?['allCategories'] ?? [];
    return categories.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<Product>> fetchProducts({int? limit, int? offset, List<String>? categorySlugs, List<String>? brandSlugs}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_allProductsQuery),
      variables: {
        'limit': limit, 
        'offset': offset,
        if (categorySlugs != null) 'categorySlugs': categorySlugs,
        if (brandSlugs != null) 'brandSlugs': brandSlugs,
      },
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List products = result.data?['allProducts'] ?? [];
    return products.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProductDetail(String idOrSlug) async {
    const String productDetailQuery = r'''
      query GetProductDetail($id: ID, $slug: String) {
        productByIdOrSlug(id: $id, slug: $slug) {
          id
          name
          slug
          description
          price
          rating
          images {
            imageUrl
          }
          category {
            name
            slug
          }
          allStoreListings {
            id
            store {
              id
              name
            }
            isAvailable
            price
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(productDetailQuery),
      variables: int.tryParse(idOrSlug) != null ? {'id': idOrSlug} : {'slug': idOrSlug},
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final data = result.data?['productByIdOrSlug'];
    if (data == null) return null;
    return Product.fromJson(data);
  }

  static const String _allBrandsQuery = r'''
    query GetAllBrands($limit: Int, $offset: Int) {
      allBrands(limit: $limit, offset: $offset) {
        id
        name
        slug
        description
        logo
      }
    }
  ''';

  Future<List<Brand>> fetchBrands({int? limit, int? offset}) async {
    final QueryOptions options = QueryOptions(
      document: gql(_allBrandsQuery),
      variables: {'limit': limit, 'offset': offset},
      fetchPolicy: FetchPolicy.cacheAndNetwork,
    );

    final QueryResult result = await ApiClient.client.value.query(options);

    if (result.hasException) {
      throw result.exception!;
    }

    final List brands = result.data?['allBrands'] ?? [];
    return brands.map((json) => Brand.fromJson(json)).toList();
  }
}

final categoriesProvider = FutureProvider.family<List<Category>, String?>((ref, module) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchCategories(module: module);
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchProducts(limit: 20);
});

final productDetailProvider = FutureProvider.family<Product?, String>((ref, idOrSlug) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.getProductDetail(idOrSlug);
});

final allSegmentsProvider = FutureProvider<List<ProductSegment>>((ref) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchSegments();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchBrands();
});

final relatedProductsProvider = FutureProvider.family<List<Product>, String>((ref, categorySlug) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchProducts(limit: 10, categorySlugs: [categorySlug]);
});

final similarBrandsProvider = FutureProvider.family<List<Product>, String>((ref, brandSlug) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.fetchProducts(limit: 10, brandSlugs: [brandSlug]);
});
