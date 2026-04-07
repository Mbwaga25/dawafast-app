class Product {
  final String id;
  final String name;
  final String slug;
  final double price;
  final double? originalPrice;
  final double? rating;
  final String? description;
  final String? categoryName;
  final String? categorySlug;
  final String? brandName;
  final String? brandSlug;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.originalPrice,
    this.rating,
    this.description,
    this.categoryName,
    this.categorySlug,
    this.brandName,
    this.brandSlug,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imageUrls = [];
    
    // Handle 'image' field (single)
    if (json['image'] != null) {
      if (json['image'] is String) {
        imageUrls.add(json['image']);
      } else if (json['image'] is Map && json['image']['imageUrl'] != null) {
        imageUrls.add(json['image']['imageUrl'].toString());
      }
    }
    
    // Handle 'images' field (list)
    var imagesList = json['images'] as List? ?? [];
    for (var img in imagesList) {
      if (img != null) {
        if (img is String) {
          if (!imageUrls.contains(img)) imageUrls.add(img);
        } else if (img is Map && img['imageUrl'] != null) {
          final url = img['imageUrl'].toString();
          if (!imageUrls.contains(url)) imageUrls.add(url);
        }
      }
    }

    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      price: double.parse(json['price'].toString()),
      originalPrice: json['originalPrice'] != null ? double.parse(json['originalPrice'].toString()) : null,
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      description: json['description'],
      categoryName: json['category']?['name'],
      categorySlug: json['category']?['slug'],
      brandName: json['brand']?['name'],
      brandSlug: json['brand']?['slug'],
      images: imageUrls,
    );
  }

  double get discountPercentage {
    if (originalPrice == null || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }
}

class ProductSegment {
  final String id;
  final String title;
  final String slug;
  final List<Product> products;

  ProductSegment({
    required this.id,
    required this.title,
    required this.slug,
    required this.products,
  });

  factory ProductSegment.fromJson(Map<String, dynamic> json) {
    List<dynamic> _extractNodes(dynamic data) {
      if (data is Map && data.containsKey('edges')) {
        return (data['edges'] as List).map((edge) => edge['node']).toList();
      } else if (data is List) {
        return data;
      }
      return [];
    }

    var productsList = _extractNodes(json['products']);
    List<Product> products = productsList.map((p) => Product.fromJson(p)).toList();

    return ProductSegment(
      id: json['id'],
      title: json['title'] ?? json['slug'] ?? 'Segment',
      slug: json['slug'] ?? '',
      products: products,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String slug;
  final String? image;
  final List<Category>? children;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<dynamic> _extractNodes(dynamic data) {
      if (data is Map && data.containsKey('edges')) {
        return (data['edges'] as List).map((edge) => edge['node']).toList();
      } else if (data is List) {
        return data;
      }
      return [];
    }

    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
      children: json['children'] != null
          ? _extractNodes(json['children']).map((i) => Category.fromJson(i)).toList()
          : null,
    );
  }
}
