import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auto_orders/auto_orders_repository.dart';
import '../auto_orders/models.dart';
import 'customers_state.dart';

final customerAutoOrdersProvider =
    StateNotifierProvider.family<
      CustomerAutoOrdersNotifier,
      CustomerAutoOrdersState,
      int
    >((ref, customerId) {
      final repository = ref.watch(autoOrdersRepositoryProvider);
      return CustomerAutoOrdersNotifier(
        repository: repository,
        customerId: customerId,
      );
    });

class CustomerAutoOrdersNotifier
    extends StateNotifier<CustomerAutoOrdersState> {
  CustomerAutoOrdersNotifier({
    required AutoOrdersRepository repository,
    required this.customerId,
  }) : _repository = repository,
       super(CustomerAutoOrdersState.initial());

  final AutoOrdersRepository _repository;
  final int customerId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final schedules = await _repository.fetchAutoOrdersForCustomer(
        customerId,
      );
      schedules.sort((a, b) => b.deductionDate.compareTo(a.deductionDate));
      state = state.copyWith(isLoading: false, schedules: schedules);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load auto-order schedules',
      );
    }
  }

  Future<String?> save(AutoOrderFormData data) async {
    try {
      if (data.id == null) {
        await _repository.createAutoOrder(data);
      } else {
        await _repository.updateAutoOrder(data);
      }
      await load();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to save auto-order';
    }
  }
}
