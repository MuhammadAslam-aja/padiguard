import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/app_notification.dart';
import '../../../services/api_mock_data.dart';
import '../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = AuthState.loading();
    final secureStorage = _ref.read(secureStorageProvider);
    final dioClient = _ref.read(dioClientProvider);

    try {
      final token = await secureStorage.read(AppConstants.keyToken).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (token == null) {
        state = AuthState.unauthenticated();
        return;
      }

      // Fetch user profile from backend
      final response = await dioClient.dio.get('api/auth/me').timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = UserModel.fromJson(response.data['user']);
        state = AuthState.authenticated(user);
      } else {
        // Clear token if invalid
        await secureStorage.delete(AppConstants.keyToken);
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      // Jika timeout atau error jaringan -> langsung ke halaman login
      try {
        await secureStorage.delete(AppConstants.keyToken);
      } catch (_) {}
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password, bool rememberMe) async {
    state = AuthState.loading();
    final secureStorage = _ref.read(secureStorageProvider);
    final sharedPrefs = _ref.read(sharedPrefsProvider);
    final dioClient = _ref.read(dioClientProvider);

    try {
      final response = await dioClient.dio.post(
        'api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);
        
        await secureStorage.write(AppConstants.keyToken, token);
        await sharedPrefs.setString(AppConstants.keyUserRole, user.role);
        await sharedPrefs.setString(AppConstants.keyUserName, user.name);
        await sharedPrefs.setString(AppConstants.keyUserEmail, user.email);

        // Set pending notification sebelum perpindahan state/halaman
        _ref.read(pendingNotificationProvider.notifier).state = PendingNotification(
          title: 'Login Berhasil! 🌾',
          message: 'Selamat datang kembali, ${user.name}.',
          type: NotificationType.success,
        );

        state = AuthState.authenticated(user);
        return true;
      } else {
        state = AuthState.error(response.data['message'] ?? 'Login gagal.');
        return false;
      }
    } on DioException catch (e) {
      String msg = 'Email atau password yang Anda masukkan salah.';
      final resData = e.response?.data;
      if (resData is Map && resData['message'] != null) {
        msg = resData['message'].toString();
      } else if (resData is String && resData.isNotEmpty) {
        try {
          final parsed = jsonDecode(resData);
          if (parsed is Map && parsed['message'] != null) {
            msg = parsed['message'].toString();
          }
        } catch (_) {}
      }
      state = AuthState.error(msg);
      return false;
    } catch (e) {
      state = AuthState.error('Terjadi kesalahan koneksi. Silakan coba lagi.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    state = AuthState.loading();
    final dioClient = _ref.read(dioClientProvider);

    try {
      final response = await dioClient.dio.post(
        'api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        state = AuthState.unauthenticated(); // Require login after register or we can auto-login
        return true;
      } else {
        state = AuthState.error(response.data['message'] ?? 'Registrasi gagal.');
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registrasi gagal.';
      state = AuthState.error(msg);
      return false;
    } catch (e) {
      state = AuthState.error('Terjadi kesalahan jaringan.');
      return false;
    }
  }

  Future<bool> updateProfile(String name, String? newPassword) async {
    if (state.status != AuthStatus.authenticated) return false;
    
    final dioClient = _ref.read(dioClientProvider);
    final sharedPrefs = _ref.read(sharedPrefsProvider);

    try {
      final response = await dioClient.dio.put(
        'api/auth/profile',
        data: {
          'name': name,
          if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedUser = UserModel.fromJson(response.data['user']);
        await sharedPrefs.setString(AppConstants.keyUserName, updatedUser.name);
        state = AuthState.authenticated(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAvatar(XFile xFile) async {
    if (state.status != AuthStatus.authenticated) return false;
    
    final currentUser = state.user!;
    
    if (!AppConstants.useMockApi) {
      final dioClient = _ref.read(dioClientProvider);
      try {
        final bytes = await xFile.readAsBytes();
        final filename = xFile.name.isNotEmpty ? xFile.name : 'avatar.jpg';
        final file = MultipartFile.fromBytes(
          bytes,
          filename: filename,
        );
        
        final formData = FormData.fromMap({
          'avatar': file,
        });
        
        final response = await dioClient.dio.post(
          'api/auth/avatar',
          data: formData,
        );
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          final updatedUser = UserModel.fromJson(response.data['user']);
          state = AuthState.authenticated(updatedUser);
          return true;
        }
        return false;
      } catch (e) {
        return false;
      }
    }
    
    // Fallback/Mock Database update
    final mockDb = ApiMockData();
    final idx = mockDb.users.indexWhere((u) => u['email'] == currentUser.email);
    if (idx != -1) {
      mockDb.users[idx]['avatar'] = xFile.path;
      final updatedUser = currentUser.copyWith(avatar: xFile.path);
      state = AuthState.authenticated(updatedUser);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    state = AuthState.loading();
    final secureStorage = _ref.read(secureStorageProvider);
    final sharedPrefs = _ref.read(sharedPrefsProvider);
    final dioClient = _ref.read(dioClientProvider);

    try {
      await dioClient.dio.post('api/auth/logout');
    } catch (_) {}

    await secureStorage.delete(AppConstants.keyToken);
    await sharedPrefs.remove(AppConstants.keyUserRole);
    await sharedPrefs.remove(AppConstants.keyUserName);
    await sharedPrefs.remove(AppConstants.keyUserEmail);

    _ref.read(pendingNotificationProvider.notifier).state = const PendingNotification(
      title: 'Keluar Berhasil',
      message: 'Sampai jumpa! Anda telah keluar dari aplikasi.',
      type: NotificationType.info,
    );

    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
