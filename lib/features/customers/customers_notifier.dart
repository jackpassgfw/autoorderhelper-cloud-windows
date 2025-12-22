import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'customers_repository.dart';
import 'customers_state.dart';
import 'models.dart';

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      final repository = ref.watch(customersRepositoryProvider);
      return CustomersNotifier(repository);
    });

class CustomersNotifier extends StateNotifier<CustomersState> {
  CustomersNotifier(this._repository) : super(CustomersState.initial());

  final CustomersRepository _repository;

  Future<void> loadBusinessCenters() async {
    state = state.copyWith(isLoadingCenters: true, errorMessage: null);
    try {
      final centers = await _repository.fetchBusinessCenters();
      state = state.copyWith(businessCenters: centers, isLoadingCenters: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingCenters: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingCenters: false,
        errorMessage: 'Failed to load business centers',
      );
    }
  }

  Future<void> loadCustomers({int? page}) async {
    final targetPage = page ?? state.meta.page;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.fetchCustomers(
        page: targetPage,
        pageSize: state.meta.pageSize,
        search: state.search.isEmpty ? null : state.search,
        memberStatus: state.memberStatusFilter,
        businessCenterId: state.businessCenterFilter,
      );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        meta: result.meta,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load customers',
      );
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(search: value);
    loadCustomers(page: 1);
  }

  void updateMemberStatus(MemberStatus? status) {
    state = state.copyWith(memberStatusFilter: status);
    loadCustomers(page: 1);
  }

  void updateBusinessCenter(int? id) {
    state = state.copyWith(businessCenterFilter: id);
    loadCustomers(page: 1);
  }

  Future<String?> saveCustomer(CustomerFormData data) async {
    try {
      if (data.id == null) {
        await _repository.createCustomer(data);
      } else {
        await _repository.updateCustomer(data.id!, data);
      }
      await loadCustomers(page: 1);
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to save customer';
    }
  }

  Future<String?> deleteCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to delete customer';
    }
  }
}
