import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_mock_data.dart';
import 'secure_storage.dart';
import '../config/constants.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService secureStorage;
  final ApiMockData mockDb = ApiMockData();

  DioClient({required this.secureStorage}) : dio = Dio() {
    dio.options.baseUrl = AppConstants.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // Add Interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic baseUrl update per request (handles web host changes: localhost, IP, ngrok)
          options.baseUrl = AppConstants.baseUrl;
          
          // Bersihkan prefix 'api/' jika baseUrl sudah berakhiran '/api/' untuk mencegah duplikasi URL (/api/api/...)
          if (options.baseUrl.endsWith('/api/') || options.baseUrl.endsWith('/api')) {
            if (options.path.startsWith('api/')) {
              options.path = options.path.substring(4);
            } else if (options.path.startsWith('/api/')) {
              options.path = options.path.substring(5);
            }
          }
          
          // Add JWT Token to header if exists
          try {
            final token = await secureStorage.read(AppConstants.keyToken).timeout(
              const Duration(seconds: 1),
              onTimeout: () => null,
            );
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            if (kDebugMode) print('Token read interceptor error: $e');
          }
          
          if (kDebugMode) {
            print('--> Request: ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) print('Data: ${options.data}');
          }

          // Mock Interceptor: Catch all requests if toggle is enabled
          if (AppConstants.useMockApi) {
            return _handleMockResponse(options, handler);
          }
          // Tambahkan header bypass ngrok interstitial page
          // agar API tidak diblokir saat diakses via ngrok tunnel
          options.headers['ngrok-skip-browser-warning'] = 'true';

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('<-- Response: ${response.statusCode} for ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print('x-- Error: ${e.message} for ${e.requestOptions.path}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _handleMockResponse(RequestOptions options, RequestInterceptorHandler handler) async {
    // Simulate network latency (800 milliseconds)
    await Future.delayed(const Duration(milliseconds: 800));

    var path = options.path.replaceAll(AppConstants.baseUrl, '').replaceAll(AppConstants.defaultBaseUrl, '');
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    final method = options.method.toUpperCase();
    final headers = options.headers;

    // Helper to extract path variable id
    String? getPathId(String routePattern) {
      final regExp = RegExp(routePattern);
      final match = regExp.firstMatch(path);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
      return null;
    }

    try {
      // 1. Auth Endpoint: Login
      if (path == 'api/auth/login' && method == 'POST') {
        final data = options.data;
        final String email = data['email'] ?? '';
        final String password = data['password'] ?? '';

        final user = mockDb.authenticate(email, password);
        if (user != null) {
          final dummyToken = 'jwt_token_mock_for_${user['email']}';
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'token': dummyToken,
              'user': user,
            },
          ));
          return;
        } else {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'message': 'Email atau password salah.'},
            ),
          ));
          return;
        }
      }

      // 2. Auth Endpoint: Register
      if (path == 'api/auth/register' && method == 'POST') {
        final data = options.data;
        final String name = data['name'] ?? '';
        final String email = data['email'] ?? '';
        final String password = data['password'] ?? '';
        final String role = data['role'] ?? 'petani';

        final success = mockDb.register(name, email, password, role);
        if (success) {
          final user = mockDb.getUserByEmail(email);
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'success': true,
              'message': 'Registrasi berhasil.',
              'user': user,
            },
          ));
          return;
        } else {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'Email sudah terdaftar.'},
            ),
          ));
          return;
        }
      }

      // 3. Auth Endpoint: Logout
      if (path == 'api/auth/logout' && method == 'POST') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'message': 'Logout berhasil.'},
        ));
        return;
      }

      // Extract authorization email for guards
      final authHeader = headers['Authorization']?.toString() ?? '';
      String? currentUserEmail;
      if (authHeader.startsWith('Bearer jwt_token_mock_for_')) {
        currentUserEmail = authHeader.replaceFirst('Bearer jwt_token_mock_for_', '');
      }

      // Guest checks
      if (currentUserEmail == null && 
          (path.startsWith('api/auth/me') || 
           path.startsWith('api/detection') || 
           path.startsWith('api/admin'))) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'message': 'Unauthorized. Silakan login kembali.'},
          ),
        ));
        return;
      }

      final currentUser = currentUserEmail != null ? mockDb.getUserByEmail(currentUserEmail) : null;

      // 4. Auth Endpoint: Me
      if (path == 'api/auth/me' && method == 'GET') {
        if (currentUser != null) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'user': currentUser},
          ));
          return;
        }
      }

      // 5. Auth Endpoint: Update Profile
      if (path == 'api/auth/profile' && method == 'PUT') {
        final data = options.data;
        final String name = data['name'] ?? '';
        final String? password = data['password'];

        final success = mockDb.updateProfile(currentUserEmail!, name, password);
        if (success) {
          final updatedUser = mockDb.getUserByEmail(currentUserEmail);
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Profil berhasil diperbarui.',
              'user': updatedUser,
            },
          ));
          return;
        }
      }

      // 6. Detection: Upload / Scan (YOLOv12)
      if (path == 'api/detection' && method == 'POST') {
        // Mock YOLOv12 inference response
        final newDetection = mockDb.addMockDetection(
          currentUserEmail!,
          currentUser?['name'] ?? 'Petani',
          null, // Image path
        );
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {'success': true, 'detection': newDetection},
        ));
        return;
      }

      // 7. Detection: History list
      if (path == 'api/detection/history' && method == 'GET') {
        final emailFilter = currentUser?['role'] == 'admin' ? null : currentUserEmail;
        final list = mockDb.getDetectionHistory(emailFilter);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'history': list},
        ));
        return;
      }

      // 8. Detection: Get by ID
      final detectionId = getPathId(r'^/api/detection/([^/]+)$');
      if (detectionId != null && method == 'GET') {
        final det = mockDb.getDetectionById(detectionId);
        if (det != null) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'detection': det},
          ));
          return;
        } else {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Data deteksi tidak ditemukan.'},
            ),
          ));
          return;
        }
      }

      // 9. Detection: Delete
      if (detectionId != null && method == 'DELETE') {
        final success = mockDb.deleteDetection(detectionId);
        if (success) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'message': 'Data deteksi berhasil dihapus.'},
          ));
          return;
        } else {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'message': 'Data deteksi gagal dihapus.'},
            ),
          ));
          return;
        }
      }

      // ---- ADMIN ENDPOINTS ----
      if (currentUser?['role'] != 'admin' && path.startsWith('api/admin')) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 403,
            data: {'message': 'Akses khusus Admin.'},
          ),
        ));
        return;
      }

      // 10. Admin Dashboard Stats
      if (path == 'api/admin/dashboard' && method == 'GET') {
        final stats = mockDb.getAdminDashboardStats();
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'stats': stats},
        ));
        return;
      }

      // 11. Admin: Get Users list
      if (path == 'api/admin/users' && method == 'GET') {
        final list = mockDb.getAllUsers();
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'users': list},
        ));
        return;
      }

      // 12. Admin: Add User
      if (path == 'api/admin/users' && method == 'POST') {
        final data = options.data;
        final String name = data['name'] ?? '';
        final String email = data['email'] ?? '';
        final String password = data['password'] ?? '';
        final String role = data['role'] ?? 'petani';

        final success = mockDb.adminAddUser(name, email, password, role);
        if (success) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {'success': true, 'message': 'User berhasil dibuat.'},
          ));
          return;
        } else {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'Email sudah terdaftar.'},
            ),
          ));
          return;
        }
      }

      // 13. Admin: Update/Delete User
      final userId = getPathId(r'^/api/admin/users/([^/]+)$');
      if (userId != null) {
        if (method == 'PUT') {
          final data = options.data;
          final String name = data['name'] ?? '';
          final String email = data['email'] ?? '';
          final String role = data['role'] ?? 'petani';
          final String? password = data['password'];

          final success = mockDb.adminUpdateUser(userId, name, email, role, password);
          if (success) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'message': 'User berhasil diperbarui.'},
            ));
            return;
          }
        } else if (method == 'DELETE') {
          final success = mockDb.deleteUser(userId);
          if (success) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'message': 'User berhasil dihapus.'},
            ));
            return;
          }
        }
      }

      // 14. Admin: Get all detections list (cross-users)
      if (path == 'api/admin/detections' && method == 'GET') {
        final list = mockDb.getDetectionHistory(null);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'detections': list},
        ));
        return;
      }

      // 15. Admin: Dataset list
      if (path == 'api/admin/dataset' && method == 'GET') {
        final list = mockDb.getDatasetList();
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'dataset': list},
        ));
        return;
      }

      // 16. Admin: Upload dataset
      if (path == 'api/admin/dataset/upload' && method == 'POST') {
        final label = options.data?['label'] ?? 'Matang - Sehat';
        mockDb.uploadDataset(label, null);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {'success': true, 'message': 'Dataset berhasil diunggah.'},
        ));
        return;
      }

      // 17. Admin: Model Performance
      if (path == 'api/admin/model/performance' && method == 'GET') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': true, 'performance': mockDb.modelPerformance},
        ));
        return;
      }

      // 18. Admin: Retrain Model Trigger
      if (path == 'api/admin/model/retrain' && method == 'POST') {
        final newPerf = await mockDb.triggerRetrain();
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Model training selesai!',
            'performance': newPerf
          },
        ));
        return;
      }

      // Default route not found
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'message': 'Endpoint mock tidak ditemukan ($method $path).'},
        ),
      ));
    } catch (err) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: err,
        message: 'Koneksi error: ${err.toString()}',
      ));
    }
  }
}
