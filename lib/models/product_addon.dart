class ProductAddon {
  const ProductAddon({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final double price;
  final bool isAvailable;

  factory ProductAddon.fromMap(Map<String, dynamic> map) {
    return ProductAddon(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'isAvailable': isAvailable,
      };

  ProductAddon copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
  }) {
    return ProductAddon(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
