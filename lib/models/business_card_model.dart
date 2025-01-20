class BusinessCard {
  final String id;
  final String name;
  final String? title;
  final String? company;
  final String? email;
  final String? phone;
  final String? website;
  final String? imageUrl;
  final DateTime createdAt;

  BusinessCard({
    required this.id,
    required this.name,
    this.title,
    this.company,
    this.email,
    this.phone,
    this.website,
    this.imageUrl,
    required this.createdAt,
  });

  factory BusinessCard.fromJson(Map<String, dynamic> json) => BusinessCard(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String?,
        company: json['company'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'company': company,
        'email': email,
        'phone': phone,
        'website': website,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
