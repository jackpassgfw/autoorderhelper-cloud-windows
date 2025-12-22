import '../categories/models.dart';
import '../customers/models.dart';
import 'models.dart';

class ProductsState {
  const ProductsState({
    required this.items,
    required this.categories,
    required this.meta,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<Product> items;
  final List<Category> categories;
  final PaginationMeta meta;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  ProductsState copyWith({
    List<Product>? items,
    List<Category>? categories,
    PaginationMeta? meta,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ProductsState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  factory ProductsState.initial() {
    return const ProductsState(
      items: [],
      categories: [],
      meta: PaginationMeta(page: 1, pageSize: 50, total: 0),
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}
