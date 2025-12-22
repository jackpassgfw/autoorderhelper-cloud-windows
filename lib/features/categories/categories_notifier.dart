import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'categories_repository.dart';
import 'categories_state.dart';

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
      final repository = ref.watch(categoriesRepositoryProvider);
      return CategoriesNotifier(repository);
    });

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier(this._repository) : super(CategoriesState.initial());

  final CategoriesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.fetchAll();
      state = state.copyWith(items: items, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load categories',
      );
    }
  }

  Future<String?> save({
    int? id,
    required String name,
    int? parentId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (id == null) {
        await _repository.create(
          name: name,
          parentId: parentId,
          sortOrder: sortOrder,
          isActive: isActive,
        );
      } else {
        await _repository.update(
          id,
          name: name,
          parentId: parentId,
          sortOrder: sortOrder,
          isActive: isActive,
        );
      }
      await load();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to save category';
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
      return 'Failed to delete category';
    }
  }
}
