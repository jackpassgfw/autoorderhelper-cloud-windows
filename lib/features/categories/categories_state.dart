import 'models.dart';

class CategoriesState {
  const CategoriesState({
    required this.items,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<Category> items;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  CategoriesState copyWith({
    List<Category>? items,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CategoriesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  factory CategoriesState.initial() {
    return const CategoriesState(
      items: [],
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}
