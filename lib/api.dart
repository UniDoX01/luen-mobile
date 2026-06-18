/// API client + endpoints + DTOs.
///
/// One file on purpose — easier to drop into a fresh `flutter create` scaffold.
/// Talks to https://houseofluen.com/api/* using the existing Laravel + Sanctum
/// backend. Auth token is stored in flutter_secure_storage.
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kApiBase = 'https://houseofluen.com';

class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'luen_auth_token';

  static Future<String?> read() => _storage.read(key: _key);
  static Future<void> write(String token) => _storage.write(key: _key, value: token);
  static Future<void> clear() => _storage.delete(key: _key);
}

class LuenApi {
  LuenApi() {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBase,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await TokenStore.clear();
        }
        handler.next(e);
      },
    ));
  }

  late final Dio _dio;
  Dio get raw => _dio;

  // ── Public ────────────────────────────────────────────────────────────────
  Future<AppConfig> fetchAppConfig() async {
    final r = await _dio.get('/api/app/config');
    return AppConfig.fromJson(r.data['data'] ?? r.data);
  }

  Future<List<Product>> listProducts({int limit = 30, String? category}) async {
    final r = await _dio.get('/api/products', queryParameters: {
      'limit': limit,
      if (category != null) 'filter[category]': category,
    });
    final list = _extractList(r.data);
    return list.map((j) => Product.fromJson(j)).toList();
  }

  Future<Product> getProduct(String idOrSlug) async {
    final r = await _dio.get('/api/products/$idOrSlug');
    final body = r.data is Map && r.data['data'] != null ? r.data['data'] : r.data;
    return Product.fromJson(body);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<User> login(String email, String password) async {
    final r = await _dio.post('/api/auth/login', data: {'email': email, 'password': password});
    final data = r.data['data'] ?? r.data;
    final token = data['token'] ?? r.data['token'];
    if (token != null) await TokenStore.write(token);
    return User.fromJson(data['user'] ?? data);
  }

  Future<User> signup({required String name, required String email, required String password}) async {
    final r = await _dio.post('/api/auth/register', data: {
      'name': name,
      'full_name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
    final data = r.data['data'] ?? r.data;
    final token = data['token'] ?? r.data['token'];
    if (token != null) await TokenStore.write(token);
    return User.fromJson(data['user'] ?? data);
  }

  Future<User> me() async {
    final r = await _dio.get('/api/auth/me');
    final body = r.data is Map && r.data['data'] != null ? r.data['data'] : r.data;
    return User.fromJson(body);
  }

  Future<void> logout() async {
    try { await _dio.post('/api/auth/logout'); } catch (_) {}
    await TokenStore.clear();
  }

  // ── Cart / Orders ─────────────────────────────────────────────────────────
  Future<List<CartItem>> fetchCart() async {
    final r = await _dio.get('/api/cart-items');
    return _extractList(r.data).map((j) => CartItem.fromJson(j)).toList();
  }

  Future<CartItem> addToCart({required String productId, int quantity = 1, String? size, String? color}) async {
    final r = await _dio.post('/api/cart-items', data: {
      'product_id': productId,
      'quantity': quantity,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
    });
    final body = r.data is Map && r.data['data'] != null ? r.data['data'] : r.data;
    return CartItem.fromJson(body);
  }

  Future<void> removeCartItem(dynamic id) => _dio.delete('/api/cart-items/$id');

  Future<List<Order>> fetchOrders() async {
    final r = await _dio.get('/api/orders', queryParameters: {'limit': 50, 'sort': '-created_at'});
    return _extractList(r.data).map((j) => Order.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createCheckoutSession({
    required String provider,
    required String orderId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final r = await _dio.post('/api/checkout/session', data: {
      'provider': provider,
      'order_id': orderId,
      if (successUrl != null) 'success_url': successUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // ── AI Concierge ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> conciergeConfig() async {
    final r = await _dio.get('/api/chat/ai/config');
    return Map<String, dynamic>.from(r.data);
  }

  Future<String?> conciergeMessage(String message, List<Map<String, String>> history) async {
    final r = await _dio.post('/api/chat/ai/message', data: {'message': message, 'history': history});
    return r.data['reply'] as String?;
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map && d['data'] is List) return d['data'];
      if (body['items'] is List) return body['items'];
    }
    return const [];
  }
}

// ─── DTOs ────────────────────────────────────────────────────────────────────

class AppConfig {
  final String minIos, minAndroid, recIos, recAndroid;
  final String appStoreUrl, playStoreUrl;
  final bool maintenanceMode;
  final String maintenanceTitle, maintenanceMessage;
  final String updateBannerTitle, updateBannerMessage;
  final Map<String, dynamic> featureFlags;
  final String? brandPrimaryHex, brandBgHex, brandLogoUrl, conciergeGreeting;

  AppConfig({
    required this.minIos, required this.minAndroid,
    required this.recIos, required this.recAndroid,
    required this.appStoreUrl, required this.playStoreUrl,
    required this.maintenanceMode, required this.maintenanceTitle, required this.maintenanceMessage,
    required this.updateBannerTitle, required this.updateBannerMessage,
    required this.featureFlags,
    this.brandPrimaryHex, this.brandBgHex, this.brandLogoUrl, this.conciergeGreeting,
  });

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
    minIos:     j['min_version_ios']     ?? '1.0.0',
    minAndroid: j['min_version_android'] ?? '1.0.0',
    recIos:     j['recommended_version_ios']     ?? '1.0.0',
    recAndroid: j['recommended_version_android'] ?? '1.0.0',
    appStoreUrl: j['app_store_url'] ?? '',
    playStoreUrl: j['play_store_url'] ?? '',
    maintenanceMode: j['maintenance_mode'] == true,
    maintenanceTitle: j['maintenance_title'] ?? '',
    maintenanceMessage: j['maintenance_message'] ?? '',
    updateBannerTitle: j['update_banner_title'] ?? '',
    updateBannerMessage: j['update_banner_message'] ?? '',
    featureFlags: Map<String, dynamic>.from(j['feature_flags'] ?? {}),
    brandPrimaryHex: j['brand']?['primary_hex'],
    brandBgHex: j['brand']?['background_hex'],
    brandLogoUrl: j['brand']?['logo_url'],
    conciergeGreeting: j['concierge_greeting'],
  );

  bool isEnabled(String flag) => featureFlags[flag] == true;
}

class User {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isVip;
  final double totalSpent;
  User({required this.id, required this.email, this.name, required this.role, required this.isVip, required this.totalSpent});
  factory User.fromJson(Map<String, dynamic> j) => User(
    id: '${j['id']}',
    email: j['email'] ?? '',
    name: j['full_name'] ?? j['name'],
    role: j['role'] ?? 'user',
    isVip: j['is_vip'] == true || j['is_vip'] == 1,
    totalSpent: double.tryParse('${j['total_spent'] ?? 0}') ?? 0.0,
  );
}

class Product {
  final String id, slug, name;
  final String? category, shortDescription, mainImage;
  final double price;
  final double? salePrice;
  final List<String> images, sizes, colors;
  final int stock;
  Product({
    required this.id, required this.slug, required this.name,
    this.category, this.shortDescription, this.mainImage,
    required this.price, this.salePrice,
    required this.images, required this.sizes, required this.colors,
    required this.stock,
  });
  factory Product.fromJson(Map<String, dynamic> j) {
    List<String> _toList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return [v];
      return const [];
    }
    return Product(
      id: '${j['id']}',
      slug: j['slug'] ?? '',
      name: j['name'] ?? '',
      category: j['category'],
      shortDescription: j['short_description'],
      mainImage: j['main_image'] ?? (_toList(j['images']).isNotEmpty ? _toList(j['images']).first : null),
      price: double.tryParse('${j['price'] ?? 0}') ?? 0.0,
      salePrice: j['sale_price'] == null ? null : double.tryParse('${j['sale_price']}'),
      images: _toList(j['images']),
      sizes: _toList(j['sizes']),
      colors: _toList(j['colors']),
      stock: int.tryParse('${j['stock'] ?? j['stock_quantity'] ?? 0}') ?? 0,
    );
  }
  double get displayPrice => salePrice ?? price;
}

class CartItem {
  final dynamic id;
  final String productId;
  final int quantity;
  final String? size, color;
  final Product? product;
  CartItem({required this.id, required this.productId, required this.quantity, this.size, this.color, this.product});
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    id: j['id'],
    productId: '${j['product_id']}',
    quantity: j['quantity'] ?? 1,
    size: j['size'], color: j['color'],
    product: j['product'] is Map ? Product.fromJson(Map<String, dynamic>.from(j['product'])) : null,
  );
}

class Order {
  final dynamic id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double total;
  final String createdAt;
  Order({required this.id, required this.orderNumber, required this.status, required this.paymentStatus, required this.total, required this.createdAt});
  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    orderNumber: j['order_number'] ?? '',
    status: j['status'] ?? 'pending',
    paymentStatus: j['payment_status'] ?? 'unpaid',
    total: double.tryParse('${j['total'] ?? j['total_amount'] ?? 0}') ?? 0.0,
    createdAt: j['created_at'] ?? '',
  );
  bool get isPickup => status == 'pickup_pending' || status == 'ready_for_pickup' || status == 'picked_up';
}
