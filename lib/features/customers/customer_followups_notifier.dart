import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'customers_repository.dart';
import 'customers_state.dart';

final customerFollowupsProvider =
    StateNotifierProvider.family<
      CustomerFollowupsNotifier,
      CustomerFollowupsState,
      int
    >((ref, customerId) {
      final repository = ref.watch(customersRepositoryProvider);
      return CustomerFollowupsNotifier(
        repository: repository,
        customerId: customerId,
      );
    });

class CustomerFollowupsNotifier extends StateNotifier<CustomerFollowupsState> {
  CustomerFollowupsNotifier({
    required CustomersRepository repository,
    required this.customerId,
  }) : _repository = repository,
       super(CustomerFollowupsState.initial());

  final CustomersRepository _repository;
  final int customerId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final followups = await _repository.fetchFollowups(customerId);
      state = state.copyWith(isLoading: false, followups: followups);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load follow-ups',
      );
    }
  }

  Future<String?> addFollowup(String content) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.createFollowup(
        customerId: customerId,
        content: content,
      );
      final followups = await _repository.fetchFollowups(customerId);
      state = state.copyWith(isSubmitting: false, followups: followups);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to add follow-up';
    }
  }

  Future<String?> deleteFollowup(int followupId) async {
    try {
      await _repository.deleteFollowup(followupId);
      final followups = await _repository.fetchFollowups(customerId);
      state = state.copyWith(followups: followups);
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to delete follow-up';
    }
  }

  Future<String?> updateFollowup({
    required int followupId,
    required String content,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.updateFollowup(
        followupId: followupId,
        content: content,
      );
      final followups = await _repository.fetchFollowups(customerId);
      state = state.copyWith(isSubmitting: false, followups: followups);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to update follow-up';
    }
  }
}
