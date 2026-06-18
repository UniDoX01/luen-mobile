/// Riverpod providers — single file for the whole app's state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'dart:io' show Platform;

import 'api.dart';

final apiProvider = Provider<LuenApi>((_) => LuenApi());

/// App config (fetched once on launch, refreshed on resume).
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final api = ref.read(apiProvider);
  return api.fetchAppConfig();
});

final packageInfoProvider = FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

/// Composite — decides whether the app is gated by force-update or maintenance.
class AppGateState {
  final AppConfig config;
  final PackageInfo info;
  AppGateState(this.config, this.info);

  String get _currentVersion => info.version;
  String get _minRequired    => Platform.isIOS ? config.minIos : config.minAndroid;
  String get _recommended    => Platform.isIOS ? config.recIos : config.recAndroid;

  bool get isMaintenance => config.maintenanceMode;
  bool get isForceUpdate {
    try {
      return Version.parse(_currentVersion) < Version.parse(_minRequired);
    } catch (_) { return false; }
  }
  bool get isSoftUpdate {
    try {
      final cur = Version.parse(_currentVersion);
      return cur < Version.parse(_recommended) && cur >= Version.parse(_minRequired);
    } catch (_) { return false; }
  }
  String get storeUrl => Platform.isIOS ? config.appStoreUrl : config.playStoreUrl;
}

final appGateProvider = FutureProvider<AppGateState>((ref) async {
  final cfg = await ref.watch(appConfigProvider.future);
  final inf = await ref.watch(packageInfoProvider.future);
  return AppGateState(cfg, inf);
});

/// Current user — null = signed out. Loaded from /api/auth/me on launch.
class AuthState {
  final User? user;
  final bool loading;
  const AuthState({this.user, this.loading = false});
  bool get isSignedIn => user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api) : super(const AuthState(loading: true)) {
    refresh();
  }
  final LuenApi _api;

  Future<void> refresh() async {
    try {
      final token = await TokenStore.read();
      if (token == null) { state = const AuthState(); return; }
      final u = await _api.me();
      state = AuthState(user: u);
    } catch (_) {
      await TokenStore.clear();
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      final u = await _api.login(email, password);
      state = AuthState(user: u);
    } catch (e) {
      state = const AuthState();
      rethrow;
    }
  }

  Future<void> signup({required String name, required String email, required String password}) async {
    state = const AuthState(loading: true);
    try {
      final u = await _api.signup(name: name, email: email, password: password);
      state = AuthState(user: u);
    } catch (e) {
      state = const AuthState();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _api.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(apiProvider));
});

/// Products (featured / shop list)
final productsProvider = FutureProvider.family<List<Product>, String?>((ref, category) async {
  return ref.read(apiProvider).listProducts(limit: 30, category: category);
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, slug) async {
  return ref.read(apiProvider).getProduct(slug);
});

/// Cart
class CartController extends StateNotifier<AsyncValue<List<CartItem>>> {
  CartController(this._api) : super(const AsyncValue.loading()) { refresh(); }
  final LuenApi _api;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await _api.fetchCart();
      state = AsyncValue.data(items);
    } catch (e, s) { state = AsyncValue.error(e, s); }
  }

  Future<void> add(String productId, {int qty = 1, String? size, String? color}) async {
    await _api.addToCart(productId: productId, quantity: qty, size: size, color: color);
    await refresh();
  }

  Future<void> remove(dynamic id) async {
    await _api.removeCartItem(id);
    await refresh();
  }
}

final cartProvider = StateNotifierProvider<CartController, AsyncValue<List<CartItem>>>((ref) {
  return CartController(ref.read(apiProvider));
});

/// Orders
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.read(apiProvider).fetchOrders();
});
