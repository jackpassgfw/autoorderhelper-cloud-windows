import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../customers/models.dart';
import 'models.dart';

final autoOrdersRepositoryProvider = Provider<AutoOrdersRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AutoOrdersRepository(client);
});

class AutoOrdersRepository {
  AutoOrdersRepository(this._client);

  final Dio _client;

  Future<AutoOrderListResponse> fetchAutoOrders({
    int page = 1,
    int pageSize = 10,
    int? customerId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auto-orders/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (customerId != null) 'customer_id': customerId,
      },
    );
    return AutoOrderListResponse.fromJson(response.data ?? const {});
  }

  Future<List<DeductionOption>> fetchDeductionOptions() async {
    final response = await _client.get<List<dynamic>>(
      '/auto-orders/deduction-options',
    );
    final data = response.data ?? [];
    return data
        .map((item) => DeductionOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Customer>> fetchCustomersForSelect() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/customers/',
      queryParameters: {'page_size': 100},
    );
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AutoOrder> createAutoOrder(AutoOrderFormData data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auto-orders/',
      data: data.toCreatePayload(),
    );
    return AutoOrder.fromJson(response.data ?? const {});
  }

  Future<AutoOrder> updateAutoOrder(AutoOrderFormData data) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/auto-orders/${data.id}',
      data: data.toUpdatePayload(),
    );
    return AutoOrder.fromJson(response.data ?? const {});
  }

  Future<AutoOrder> changeStatus(int id, ScheduleStatus status) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '/auto-orders/$id/status/',
      data: {'status': scheduleStatusToJson(status)},
    );
    return AutoOrder.fromJson(response.data ?? const {});
  }

  Future<AutoOrder> fetchAutoOrder(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auto-orders/$id',
    );
    return AutoOrder.fromJson(response.data ?? const {});
  }

  Future<void> deleteAutoOrder(int id) async {
    await _client.delete<void>('/auto-orders/$id');
  }

  Future<NoteMedia> uploadNoteMedia(File file) async {
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

  Future<void> updateScheduleNote({
    required int id,
    required String note,
    required List<NoteMedia> noteMedia,
  }) async {
    await _client.put<Map<String, dynamic>>(
      '/auto-orders/$id',
      data: {
        'note': note,
        'media': noteMedia.map((media) => media.toJson()).toList(),
      },
    );
  }

  Future<List<AutoOrder>> fetchAutoOrdersForCustomer(int customerId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auto-orders/',
      queryParameters: {'customer_id': customerId, 'page_size': 100},
    );
    final listResponse = AutoOrderListResponse.fromJson(
      response.data ?? const {},
    );
    return listResponse.items;
  }
}
