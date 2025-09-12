import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false; // Para controlar se já verificou o status

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasUser => _user != null;
  bool get isInitialized => _isInitialized;
  String? get userToken => null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Starting login for user: $username');
      }
      
      final response = await ApiService.login(username, password);
      
      if (kDebugMode) {
        print('Login response received: $response');
        print('Success field: ${response['success']}');
      }
      
      if (response.containsKey('success') && response['success'] == true) {
        if (kDebugMode) {
          print('Success validation passed');
        }
        
        _isAuthenticated = true;
        
        // Processar dados do usuário
        if (response.containsKey('user') && response['user'] != null) {
          if (kDebugMode) {
            print('User data found: ${response['user']}');
          }
          
          try {
            _user = User.fromJson(response['user']);
            if (kDebugMode) {
              print('User object created successfully: ${_user?.id}');
            }
          } catch (userError) {
            if (kDebugMode) {
              print('Error creating User object: $userError');
            }
            _user = null;
          }
        }
        
        // Salvar dados de autenticação
        await _saveAuthData(response);
        
        notifyListeners();
        
        if (kDebugMode) {
          print('Login completed successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Login failed - success field is not true');
          print('Message: ${response['message'] ?? 'No message provided'}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Login error: $e');
        print('Stack trace: $stackTrace');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método privado para salvar dados de autenticação
  Future<void> _saveAuthData(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar token
      if (response.containsKey('token') && response['token'] != null) {
        await prefs.setString('auth_token', response['token']);
        if (kDebugMode) {
          print('Token saved: ${response['token'].toString().substring(0, 10)}...');
        }
      }
      
      // Salvar dados do usuário
      if (_user != null) {
        await prefs.setInt('user_id', _user!.id);
        await prefs.setString('user_data', _user!.toJson().toString());
      }
      
      // Salvar timestamp do login
      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Auth data saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving auth data: $e');
      }
    }
  }

  void setUser(dynamic userData) {
    if (userData != null) {
      try {
        if (userData is User) {
          _user = userData;
        } else if (userData is Map<String, dynamic>) {
          _user = User.fromJson(userData);
        } else {
          throw Exception('Invalid user data type: ${userData.runtimeType}');
        }
        
        _isAuthenticated = true;
        
        if (kDebugMode) {
          print('User set successfully: ${_user?.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error setting user: $e');
        }
        _user = null;
        _isAuthenticated = false;
      }
    } else {
      _user = null;
      _isAuthenticated = false;
    }
    
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('User cleared');
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      if (_user != null) {
        await prefs.setInt('user_id', _user!.id);
      }
      
      if (kDebugMode) {
        print('Token saved: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving token: $e');
      }
    }
  }

  void updateUserData(Map<String, dynamic> updates) {
    if (_user != null) {
      try {
        final currentData = _user!.toJson();
        currentData.addAll(updates);
        _user = User.fromJson(currentData);
        
        // Atualizar dados salvos
        _saveUpdatedUserData();
        
        notifyListeners();
        
        if (kDebugMode) {
          print('User data updated: $updates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating user data: $e');
        }
      }
    }
  }

  // Método para salvar dados atualizados do usuário
  Future<void> _saveUpdatedUserData() async {
    if (_user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', _user!.toJson().toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error saving updated user data: $e');
        }
      }
    }
  }

  // Logout manual - remove todos os dados
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      await prefs.remove('login_timestamp');
      
      _user = null;
      _isAuthenticated = false;
      
      if (kDebugMode) {
        print('Manual logout completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    }
    
    notifyListeners();
  }

  // Verificar status de autenticação - chamado na inicialização do app
  Future<void> checkAuthStatus() async {
    if (kDebugMode) {
      print('Checking authentication status...');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      
      if (token != null && userId != null) {
        if (kDebugMode) {
          print('Found saved token and user ID');
        }
        
        // Tentar carregar dados do usuário salvos localmente primeiro
        await _loadSavedUserData(prefs, userId);
        
        // Verificar token com servidor (opcional - só se houver conexão)
        await _verifyTokenWithServer(token, prefs);
      } else {
        if (kDebugMode) {
          print('No saved authentication data found');
        }
        _isAuthenticated = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking auth status: $e');
      }
      // Em caso de erro, mantém o usuário logado se há dados locais
      // Não faz logout automático por erro de rede
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  // Carregar dados do usuário salvos localmente
  Future<void> _loadSavedUserData(SharedPreferences prefs, int userId) async {
    try {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        // Aqui você pode implementar a conversão de string para Map se necessário
        // Por agora, vamos usar o userId para criar um usuário básico
        _isAuthenticated = true;
        
        if (kDebugMode) {
          print('User authenticated from saved data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved user data: $e');
      }
    }
  }

  // Verificar token com servidor (não obrigatório)
  Future<void> _verifyTokenWithServer(String token, SharedPreferences prefs) async {
    try {
      final response = await ApiService.verifyToken(token);
      
      if (response.containsKey('success') && response['success'] == true) {
        if (kDebugMode) {
          print('Token verified successfully with server');
        }
        
        // Atualizar dados do usuário se disponível
        if (response.containsKey('user') && response['user'] != null) {
          _user = User.fromJson(response['user']);
          await _saveUpdatedUserData();
        }
        
        _isAuthenticated = true;
      } else {
        // Token inválido no servidor - fazer logout
        if (kDebugMode) {
          print('Token invalid on server - logging out');
        }
        await _clearAuthData(prefs);
        _isAuthenticated = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying token with server: $e');
        print('Keeping user logged in due to network error');
      }
      // Em caso de erro de rede, manter usuário logado
      // Não fazer logout automático
      if (_isAuthenticated) {
        if (kDebugMode) {
          print('Maintaining authentication status due to network error');
        }
      }
    }
  }

  // Limpar dados de autenticação
  Future<void> _clearAuthData(SharedPreferences prefs) async {
    try {
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      await prefs.remove('login_timestamp');
      
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing auth data: $e');
      }
    }
  }

  // Método para forçar re-verificação do token (opcional)
  Future<bool> refreshAuthStatus() async {
    if (!_isAuthenticated) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final response = await ApiService.verifyToken(token);
        
        if (response.containsKey('success') && response['success'] == true) {
          return true;
        } else {
          await logout();
          return false;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing auth status: $e');
      }
      // Manter logado em caso de erro de rede
      return true;
    }
    
    return false;
  }
}