import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maava_mart_seller/core/network/dio_client.dart';
import 'package:maava_mart_seller/features/analytics/domain/analytics_model.dart';

/// Analytics computed from the seller's own delivered orders.
///
/// There is no analytics endpoint on the backend. Rather than show invented
/// figures, the numbers are derived here from the order list, and anything the
/// orders cannot answer is left out instead of guessed at.
class ApiAnalyticsRepository {
  const ApiAnalyticsRepository(this._dio);

  final Dio _dio;

  /// [days] is the window; the same length immediately before it is the
  /// comparison period.
  Future<AnalyticsSummary> getSummary({int days = 1}) async {
    final response = await _dio.get<dynamic>(
      '/quick/restaurant/orders',
      // Wide enough to cover both the window and the one before it. Delivered
      // only: a cancelled order is not revenue, and counting it would flatter
      // every figure on the screen.
      queryParameters: {'status': 'delivered', 'limit': 200},
    );

    final data = _asMap(response.data);
    final orders = _asList(data['orders'] ?? data['data']);
    if (orders.isEmpty) return const AnalyticsSummary.empty();

    final now = DateTime.now();
    final windowStart = now.subtract(Duration(days: days));
    final priorStart = now.subtract(Duration(days: days * 2));

    final current = <Map<String, dynamic>>[];
    final prior = <Map<String, dynamic>>[];
    // Earliest order per customer across everything fetched, which is what
    // makes "new" mean new to this store rather than new to the window.
    final firstSeen = <String, DateTime>{};

    for (final o in orders) {
      final at = _asDate(o['deliveredAt'] ?? o['createdAt']);
      if (at == null) continue;

      final customer = _customerKey(o);
      if (customer.isNotEmpty) {
        final seen = firstSeen[customer];
        if (seen == null || at.isBefore(seen)) firstSeen[customer] = at;
      }

      if (at.isAfter(windowStart)) {
        current.add(o);
      } else if (at.isAfter(priorStart)) {
        prior.add(o);
      }
    }

    final sales = current.fold<double>(0, (sum, o) => sum + _total(o));
    final priorSales = prior.fold<double>(0, (sum, o) => sum + _total(o));

    final items = current.fold<int>(
      0,
      (sum, o) =>
          sum +
          _asList(
            o['items'],
          ).fold<int>(0, (n, i) => n + (_asNum(i['quantity'])?.toInt() ?? 0)),
    );

    var newCustomers = 0;
    var returning = 0;
    final counted = <String>{};
    for (final o in current) {
      final customer = _customerKey(o);
      if (customer.isEmpty || !counted.add(customer)) continue;
      final first = firstSeen[customer];
      if (first != null && first.isAfter(windowStart)) {
        newCustomers++;
      } else {
        returning++;
      }
    }

    return AnalyticsSummary(
      totalSales: sales,
      totalOrders: current.length,
      averageOrderValue: current.isEmpty ? 0 : sales / current.length,
      itemsSold: items,
      newCustomers: newCustomers,
      returningCustomers: returning,
      salesTrendPercent: _trend(sales, priorSales),
      ordersTrendPercent: _trend(
        current.length.toDouble(),
        prior.length.toDouble(),
      ),
    );
  }

  /// Null when there is nothing to compare against. Growth from zero is not a
  /// percentage, and rendering it as one would print an infinity.
  static double? _trend(double now, double before) {
    if (before <= 0) return null;
    return ((now - before) / before) * 100;
  }

  static String _customerKey(Map<String, dynamic> order) {
    final user = order['userId'];
    if (user is Map) return (user['_id'] ?? '').toString();
    final id = (user ?? '').toString();
    return id.isNotEmpty ? id : (order['customerPhone'] ?? '').toString();
  }

  static double _total(Map<String, dynamic> order) =>
      _asNum(_asMap(order['pricing'])['total'])?.toDouble() ?? 0;

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<Map<String, dynamic>> _asList(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];

  static num? _asNum(dynamic v) =>
      v is num ? v : num.tryParse((v ?? '').toString());

  static DateTime? _asDate(dynamic v) =>
      DateTime.tryParse((v ?? '').toString())?.toLocal();
}

final analyticsRepositoryProvider = Provider<ApiAnalyticsRepository>(
  (ref) => ApiAnalyticsRepository(ref.watch(dioProvider)),
);

/// Today against yesterday, which is what the screen's copy claims.
final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>(
  (ref) => ref.watch(analyticsRepositoryProvider).getSummary(),
);

/// The same summary over an arbitrary window, for the cards whose copy says
/// "this week" rather than "today".
final analyticsSummaryForProvider =
    FutureProvider.family<AnalyticsSummary, int>(
      (ref, days) => ref.watch(analyticsRepositoryProvider).getSummary(
        days: days,
      ),
    );
