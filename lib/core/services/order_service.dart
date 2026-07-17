import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:project_fuel/core/models/order.dart';

class OrderService {
  static List<Order>? _cache;

  static Future<List<Order>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/mock_data/orders.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .whereType<Map<String, dynamic>>()
        .map((j) => Order.fromJson(j))
        .toList();
    return _cache!;
  }

  Future<List<Order>> getOrders() => _loadAll();

  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final all = await _loadAll();
    return all.where((o) => o.status == status).toList();
  }

  Future<void> createOrder(Order order) async {
    final all = await _loadAll();
    all.add(order);
    _cache = all;
  }

  Future<void> updateOrder(Order order) async {
    final all = await _loadAll();
    final i = all.indexWhere((o) => o.orderId == order.orderId);
    if (i == -1) return;
    all[i] = order;
    _cache = all;
  }
}
