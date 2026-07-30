import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';

/// Enum untuk tipe notifikasi
enum NotificationType { success, error, warning, info }

/// Helper class untuk menampilkan notifikasi yang konsisten dan premium
/// di seluruh aplikasi.
class AppNotification {
  AppNotification._();

  // ─── Warna & Ikon per tipe ───────────────────────────────────────────────

  static Color _bgColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF166534); // deep green
      case NotificationType.error:
        return const Color(0xFF9F1239); // deep rose
      case NotificationType.warning:
        return const Color(0xFF92400E); // deep amber
      case NotificationType.info:
        return const Color(0xFF1E3A5F); // deep blue
    }
  }

  static Color _accentColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4ADE80); // bright green
      case NotificationType.error:
        return const Color(0xFFFB7185); // bright rose
      case NotificationType.warning:
        return const Color(0xFFFBBF24); // bright amber
      case NotificationType.info:
        return const Color(0xFF60A5FA); // bright blue
    }
  }

  static IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.cancel_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  // ─── Metode utama ────────────────────────────────────────────────────────

  /// Tampilkan notifikasi floating premium.
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    void display() {
      try {
        final targetCtx = rootNavigatorKey.currentContext ?? context;
        final messenger = ScaffoldMessenger.maybeOf(targetCtx) ?? ScaffoldMessenger.maybeOf(context);
        if (messenger != null && messenger.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              duration: duration,
              content: _NotificationContent(
                message: message,
                title: title,
                type: type,
                bgColor: _bgColor(type),
                accentColor: _accentColor(type),
                icon: _icon(type),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('AppNotification display error: $e');
      }
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => display());
    } else {
      display();
    }
  }

  // ─── Shortcut methods ────────────────────────────────────────────────────

  /// Notifikasi login berhasil.
  static void loginSuccess(BuildContext context, String userName) {
    show(
      context,
      title: 'Login Berhasil! 🌾',
      message: 'Selamat datang kembali, $userName.',
      type: NotificationType.success,
    );
  }

  /// Notifikasi login gagal.
  static void loginError(BuildContext context, String errorMsg) {
    show(
      context,
      title: 'Login Gagal',
      message: errorMsg,
      type: NotificationType.error,
    );
  }

  /// Notifikasi registrasi berhasil.
  static void registerSuccess(BuildContext context) {
    show(
      context,
      title: 'Registrasi Berhasil! 🎉',
      message: 'Akun Anda telah dibuat. Silakan masuk.',
      type: NotificationType.success,
      duration: const Duration(seconds: 4),
    );
  }

  /// Notifikasi registrasi gagal.
  static void registerError(BuildContext context, String errorMsg) {
    show(
      context,
      title: 'Registrasi Gagal',
      message: errorMsg,
      type: NotificationType.error,
    );
  }

  /// Notifikasi logout berhasil.
  static void logoutSuccess(BuildContext context) {
    show(
      context,
      title: 'Keluar Berhasil',
      message: 'Sampai jumpa! Anda telah keluar dari aplikasi.',
      type: NotificationType.info,
    );
  }

  /// Notifikasi profil berhasil diperbarui.
  static void profileUpdateSuccess(BuildContext context) {
    show(
      context,
      title: 'Profil Diperbarui',
      message: 'Data profil Anda berhasil disimpan.',
      type: NotificationType.success,
    );
  }

  /// Notifikasi profil gagal diperbarui.
  static void profileUpdateError(BuildContext context) {
    show(
      context,
      title: 'Gagal Memperbarui',
      message: 'Terjadi kesalahan saat menyimpan profil.',
      type: NotificationType.error,
    );
  }

  /// Notifikasi foto profil berhasil diubah.
  static void avatarUpdateSuccess(BuildContext context) {
    show(
      context,
      title: 'Foto Diperbarui',
      message: 'Foto profil Anda berhasil diubah.',
      type: NotificationType.success,
    );
  }

  /// Notifikasi foto profil gagal diubah.
  static void avatarUpdateError(BuildContext context) {
    show(
      context,
      title: 'Gagal Mengubah Foto',
      message: 'Terjadi kesalahan saat mengubah foto profil.',
      type: NotificationType.error,
    );
  }

  /// Notifikasi lupa password.
  static void forgotPassword(BuildContext context) {
    show(
      context,
      title: 'Reset Password',
      message: 'Silakan hubungi admin untuk mereset password Anda.',
      type: NotificationType.info,
    );
  }

  /// Notifikasi umum.
  static void info(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: NotificationType.info);
  }

  static void success(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: NotificationType.success);
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: NotificationType.error);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: NotificationType.warning);
  }
}

// ─── Widget konten notifikasi ────────────────────────────────────────────────

class _NotificationContent extends StatelessWidget {
  final String message;
  final String? title;
  final NotificationType type;
  final Color bgColor;
  final Color accentColor;
  final IconData icon;

  const _NotificationContent({
    required this.message,
    required this.type,
    required this.bgColor,
    required this.accentColor,
    required this.icon,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Accent bar (decorative)
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
