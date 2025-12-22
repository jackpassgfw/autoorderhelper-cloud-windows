import '../customers/models.dart';

class BusinessCentersState {
  const BusinessCentersState({
    required this.items,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<BusinessCenter> items;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  BusinessCentersState copyWith({
    List<BusinessCenter>? items,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return BusinessCentersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  factory BusinessCentersState.initial() {
    return const BusinessCentersState(
      items: [],
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}
