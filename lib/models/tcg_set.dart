class TcgSet {
  final String id;
  final String name;
  final String? logo;
  final String? symbol;
  final String? releaseDate;
  final int? printedTotal; // Add missing property
  final int? total; // Add missing property

  TcgSet({
    required this.id,
    required this.name,
    this.logo,
    this.symbol,
    this.releaseDate,
    this.printedTotal,
    this.total,
  });

  factory TcgSet.fromJson(Map<String, dynamic> json) {
    return TcgSet(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['images']?['logo'] as String?,
      symbol: json['images']?['symbol'] as String?,
      releaseDate: json['releaseDate'] as String?,
      printedTotal: json['printedTotal'] as int?,
      total: json['total'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'images': {
        'logo': logo,
        'symbol': symbol,
      },
      'releaseDate': releaseDate,
      'printedTotal': printedTotal,
      'total': total,
    };
  }
}
