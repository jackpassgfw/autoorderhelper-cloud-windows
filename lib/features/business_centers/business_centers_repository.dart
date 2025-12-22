import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../customers/models.dart';

final businessCentersRepositoryProvider = Provider<BusinessCentersRepository>((
  ref,
) {
  final client = ref.watch(apiClientProvider);
  return BusinessCentersRepository(client);
});

class BusinessCentersRepository {
  BusinessCentersRepository(this._client);

  final Dio _client;

  Future<List<BusinessCenter>> fetchAll() async {
    final response = await _client.get<List<dynamic>>('/business-centers/');
    final data = response.data ?? [];
    return data
        .map((item) => BusinessCenter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BusinessCenter> create(String name, {String? description}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/business-centers/',
      data: {'name': name, 'description': description},
    );
    return BusinessCenter.fromJson(response.data ?? const {});
  }

  Future<BusinessCenter> update(
    int id, {
    required String name,
    String? description,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/business-centers/$id',
      data: {'name': name, 'description': description},
    );
    return BusinessCenter.fromJson(response.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _client.delete<void>('/business-centers/$id');
  }
}
