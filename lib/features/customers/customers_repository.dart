import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
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
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/customers/',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (memberStatus != null)
          'member_status': memberStatusToJson(memberStatus),
        if (businessCenterId != null) 'business_center_id': businessCenterId,
      },
    );
    return CustomerListResponse.fromJson(response.data ?? const {});
  }

  Future<Customer> createCustomer(CustomerFormData data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/customers/',
      data: data.toPayload(),
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

  Future<List<BusinessCenter>> fetchBusinessCenters() async {
    final response = await _client.get<List<dynamic>>('/business-centers/');
    final data = response.data ?? [];
    return data
        .map((item) => BusinessCenter.fromJson(item as Map<String, dynamic>))
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
