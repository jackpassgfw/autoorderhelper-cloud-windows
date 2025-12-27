import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'customers_repository.dart';
import 'customers_state.dart';
import 'models.dart';

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      final repository = ref.watch(customersRepositoryProvider);
      return CustomersNotifier(repository);
    });

class CustomersNotifier extends StateNotifier<CustomersState> {
  CustomersNotifier(this._repository) : super(CustomersState.initial());

  final CustomersRepository _repository;
  int _latestRequestId = 0;
  bool _hasCache = false;
  String _cacheKey = '';
  List<Customer> _cachedCustomers = [];
  bool _useClientPaging = false;
  final Map<int, Set<int>> _pageIdCache = {};

  void _invalidateCache() {
    _hasCache = false;
    _cacheKey = '';
    _cachedCustomers = [];
    _useClientPaging = false;
    _pageIdCache.clear();
  }

  String _buildCacheKey() {
    return 'all';
  }

  Future<List<Customer>> _loadAllCustomers() async {
    final key = _buildCacheKey();
    if (_hasCache && _cacheKey == key) return _cachedCustomers;
    final items = await _repository.fetchAllCustomers(
      ordering: 'id',
    );
    _cachedCustomers = items;
    _cacheKey = key;
    _hasCache = true;
    return items;
  }

  Future<void> loadBusinessCenters() async {
    state = state.copyWith(isLoadingCenters: true, errorMessage: null);
    try {
      final centers = await _repository.fetchBusinessCenters();
      state = state.copyWith(businessCenters: centers, isLoadingCenters: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingCenters: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingCenters: false,
        errorMessage: 'Failed to load business centers',
      );
    }
  }

  Future<void> loadCountries() async {
    state = state.copyWith(isLoadingCountries: true, errorMessage: null);
    try {
      final countries = await _repository.fetchCountries()
        ..sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(countries: countries, isLoadingCountries: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingCountries: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingCountries: false,
        errorMessage: 'Failed to load countries',
      );
    }
  }

  Future<void> loadCustomers({int? page}) async {
    final targetPage = page ?? state.meta.page;
    final requestId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final searchValue = state.search.trim();
      final sponsorValue = state.sponsorFilter.trim();
      final requiresClientPaging = _useClientPaging ||
          searchValue.isNotEmpty ||
          sponsorValue.isNotEmpty ||
          state.businessCenterFilter != null ||
          state.countryFilter != null;
      if (requiresClientPaging) {
        await _loadCustomersClient(targetPage: targetPage, requestId: requestId);
        return;
      }

      final result = await _repository.fetchCustomers(
        page: targetPage,
        pageSize: state.meta.pageSize,
        search: null,
        ordering: 'id',
      );

      if (requestId != _latestRequestId) return;

      final pageIds = result.items.map((item) => item.id).toList();
      final pageIdSet = pageIds.toSet();
      var overlapDetected = pageIdSet.length != pageIds.length;
      if (!overlapDetected) {
        for (final entry in _pageIdCache.entries) {
          if (entry.key == targetPage) continue;
          if (pageIdSet.any(entry.value.contains)) {
            overlapDetected = true;
            break;
          }
        }
      }

      if (overlapDetected) {
        _useClientPaging = true;
        _pageIdCache.clear();
        await _loadCustomersClient(
          targetPage: targetPage,
          requestId: requestId,
        );
        return;
      }

      _pageIdCache[targetPage] = pageIdSet;
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        meta: PaginationMeta(
          page: targetPage,
          pageSize: result.meta.pageSize,
          total: result.meta.total,
        ),
      );
    } on DioException catch (error) {
      if (requestId != _latestRequestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: normalizeErrorMessage(error),
      );
    } catch (_) {
      if (requestId != _latestRequestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load customers',
      );
    }
  }

  Future<void> _loadCustomersClient({
    required int targetPage,
    required int requestId,
  }) async {
    final allItems = await _loadAllCustomers();
    final searchValue = state.search.trim().toLowerCase();
    final sponsorValue = state.sponsorFilter.trim().toLowerCase();
    final businessCenterId = state.businessCenterFilter;
    final countryId = state.countryFilter;
    final chinaCountryId = _findChinaCountryId();
    final filteredItems = allItems.where((item) {
      if (businessCenterId != null && item.businessCenterId != businessCenterId) {
        return false;
      }
      if (countryId != null) {
        if (countryId == kNotChinaFilterValue) {
          if (chinaCountryId != null && item.countryId == chinaCountryId) {
            return false;
          }
        } else if (item.countryId != countryId) {
          return false;
        }
      }
      if (searchValue.isNotEmpty) {
        final name = item.name.toLowerCase();
        final phone = item.phone.toLowerCase();
        if (!name.contains(searchValue) && !phone.contains(searchValue)) {
          return false;
        }
      }
      if (sponsorValue.isNotEmpty) {
        final sponsor = (item.sponsor ?? '').toLowerCase();
        if (!sponsor.contains(sponsorValue)) return false;
      }
      return true;
    }).toList();
    final total = filteredItems.length;
    final pageSize = state.meta.pageSize;
    final totalPages = (total / pageSize).ceil().clamp(1, 1000000);
    final effectivePage = targetPage.clamp(1, totalPages);
    final start = (effectivePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);
    final pageItems = start >= total
        ? const <Customer>[]
        : filteredItems.sublist(start, end);
    if (requestId != _latestRequestId) return;
    state = state.copyWith(
      isLoading: false,
      items: pageItems,
      meta: PaginationMeta(
        page: effectivePage,
        pageSize: pageSize,
        total: total,
      ),
    );
  }

  void updateSearch(String value) {
    final normalized = value.trim();
    if (normalized == state.search) return;
    state = state.copyWith(search: normalized);
    loadCustomers(page: 1);
  }

  void updateSponsorFilter(String value) {
    final normalized = value.trim();
    if (normalized == state.sponsorFilter) return;
    state = state.copyWith(sponsorFilter: normalized);
    _invalidateCache();
    loadCustomers(page: 1);
  }

  void updateBusinessCenter(int? id) {
    if (id == state.businessCenterFilter) return;
    state = state.copyWith(businessCenterFilter: id);
    _invalidateCache();
    loadCustomers(page: 1);
  }

  void updateCountry(int? id) {
    if (id == state.countryFilter) return;
    state = state.copyWith(countryFilter: id);
    _invalidateCache();
    loadCustomers(page: 1);
  }

  int? _findChinaCountryId() {
    for (final country in state.countries) {
      if (country.name.trim().toLowerCase() == 'china') {
        return country.id;
      }
    }
    return null;
  }

  Future<String?> saveCustomer(CustomerFormData data) async {
    try {
      if (data.id == null) {
        await _repository.createCustomer(data);
      } else {
        await _repository.updateCustomer(data.id!, data);
      }
      _invalidateCache();
      await loadCustomers(page: 1);
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to save customer';
    }
  }

  Future<String?> deleteCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);
      _invalidateCache();
      await loadCustomers();
      return null;
    } on DioException catch (error) {
      return normalizeErrorMessage(error);
    } catch (_) {
      return 'Failed to delete customer';
    }
  }
}
