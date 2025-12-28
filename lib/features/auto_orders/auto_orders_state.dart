import 'package:flutter/material.dart';

import '../customers/models.dart';
import 'models.dart';

class AutoOrdersState {
  const AutoOrdersState({
    required this.items,
    required this.meta,
    required this.isLoading,
    required this.isSubmitting,
    required this.errorMessage,
    required this.statusFilter,
    required this.cycleFilter,
    required this.dateRangeFilter,
    required this.customers,
    required this.deductionOptions,
  });

  final List<AutoOrder> items;
  final PaginationMeta meta;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final ScheduleStatus? statusFilter;
  final CycleFilter? cycleFilter;
  final DateTimeRange? dateRangeFilter;
  final List<Customer> customers;
  final List<DeductionOption> deductionOptions;

  AutoOrdersState copyWith({
    List<AutoOrder>? items,
    PaginationMeta? meta,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    ScheduleStatus? statusFilter,
    bool clearStatusFilter = false,
    CycleFilter? cycleFilter,
    bool clearCycleFilter = false,
    DateTimeRange? dateRangeFilter,
    bool clearDateRangeFilter = false,
    List<Customer>? customers,
    List<DeductionOption>? deductionOptions,
  }) {
    return AutoOrdersState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      cycleFilter: clearCycleFilter
          ? null
          : (cycleFilter ?? this.cycleFilter),
      dateRangeFilter: clearDateRangeFilter
          ? null
          : (dateRangeFilter ?? this.dateRangeFilter),
      customers: customers ?? this.customers,
      deductionOptions: deductionOptions ?? this.deductionOptions,
    );
  }

  factory AutoOrdersState.initial() {
    return AutoOrdersState(
      items: const [],
      meta: const PaginationMeta(page: 1, pageSize: 10, total: 0),
      isLoading: false,
      isSubmitting: false,
      errorMessage: null,
      statusFilter: null,
      cycleFilter: null,
      dateRangeFilter: null,
      customers: const [],
      deductionOptions: const [],
    );
  }
}
