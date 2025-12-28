import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'deliveries_repository.dart';
import 'deliveries_state.dart';
import 'models.dart';

final deliveriesNotifierProvider =
    StateNotifierProvider<DeliveriesNotifier, DeliveriesState>((ref) {
      final repository = ref.watch(deliveriesRepositoryProvider);
      return DeliveriesNotifier(repository);
    });

class DeliveriesNotifier extends StateNotifier<DeliveriesState> {
  DeliveriesNotifier(this._repository) : super(DeliveriesState.initial());

  final DeliveriesRepository _repository;

  Future<void> load({int? page}) async {
    final targetPage = page ?? state.meta.page;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.fetchDeliveries(
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
        errorMessage: 'Failed to load deliveries',
      );
    }
  }

  Future<String?> update(DeliveryUpdateData data) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.updateDelivery(data);
      await load();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to update delivery';
    }
  }

  Future<String?> delete(int id) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.deleteDelivery(id);
      await load();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to delete delivery';
    }
  }

  Future<String?> create(DeliveryCreateData data) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.createDelivery(data);
      await load(page: 1);
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to create delivery';
    }
  }
}
