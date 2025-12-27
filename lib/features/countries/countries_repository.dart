import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../customers/models.dart';

final countriesRepositoryProvider = Provider<CountriesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CountriesRepository(client);
});

class CountriesRepository {
  CountriesRepository(this._client);

  final Dio _client;

  Future<List<Country>> fetchAll() async {
    final response = await _client.get<List<dynamic>>('/countries/');
    final data = response.data ?? [];
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Country> create(String name) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/countries/',
      data: {'name': name},
    );
    return Country.fromJson(response.data ?? const {});
  }

  Future<Country> update(int id, String name) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/countries/$id',
      data: {'name': name},
    );
    return Country.fromJson(response.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _client.delete<void>('/countries/$id');
  }
}
