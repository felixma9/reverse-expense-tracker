import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/savings.dart';
import '../models/user.dart';
import '../config.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  // Token helpers
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Auth
  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String username, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
      })
    );
    return response.statusCode == 201;
  }

  Future<void> logout() async {
    await deleteToken();
  }

  // User
  Future<User?> getMe() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/users/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<User?> updateMe(String name, String username) async {
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/users/me'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        'username': username,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteMe() async {
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/users/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 204) {
      await deleteToken();
      return true;
    }
    return false;
  }

  // Savings
  Future<List<Saving>> getSavings() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/savings'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Saving.fromJson(json)).toList();
    }
    return [];
  }

  Future<Saving?> addSaving(double amount, String description, Currency currency) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/savings'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'amount': amount,
        'description': description,
        'currency': currency.toStr().toUpperCase(),
      }),
    );

    if (response.statusCode == 200) {
      return Saving.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteSaving(int id) async {
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/savings/$id'),
      headers: await _authHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<double?> getSavingTotal() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/savings/total'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['total'].toDouble();
    }
    return null;
  }

  Future<double?> getSavingThisMonth() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/savings/this-month'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['total'].toDouble();
    }
    return null;
  }

  Future<Saving?> updateSaving(int id, {double? amount, String? description}) async {
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/savings/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'amount': ?amount,
        'description': ?description,
      }),
    );
    if (response.statusCode == 200) {
      return Saving.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}