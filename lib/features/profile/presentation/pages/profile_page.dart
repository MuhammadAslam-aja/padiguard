import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../core/utils/web_camera_stub.dart'
    if (dart.library.html) '../../../../core/utils/web_camera_web.dart';
import '../../../auth/presentation/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  final bool isAdmin;

  const ProfilePage({super.key, required this.isAdmin});

  ImageProvider? _getUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (kIsWeb || avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://') || avatarUrl.startsWith('blob:')) {
      return NetworkImage(avatarUrl);
    }
    return FileImage(File(avatarUrl));
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ganti Foto Profil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: AppTheme.primaryLight),
              ),
              title: Text('Kamera', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ambil foto langsung dari kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: Text('Galeri', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: const Text('Pilih foto dari galeri HP / Komputer'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
    
    if (source != null) {
      XFile? file;
      
      if (source == ImageSource.camera) {
        if (kIsWeb) {
          final bytes = await captureFromWebCamera(context);
          if (bytes != null) {
            file = XFile.fromData(
              bytes,
              name: 'avatar_camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            );
          }
        } else {
          file = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 800,
            maxHeight: 800,
          );
        }
      } else {
        file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
        );
      }

      if (file != null) {
        final success = await ref.read(authProvider.notifier).updateAvatar(file);
        if (context.mounted) {
          if (success) {
            AppNotification.avatarUpdateSuccess(context);
          } else {
            AppNotification.avatarUpdateError(context);
          }
        }
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (Opsional)',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Kosongkan jika tidak ingin diubah',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final success = await ref.read(authProvider.notifier).updateProfile(
                nameController.text.trim(),
                passwordController.text,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  AppNotification.profileUpdateSuccess(context);
                } else {
                  AppNotification.profileUpdateError(context);
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(
              'Tentang Aplikasi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplikasi Skripsi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '"KLASIFIKASI JENIS HAMA DAN KEMATANGAN TANAMAN PADI MENGGUNAKAN METODE YOLOV12"',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sistem pendeteksi hama dan kematangan tanaman padi berbasis mobile. Dikembangkan menggunakan Flutter dan ditenagai oleh model YOLOv12 di backend untuk klasifikasi objek secara presisi.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Versi Aplikasi', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(AppConstants.appVersion, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bantuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.faqList.length,
            itemBuilder: (context, index) {
              final faq = AppConstants.faqList[index];
              return ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              ref.read(pendingNotificationProvider.notifier).state = const PendingNotification(
                title: 'Berhasil Keluar',
                message: 'Anda telah keluar dari akun.',
                type: NotificationType.info,
              );
              await ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAdmin ? 'Profil Admin' : 'Profil Pengguna'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            onPressed: () => _showLogoutConfirmation(context, ref),
            tooltip: 'Keluar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Avatar & Name Card
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _changeAvatar(context, ref),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9),
                          backgroundImage: _getUserAvatar(user?.avatar),
                          child: user?.avatar == null || user!.avatar.isEmpty
                              ? const Icon(Icons.person, size: 54, color: AppTheme.successColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppTheme.accentWarning.withOpacity(0.12)
                          : AppTheme.successColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAdmin ? 'ADMINISTRATOR' : 'PETANI',
                      style: TextStyle(
                        color: isAdmin ? AppTheme.accentWarning : AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 36),
            
            // Profile Options Menu
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  // User Details - Email
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email', style: TextStyle(fontSize: 13)),
                    trailing: Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // Action: Edit Profile
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Profil', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Ubah nama atau password', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showEditProfileDialog(context, ref, user?.name ?? ''),
                  ),
                  const Divider(height: 1),
                  
                  // Action: FAQ / Bantuan
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Bantuan', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Petunjuk', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showFAQDialog(context),
                  ),
                  const Divider(height: 1),
                  
                  // Action: About App
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Tentang Aplikasi', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Informasi skripsi & pengembang', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmation(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Aplikasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3B0712) : const Color(0xFFFDE8E8),
                  foregroundColor: AppTheme.errorColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
