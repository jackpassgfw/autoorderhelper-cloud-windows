import '../auto_orders/models.dart' show NoteMedia;
import '../customers/models.dart';

class Product {
  Product({
    required this.id,
    required this.name,
    this.code,
    this.packaging,
    this.categoryName,
    this.categoryId,
    this.sp,
    this.english,
    this.distributorPriceAud,
    this.notes,
    this.currency,
    this.media = const [],
  });

  final int id;
  final String name;
  final String? code;
  final String? packaging;
  final String? categoryName;
  final int? categoryId;
  final int? sp;
  final String? english;
  final double? distributorPriceAud;
  final String? notes;
  final String? currency;
  final List<NoteMedia> media;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['product_name'] as String? ?? json['name'] as String? ?? '',
      code: json['product_code'] as String? ?? json['code'] as String?,
      packaging: json['packaging'] as String?,
      categoryName:
          json['category'] as String? ?? json['category_name'] as String?,
      categoryId: json['category_id'] as int?,
      sp: json['sp'] as int?,
      english: json['english'] as String?,
      distributorPriceAud:
          (json['distributor_price_aud'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? json['description'] as String?,
      currency: json['currency'] as String?,
      media: NoteMedia.fromJsonList(json['media']),
    );
  }
}

class ProductListResponse {
  ProductListResponse({required this.items, required this.meta});

  final List<Product> items;
  final PaginationMeta meta;

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return ProductListResponse(
      items: itemsJson
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class ProductFormData {
  ProductFormData({
    this.id,
    this.name = '',
    this.code,
    this.packaging,
    this.sp,
    this.english,
    this.distributorPriceAud,
    this.notes,
    this.currency,
    this.categoryId,
    this.media = const [],
  });

  final int? id;
  String name;
  String? code;
  String? packaging;
  int? sp;
  String? english;
  double? distributorPriceAud;
  String? notes;
  String? currency;
  int? categoryId;
  List<NoteMedia> media;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{'product_name': name};
    if (code != null && code!.isNotEmpty) {
      payload['product_code'] = code;
    }
    if (packaging != null && packaging!.isNotEmpty) {
      payload['packaging'] = packaging;
    }
    if (sp != null) {
      payload['sp'] = sp;
    }
    if (english != null && english!.isNotEmpty) {
      payload['english'] = english;
    }
    if (notes != null && notes!.isNotEmpty) {
      payload['notes'] = notes;
    }
    if (distributorPriceAud != null) {
      payload['distributor_price_aud'] = distributorPriceAud;
    }
    if (currency != null && currency!.isNotEmpty) {
      payload['currency'] = currency;
    }
    if (categoryId != null) {
      payload['category_id'] = categoryId;
    }
    payload['media'] = media.map((item) => item.toJson()).toList();
    return payload;
  }

  factory ProductFormData.fromProduct(Product product) {
    return ProductFormData(
      id: product.id,
      name: product.name,
      code: product.code,
      packaging: product.packaging,
      sp: product.sp,
      english: product.english,
      distributorPriceAud: product.distributorPriceAud,
      notes: product.notes,
      currency: product.currency,
      categoryId: product.categoryId,
      media: product.media,
    );
  }
}
