class Brand {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logo;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      logo: json['logo'],
    );
  }
}
