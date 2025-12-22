import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'models.dart';

final previewRepositoryProvider = Provider<PreviewRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PreviewRepository(client);
});

class PreviewRepository {
  PreviewRepository(this._client);

  final Dio _client;

  Future<List<PreviewOccurrence>> fetchNextWeek() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auto-orders/preview/next-week',
    );
    return PreviewResponse.fromJson(response.data ?? const {}).occurrences;
  }

  Future<List<PreviewOccurrence>> fetchRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auto-orders/preview',
      queryParameters: {'from': formatYmd(from), 'to': formatYmd(to)},
    );
    return PreviewResponse.fromJson(response.data ?? const {}).occurrences;
  }
}
