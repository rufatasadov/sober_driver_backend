import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _parametricTables = [];
  List<Map<String, dynamic>> _settings = [];
  List<Map<String, dynamic>> _driversBalance = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get roles => _roles;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get parametricTables => _parametricTables;
  List<Map<String, dynamic>> get settings => _settings;
  List<Map<String, dynamic>> get driversBalance => _driversBalance;
  String? get error => _error;

  // Role Management
  Future<void> loadRoles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/roles'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _roles = List<Map<String, dynamic>>.from(data['roles']);
      } else {
        _error = 'Failed to load roles';
      }
    } catch (e) {
      _error = 'Error loading roles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRole(
      String name, String description, List<String> privileges) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.admin}/roles'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'privileges': privileges,
        }),
      );

      if (response.statusCode == 201) {
        await loadRoles();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to create role';
        return false;
      }
    } catch (e) {
      _error = 'Error creating role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRole(String id, String name, String description,
      List<String> privileges) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.admin}/roles/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'privileges': privileges,
        }),
      );

      if (response.statusCode == 200) {
        await loadRoles();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to update role';
        return false;
      }
    } catch (e) {
      _error = 'Error updating role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRole(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.admin}/roles/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadRoles();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to delete role';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // User Management
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/users'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _users = List<Map<String, dynamic>>.from(data['users']);
      } else {
        _error = 'Failed to load users';
      }
    } catch (e) {
      _error = 'Error loading users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(String name, String email, String phone,
      String roleId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.admin}/users'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'roleId': roleId,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        await loadUsers();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to create user';
        return false;
      }
    } catch (e) {
      _error = 'Error creating user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(
      String id, String name, String email, String phone, String roleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.admin}/users/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'roleId': roleId,
        }),
      );

      if (response.statusCode == 200) {
        await loadUsers();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to update user';
        return false;
      }
    } catch (e) {
      _error = 'Error updating user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.admin}/users/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadUsers();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to delete user';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Parametric Table Management
  Future<void> loadParametricTables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/parametric-tables'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _parametricTables = List<Map<String, dynamic>>.from(data['tables']);
      } else {
        _error = 'Failed to load parametric tables';
      }
    } catch (e) {
      _error = 'Error loading parametric tables: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createParametricTable(String name, String description,
      List<Map<String, dynamic>> columns) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.admin}/parametric-tables'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'columns': columns,
        }),
      );

      if (response.statusCode == 201) {
        await loadParametricTables();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to create parametric table';
        return false;
      }
    } catch (e) {
      _error = 'Error creating parametric table: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateParametricTable(String id, String name, String description,
      List<Map<String, dynamic>> columns) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.admin}/parametric-tables/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'columns': columns,
        }),
      );

      if (response.statusCode == 200) {
        await loadParametricTables();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to update parametric table';
        return false;
      }
    } catch (e) {
      _error = 'Error updating parametric table: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteParametricTable(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.admin}/parametric-tables/$id'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadParametricTables();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to delete parametric table';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting parametric table: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Settings Management
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/settings'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _settings = List<Map<String, dynamic>>.from(data['settings']);
      } else {
        _error = 'Failed to load settings';
      }
    } catch (e) {
      _error = 'Error loading settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/settings/$key'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['value'];
      }
      return null;
    } catch (e) {
      print('Error getting setting: $e');
      return null;
    }
  }

  Future<bool> updateSetting(String key, String value,
      {String? description}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.admin}/settings/$key'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'value': value,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode == 200) {
        await loadSettings();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to update setting';
        return false;
      }
    } catch (e) {
      _error = 'Error updating setting: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSetting(
      String key, String value, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.admin}/settings'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'key': key,
          'value': value,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        await loadSettings();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to create setting';
        return false;
      }
    } catch (e) {
      _error = 'Error creating setting: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSetting(String key) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoints.admin}/settings/$key'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await loadSettings();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to delete setting';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting setting: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Balance Management
  Future<void> loadDriversBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.admin}/drivers/balance'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _driversBalance = List<Map<String, dynamic>>.from(data['drivers']);
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to load drivers balance';
      }
    } catch (e) {
      _error = 'Error loading drivers balance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDriverBalance(
    String driverId,
    double amount,
    String operation,
    String reason,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('${ApiEndpoints.admin}/drivers/$driverId/balance'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'operation': operation,
          'reason': reason,
        }),
      );

      final responseBody = response.body;
      print('Balance update response status: ${response.statusCode}');
      print('Balance update response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadDriversBalance(); // Refresh the list
        return true;
      } else {
        try {
          final data = json.decode(responseBody);
          _error = data['error'] ??
              data['message'] ??
              'Failed to update driver balance';
        } catch (e) {
          _error =
              'Failed to update driver balance (Status: ${response.statusCode})';
        }
        return false;
      }
    } catch (e) {
      print('Balance update error: $e');
      _error = 'Error updating driver balance: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Token get error: $e');
      return null;
    }
  }
}
