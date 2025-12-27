import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'countries_repository.dart';
import 'countries_state.dart';

final countriesNotifierProvider =
    StateNotifierProvider<CountriesNotifier, CountriesState>((ref) {
      final repository = ref.watch(countriesRepositoryProvider);
      return CountriesNotifier(repository);
    });

class CountriesNotifier extends StateNotifier<CountriesState> {
  CountriesNotifier(this._repository) : super(CountriesState.initial());

  final CountriesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.fetchAll()
        ..sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(isLoading: false, items: items);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load countries',
      );
    }
  }

  Future<String?> save({int? id, required String name}) async {
    try {
      if (id == null) {
        await _repository.create(name);
      } else {
        await _repository.update(id, name);
      }
      await load();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to save country';
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
      return 'Failed to delete country';
    }
  }
}
