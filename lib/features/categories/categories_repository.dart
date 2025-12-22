import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'models.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CategoriesRepository(client);
});

class CategoriesRepository {
  CategoriesRepository(this._client);

  final Dio _client;

  Future<List<Category>> fetchAll({int page = 1, int pageSize = 200}) async {
    final response = await _client.get<dynamic>(
      '/categories/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  Future<Category> create({
    required String name,
    int? parentId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/categories/',
      data: {
        'name': name,
        'parent_id': parentId,
        'sort_order': sortOrder,
        'is_active': isActive,
      },
    );
    return Category.fromJson(response.data ?? const {});
  }

  Future<Category> update(
    int id, {
    required String name,
    int? parentId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/categories/$id',
      data: {
        'name': name,
        'parent_id': parentId,
        'sort_order': sortOrder,
        'is_active': isActive,
      },
    );
    return Category.fromJson(response.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _client.delete<void>('/categories/$id');
  }
}
