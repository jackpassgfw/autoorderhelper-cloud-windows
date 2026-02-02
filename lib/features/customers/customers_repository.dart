import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auto_orders/models.dart' show NoteMedia;
import 'customer_sort.dart';
import 'models.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomersRepository(client);
});

class CustomersRepository {
  CustomersRepository(this._client);

  final Dio _client;

  Future<CustomerListResponse> fetchCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
    MemberStatus? memberStatus,
    int? businessCenterId,
    String? ordering,
  }) async {
    final queryParameters = {
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (memberStatus != null)
        'member_status': memberStatusToJson(memberStatus),
      if (businessCenterId != null) 'business_center_id': businessCenterId,
      if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
    };
    final response = await _client.get<Map<String, dynamic>>(
      '/customers/',
      queryParameters: queryParameters,
    );
    return CustomerListResponse.fromJson(response.data ?? const {});
  }

  Future<List<Customer>> fetchAllCustomers({
    int pageSize = 200,
    MemberStatus? memberStatus,
    int? businessCenterId,
    String? ordering,
  }) async {
    var page = 1;
    final byId = <int, Customer>{};
    while (true) {
      final response = await fetchCustomers(
        page: page,
        pageSize: pageSize,
        memberStatus: memberStatus,
        businessCenterId: businessCenterId,
        ordering: ordering,
      );
      for (final item in response.items) {
        byId[item.id] = item;
      }
      if (response.items.isEmpty || response.items.length < pageSize) break;
      page += 1;
    }
    final items = byId.values.toList();
    items.sort((a, b) => compareCustomerNamesAsc(a.name, b.name));
    return items;
  }

  Future<Customer> createCustomer(CustomerFormData data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/customers/',
      data: data.toPayload(),
    );
    return Customer.fromJson(response.data ?? const {});
  }

  Future<Customer> fetchCustomer(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/customers/$id',
    );
    return Customer.fromJson(response.data ?? const {});
  }

  Future<Customer> updateCustomer(int id, CustomerFormData data) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/customers/$id',
      data: data.toPayload(),
    );
    return Customer.fromJson(response.data ?? const {});
  }

  Future<void> deleteCustomer(int id) async {
    await _client.delete<void>('/customers/$id');
  }

  Future<NoteMedia> uploadMedia(File file) async {
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

  Future<List<BusinessCenter>> fetchBusinessCenters() async {
    final response = await _client.get<List<dynamic>>('/business-centers/');
    final data = response.data ?? [];
    return data
        .map((item) => BusinessCenter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Country>> fetchCountries() async {
    final response = await _client.get<List<dynamic>>('/countries/');
    final data = response.data ?? [];
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Followup>> fetchFollowups(int customerId) async {
    final response = await _client.get<List<dynamic>>(
      '/customers/$customerId/followups',
    );
    final data = response.data ?? [];
    return data
        .map((item) => Followup.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Followup> createFollowup({
    required int customerId,
    required String content,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/followups/',
      data: {'customer_id': customerId, 'content': content},
    );
    return Followup.fromJson(response.data ?? const {});
  }

  Future<void> deleteFollowup(int followupId) async {
    await _client.delete<void>('/followups/$followupId');
  }

  Future<Followup> updateFollowup({
    required int followupId,
    required String content,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/followups/$followupId',
      data: {'content': content},
    );
    return Followup.fromJson(response.data ?? const {});
  }
}
