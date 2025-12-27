import '../customers/models.dart';

class CountriesState {
  const CountriesState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<Country> items;
  final bool isLoading;
  final String? errorMessage;

  CountriesState copyWith({
    List<Country>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CountriesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  factory CountriesState.initial() {
    return const CountriesState(
      items: [],
      isLoading: false,
      errorMessage: null,
    );
  }
}
