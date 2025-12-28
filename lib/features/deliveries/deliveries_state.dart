import '../customers/models.dart';
import 'models.dart';

class DeliveriesState {
  const DeliveriesState({
    required this.items,
    required this.meta,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<Delivery> items;
  final PaginationMeta meta;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  DeliveriesState copyWith({
    List<Delivery>? items,
    PaginationMeta? meta,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return DeliveriesState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  factory DeliveriesState.initial() {
    return const DeliveriesState(
      items: [],
      meta: PaginationMeta(page: 1, pageSize: 20, total: 0),
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}
