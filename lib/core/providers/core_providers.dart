import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/dio_client.dart';
import '../../services/secure_storage.dart';
import '../../services/shared_prefs.dart';
import '../utils/app_notification.dart';

// Providers for basic services
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Since SharedPreferences initialization is asynchronous, we will override this provider in main.dart
final sharedPrefsProvider = Provider<SharedPrefsService>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden in main.dart');
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage: secureStorage);
});

/// Model untuk notifikasi yang tertunda (belum ditampilkan karena navigasi)
class PendingNotification {
  final String title;
  final String message;
  final NotificationType type;

  const PendingNotification({
    required this.title,
    required this.message,
    required this.type,
  });
}

/// Provider untuk menyimpan notifikasi pending yang harus ditampilkan
/// setelah navigasi ke halaman berikutnya selesai.
/// Contoh: notifikasi "Login Berhasil" yang ditampilkan di dashboard.
final pendingNotificationProvider =
    StateProvider<PendingNotification?>((ref) => null);

