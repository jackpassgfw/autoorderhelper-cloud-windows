import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auto_orders/models.dart' show NoteMedia;
import 'models.dart';

final deliveriesRepositoryProvider = Provider<DeliveriesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DeliveriesRepository(client);
});

class DeliveriesRepository {
  DeliveriesRepository(this._client);

  final Dio _client;

  Future<DeliveryListResponse> fetchDeliveries({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/deliveries/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return DeliveryListResponse.fromJson(response.data ?? const {});
  }

  Future<Delivery> updateDelivery(DeliveryUpdateData data) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/deliveries/${data.id}',
      data: data.toPayload(),
    );
    return Delivery.fromJson(response.data ?? const {});
  }

  Future<void> deleteDelivery(int id) async {
    await _client.delete<void>('/deliveries/$id');
  }

  Future<Delivery> createDelivery(DeliveryCreateData data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/deliveries/',
      data: data.toPayload(),
    );
    return Delivery.fromJson(response.data ?? const {});
  }

  Future<NoteMedia> uploadAttachment(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final payload = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _client.post<Map<String, dynamic>>(
      '/uploads/media',
      data: payload,
    );
    return NoteMedia.fromJson(response.data ?? const {});
  }
}
