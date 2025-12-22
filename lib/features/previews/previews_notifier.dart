import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'preview_repository.dart';
import 'previews_state.dart';

final previewsNotifierProvider =
    StateNotifierProvider<PreviewsNotifier, PreviewsState>((ref) {
      final repository = ref.watch(previewRepositoryProvider);
      return PreviewsNotifier(repository);
    });

class PreviewsNotifier extends StateNotifier<PreviewsState> {
  PreviewsNotifier(this._repository) : super(PreviewsState.initial());

  final PreviewRepository _repository;

  Future<void> loadNextWeek() async {
    state = state.copyWith(isLoadingNextWeek: true, errorNextWeek: null);
    try {
      final occurrences = await _repository.fetchNextWeek();
      state = state.copyWith(isLoadingNextWeek: false, nextWeek: occurrences);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingNextWeek: false,
        errorNextWeek: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingNextWeek: false,
        errorNextWeek: 'Failed to load next week preview',
      );
    }
  }

  Future<void> loadRange() async {
    if (state.rangeFrom.isAfter(state.rangeTo)) {
      state = state.copyWith(
        errorRange: 'From date must be on or before To date.',
      );
      return;
    }
    state = state.copyWith(isLoadingRange: true, errorRange: null);
    try {
      final occurrences = await _repository.fetchRange(
        from: state.rangeFrom,
        to: state.rangeTo,
      );
      state = state.copyWith(isLoadingRange: false, customRange: occurrences);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingRange: false,
        errorRange: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingRange: false,
        errorRange: 'Failed to load preview',
      );
    }
  }

  void updateRangeFrom(DateTime value) {
    state = state.copyWith(rangeFrom: value);
  }

  void updateRangeTo(DateTime value) {
    state = state.copyWith(rangeTo: value);
  }
}
