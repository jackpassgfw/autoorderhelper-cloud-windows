import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'business_centers_repository.dart';
import 'business_centers_state.dart';

final businessCentersNotifierProvider =
    StateNotifierProvider<BusinessCentersNotifier, BusinessCentersState>((ref) {
      final repository = ref.watch(businessCentersRepositoryProvider);
      return BusinessCentersNotifier(repository);
    });

class BusinessCentersNotifier extends StateNotifier<BusinessCentersState> {
  BusinessCentersNotifier(this._repository)
    : super(BusinessCentersState.initial());

  final BusinessCentersRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final centers = await _repository.fetchAll();
      state = state.copyWith(items: centers, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load business centers',
      );
    }
  }

  Future<String?> save({
    int? id,
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (id == null) {
        await _repository.create(name, description: description);
      } else {
        await _repository.update(id, name: name, description: description);
      }
      await load();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to save business center';
    }
  }

  Future<String?> delete(int id) async {
    try {
      await _repository.delete(id);
      await load();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to delete business center';
    }
  }
}
