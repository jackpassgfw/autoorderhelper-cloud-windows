import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../categories/categories_repository.dart';
import '../categories/models.dart';
import 'models.dart';
import 'products_repository.dart';
import 'products_state.dart';

final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
      final productsRepository = ref.watch(productsRepositoryProvider);
      final categoriesRepository = ref.watch(categoriesRepositoryProvider);
      return ProductsNotifier(productsRepository, categoriesRepository);
    });

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier(this._productsRepository, this._categoriesRepository)
    : super(ProductsState.initial());

  final ProductsRepository _productsRepository;
  final CategoriesRepository _categoriesRepository;

  Future<void> load({int page = 1}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _productsRepository.fetchAllProducts(),
        _categoriesRepository.fetchAll(),
      ]);
      final productsResponse = results[0] as ProductListResponse;
      final categories = results[1] as List<Category>;
      final products = productsResponse.items;
      state = state.copyWith(
        items: products,
        meta: productsResponse.meta,
        categories: categories,
        isLoading: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load products',
      );
    }
  }

  Future<String?> save(ProductFormData data) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (data.id == null) {
        await _productsRepository.createProduct(data);
      } else {
        await _productsRepository.updateProduct(data.id!, data);
      }
      await load();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return normalizeErrorMessage(error);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return 'Failed to save product';
    }
  }

  Future<String?> delete(int id) async {
    try {
      await _productsRepository.deleteProduct(id);
      await load();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to delete product';
    }
  }
}
