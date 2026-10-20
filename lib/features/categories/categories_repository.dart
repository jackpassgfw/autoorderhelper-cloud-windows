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

  /// Fetches every page; the backend caps `page_size` at 100.
  Future<List<Category>> fetchAll({int pageSize = 100}) async {
    final items = <Category>[];
    var page = 1;
    while (true) {
      final response = await _client.get<dynamic>(
        '/categories/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => Category.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (data is! Map<String, dynamic>) break;

      final raw = data['items'] as List<dynamic>? ?? const [];
      items.addAll(
        raw.map((item) => Category.fromJson(item as Map<String, dynamic>)),
      );

      final meta = data['meta'];
      final total = meta is Map ? (meta['total'] as num?)?.toInt() : null;
      final done = total != null ? items.length >= total : raw.length < pageSize;
      if (raw.isEmpty || done) break;
      page += 1;
    }
    return items;
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
