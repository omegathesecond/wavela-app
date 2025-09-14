import 'package:get/get.dart' as getx;
import 'api_service.dart';
import 'storage_service.dart';

class AuthApiService extends getx.GetxService {
  late ApiService _apiService;
  late StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _apiService = getx.Get.find<ApiService>();
    _storageService = getx.Get.find<StorageService>();
  }

  // Login user
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final data = {
      'email': email,
      'password': password,
    };

    final response = await _apiService.request<LoginResponse>(
      'POST',
      '/auth/login',
      data: data,
      parser: LoginResponse.fromJson,
    );

    // Save token to storage
    await _storageService.saveAuthToken(response.token);
    
    return response;
  }

  // Logout user
  Future<LogoutResponse> logout() async {
    final response = await _apiService.request<LogoutResponse>(
      'POST',
      '/auth/logout',
      parser: LogoutResponse.fromJson,
    );

    // Clear token from storage
    await _storageService.clearAuthData();
    
    return response;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAuthToken();
    return token != null;
  }

  // Get current auth token
  Future<String?> getAuthToken() async {
    return await _storageService.getAuthToken();
  }
}

// Response models
class LoginResponse {
  final String token;
  final int expiresIn;
  final AuthUser user;

  LoginResponse({
    required this.token,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      expiresIn: json['expiresIn'],
      user: AuthUser.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}

class LogoutResponse {
  final String message;

  LogoutResponse({
    required this.message,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String role;

  AuthUser({
    required this.id,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }
}