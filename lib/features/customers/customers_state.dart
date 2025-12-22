import '../auto_orders/models.dart' show AutoOrder;
import 'models.dart';

class CustomersState {
  const CustomersState({
    required this.items,
    required this.meta,
    required this.isLoading,
    required this.errorMessage,
    required this.search,
    required this.memberStatusFilter,
    required this.businessCenterFilter,
    required this.businessCenters,
    required this.isLoadingCenters,
  });

  final List<Customer> items;
  final PaginationMeta meta;
  final bool isLoading;
  final String? errorMessage;

  final String search;
  final MemberStatus? memberStatusFilter;
  final int? businessCenterFilter;

  final List<BusinessCenter> businessCenters;
  final bool isLoadingCenters;

  CustomersState copyWith({
    List<Customer>? items,
    PaginationMeta? meta,
    bool? isLoading,
    String? errorMessage,
    String? search,
    MemberStatus? memberStatusFilter,
    int? businessCenterFilter,
    List<BusinessCenter>? businessCenters,
    bool? isLoadingCenters,
  }) {
    return CustomersState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      search: search ?? this.search,
      memberStatusFilter: memberStatusFilter ?? this.memberStatusFilter,
      businessCenterFilter: businessCenterFilter ?? this.businessCenterFilter,
      businessCenters: businessCenters ?? this.businessCenters,
      isLoadingCenters: isLoadingCenters ?? this.isLoadingCenters,
    );
  }

  factory CustomersState.initial() {
    return CustomersState(
      items: const [],
      meta: const PaginationMeta(page: 1, pageSize: 10, total: 0),
      isLoading: false,
      errorMessage: null,
      search: '',
      memberStatusFilter: null,
      businessCenterFilter: null,
      businessCenters: const [],
      isLoadingCenters: false,
    );
  }
}

class CustomerFollowupsState {
  const CustomerFollowupsState({
    required this.followups,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final List<Followup> followups;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  CustomerFollowupsState copyWith({
    List<Followup>? followups,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CustomerFollowupsState(
      followups: followups ?? this.followups,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  factory CustomerFollowupsState.initial() {
    return const CustomerFollowupsState(
      followups: [],
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}

class CustomerAutoOrdersState {
  const CustomerAutoOrdersState({
    required this.schedules,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<AutoOrder> schedules;
  final bool isLoading;
  final String? errorMessage;

  CustomerAutoOrdersState copyWith({
    List<AutoOrder>? schedules,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerAutoOrdersState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  factory CustomerAutoOrdersState.initial() {
    return const CustomerAutoOrdersState(
      schedules: [],
      isLoading: false,
      errorMessage: null,
    );
  }
}
