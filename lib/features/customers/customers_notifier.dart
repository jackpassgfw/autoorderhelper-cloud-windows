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
    return '${state.memberStatusFilter}|${state.businessCenterFilter}';
  }

  Future<List<Customer>> _loadAllCustomers() async {
    final key = _buildCacheKey();
    if (_hasCache && _cacheKey == key) return _cachedCustomers;
    final items = await _repository.fetchAllCustomers(
      memberStatus: state.memberStatusFilter,
      businessCenterId: state.businessCenterFilter,
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

  Future<void> loadCustomers({int? page}) async {
    final targetPage = page ?? state.meta.page;
    final requestId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final searchValue = state.search.trim();
      if (_useClientPaging || searchValue.isNotEmpty) {
        await _loadCustomersClient(targetPage: targetPage, requestId: requestId);
        return;
      }

      final result = await _repository.fetchCustomers(
        page: targetPage,
        pageSize: state.meta.pageSize,
        search: null,
        memberStatus: state.memberStatusFilter,
        businessCenterId: state.businessCenterFilter,
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
    final filteredItems = searchValue.isEmpty
        ? allItems
        : allItems.where((item) {
            final name = item.name.toLowerCase();
            final phone = item.phone.toLowerCase();
            return name.contains(searchValue) || phone.contains(searchValue);
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

  void updateMemberStatus(MemberStatus? status) {
    if (status == state.memberStatusFilter) return;
    state = state.copyWith(memberStatusFilter: status);
    _invalidateCache();
    loadCustomers(page: 1);
  }

  void updateBusinessCenter(int? id) {
    if (id == state.businessCenterFilter) return;
    state = state.copyWith(businessCenterFilter: id);
    _invalidateCache();
    loadCustomers(page: 1);
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
