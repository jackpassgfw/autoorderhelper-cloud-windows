import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../customers/models.dart';
import 'auto_orders_repository.dart';
import 'auto_orders_state.dart';
import 'models.dart';

final autoOrdersNotifierProvider =
    StateNotifierProvider<AutoOrdersNotifier, AutoOrdersState>((ref) {
      final repository = ref.watch(autoOrdersRepositoryProvider);
      return AutoOrdersNotifier(repository);
    });

class AutoOrdersNotifier extends StateNotifier<AutoOrdersState> {
  AutoOrdersNotifier(this._repository) : super(AutoOrdersState.initial());

  final AutoOrdersRepository _repository;

  Future<void> loadAutoOrders({int? page}) async {
    final targetPage = page ?? state.meta.page;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.fetchAutoOrders(
        page: targetPage,
        pageSize: state.meta.pageSize,
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
        errorMessage: 'Failed to load auto orders',
      );
    }
  }

  Future<void> loadAuxData() async {
    try {
      final customers = await _repository.fetchCustomersForSelect();
      final options = await _repository.fetchDeductionOptions();
      state = state.copyWith(customers: customers, deductionOptions: options);
    } on DioException catch (error) {
      state = state.copyWith(errorMessage: normalizeErrorMessage(error));
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to load form data');
    }
  }

  void updateStatusFilter(ScheduleStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      meta: const PaginationMeta(page: 1, pageSize: 10, total: 0),
    );
    loadAutoOrders(page: 1);
  }

  Future<String?> saveAutoOrder(AutoOrderFormData data) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (data.id == null) {
        await _repository.createAutoOrder(data);
      } else {
        await _repository.updateAutoOrder(data);
      }
      await loadAutoOrders(page: 1);
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to save auto order';
    }
  }

  Future<String?> changeStatus(int id, ScheduleStatus status) async {
    try {
      await _repository.changeStatus(id, status);
      await loadAutoOrders();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to update status';
    }
  }
}
