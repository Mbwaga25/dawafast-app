class Brand {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      logoUrl: json['logo'],
    );
  }
}
