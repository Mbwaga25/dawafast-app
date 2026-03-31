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
      imageUrls.add(json['image']['imageUrl'] as String);
    }
    
    // Handle 'images' field (list)
    var imagesList = json['images'] as List? ?? [];
    for (var img in imagesList) {
      final url = img['imageUrl'] as String;
      if (!imageUrls.contains(url)) {
        imageUrls.add(url);
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
    var productsList = json['products'] as List? ?? [];
    List<Product> products = productsList.map((p) => Product.fromJson(p)).toList();

    return ProductSegment(
      id: json['id'],
      title: json['title'] ?? json['slug'],
      slug: json['slug'],
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
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
      children: json['children'] != null
          ? (json['children'] as List).map((i) => Category.fromJson(i)).toList()
          : null,
    );
  }
}
