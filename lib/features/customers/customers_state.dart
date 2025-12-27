import '../auto_orders/models.dart' show AutoOrder;
import 'models.dart';

const int kNotChinaFilterValue = -1;

class CustomersState {
  const CustomersState({
    required this.items,
    required this.meta,
    required this.isLoading,
    required this.errorMessage,
    required this.search,
    required this.sponsorFilter,
    required this.businessCenterFilter,
    required this.countryFilter,
    required this.businessCenters,
    required this.countries,
    required this.isLoadingCenters,
    required this.isLoadingCountries,
  });

  final List<Customer> items;
  final PaginationMeta meta;
  final bool isLoading;
  final String? errorMessage;

  final String search;
  final String sponsorFilter;
  final int? businessCenterFilter;
  final int? countryFilter;

  final List<BusinessCenter> businessCenters;
  final List<Country> countries;
  final bool isLoadingCenters;
  final bool isLoadingCountries;

  static const _unset = Object();

  CustomersState copyWith({
    List<Customer>? items,
    PaginationMeta? meta,
    bool? isLoading,
    String? errorMessage,
    String? search,
    String? sponsorFilter,
    Object? businessCenterFilter = _unset,
    Object? countryFilter = _unset,
    List<BusinessCenter>? businessCenters,
    List<Country>? countries,
    bool? isLoadingCenters,
    bool? isLoadingCountries,
  }) {
    final resolvedBusinessCenter = businessCenterFilter == _unset
        ? this.businessCenterFilter
        : businessCenterFilter as int?;
    final resolvedCountry = countryFilter == _unset
        ? this.countryFilter
        : countryFilter as int?;
    return CustomersState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      search: search ?? this.search,
      sponsorFilter: sponsorFilter ?? this.sponsorFilter,
      businessCenterFilter: resolvedBusinessCenter,
      countryFilter: resolvedCountry,
      businessCenters: businessCenters ?? this.businessCenters,
      countries: countries ?? this.countries,
      isLoadingCenters: isLoadingCenters ?? this.isLoadingCenters,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
    );
  }

  factory CustomersState.initial() {
    return CustomersState(
      items: const [],
      meta: const PaginationMeta(page: 1, pageSize: 10, total: 0),
      isLoading: false,
      errorMessage: null,
      search: '',
      sponsorFilter: '',
      businessCenterFilter: null,
      countryFilter: null,
      businessCenters: const [],
      countries: const [],
      isLoadingCenters: false,
      isLoadingCountries: false,
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
