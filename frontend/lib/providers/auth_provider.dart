import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _currentUser;

  AuthProvider(this._api);

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    final token = await _api.getToken();
    if (token == null) return false;

    final user = await _api.getMe();
    if (user == null) return false;

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> login({required String username, required String password}) async {
    final success = await _api.login(username, password);
    if (success) {
      final user = await _api.getMe();
      _currentUser = user;
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(String name, String username, String password) async {
    final success = await _api.register(name, username, password);
    if (success) return await login(username: username, password: password);
    return false;
  }

  Future<void> logout() async {
    await _api.logout();
    _currentUser = null;
    notifyListeners();
  }
}