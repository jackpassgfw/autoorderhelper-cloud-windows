import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../customers/models.dart';
import 'models.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductsRepository(client);
});

class ProductsRepository {
  ProductsRepository(this._client);

  final Dio _client;

  Future<ProductListResponse> fetchProducts({
    int page = 1,
    int pageSize = 50,
    int? categoryId,
  }) async {
    final response = await _client.get<dynamic>(
      '/products/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (categoryId != null) 'category_id': categoryId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductListResponse.fromJson(data);
    }
    if (data is List) {
      return ProductListResponse(
        items: data
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList(),
        meta: PaginationMeta(page: page, pageSize: pageSize, total: data.length),
      );
    }
    return ProductListResponse(
      items: const [],
      meta: PaginationMeta(page: page, pageSize: pageSize, total: 0),
    );
  }

  Future<ProductListResponse> fetchAllProducts({
    int pageSize = 200,
    int? categoryId,
  }) async {
    var page = 1;
    var total = 0;
    final allItems = <Product>[];
    while (true) {
      final response = await fetchProducts(
        page: page,
        pageSize: pageSize,
        categoryId: categoryId,
      );
      allItems.addAll(response.items);
      total = response.meta.total;
      final totalPages = (total / response.meta.pageSize)
          .ceil()
          .clamp(1, 1000000);
      if (response.items.isEmpty || page >= totalPages) {
        return ProductListResponse(
          items: allItems,
          meta: PaginationMeta(
            page: page,
            pageSize: response.meta.pageSize,
            total: total,
          ),
        );
      }
      page += 1;
    }
  }

  Future<Product> createProduct(ProductFormData data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/products/',
      data: data.toPayload(),
    );
    return Product.fromJson(response.data ?? const {});
  }

  Future<Product> updateProduct(int id, ProductFormData data) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/products/$id',
      data: data.toPayload(),
    );
    return Product.fromJson(response.data ?? const {});
  }

  Future<void> deleteProduct(int id) async {
    await _client.delete<void>('/products/$id');
  }
}
