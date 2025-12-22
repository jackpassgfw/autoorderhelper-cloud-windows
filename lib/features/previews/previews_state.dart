import 'models.dart';

class PreviewsState {
  const PreviewsState({
    required this.nextWeek,
    required this.customRange,
    required this.isLoadingNextWeek,
    required this.isLoadingRange,
    required this.errorNextWeek,
    required this.errorRange,
    required this.rangeFrom,
    required this.rangeTo,
  });

  final List<PreviewOccurrence> nextWeek;
  final List<PreviewOccurrence> customRange;
  final bool isLoadingNextWeek;
  final bool isLoadingRange;
  final String? errorNextWeek;
  final String? errorRange;
  final DateTime rangeFrom;
  final DateTime rangeTo;

  PreviewsState copyWith({
    List<PreviewOccurrence>? nextWeek,
    List<PreviewOccurrence>? customRange,
    bool? isLoadingNextWeek,
    bool? isLoadingRange,
    String? errorNextWeek,
    String? errorRange,
    DateTime? rangeFrom,
    DateTime? rangeTo,
  }) {
    return PreviewsState(
      nextWeek: nextWeek ?? this.nextWeek,
      customRange: customRange ?? this.customRange,
      isLoadingNextWeek: isLoadingNextWeek ?? this.isLoadingNextWeek,
      isLoadingRange: isLoadingRange ?? this.isLoadingRange,
      errorNextWeek: errorNextWeek,
      errorRange: errorRange,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
    );
  }

  factory PreviewsState.initial() {
    final now = DateTime.now();
    final from = now;
    final to = now.add(const Duration(days: 6));
    return PreviewsState(
      nextWeek: const [],
      customRange: const [],
      isLoadingNextWeek: false,
      isLoadingRange: false,
      errorNextWeek: null,
      errorRange: null,
      rangeFrom: from,
      rangeTo: to,
    );
  }
}
