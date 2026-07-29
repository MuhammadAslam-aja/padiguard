import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../core/widgets/auth_responsive_wrapper.dart';
import '../auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pre-fill fields for easy demo/testing
  void _fillMockCredentials(String role) {
    if (role == 'petani') {
      _emailController.text = 'petani@gmail.com';
      _passwordController.text = 'petani123';
    } else {
      _emailController.text = 'admin@gmail.com';
      _passwordController.text = 'admin123';
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).login(email, password, _rememberMe);

    if (success) {
      // Simpan notifikasi ke provider agar ditampilkan di dashboard setelah navigasi
      final state = ref.read(authProvider);
      final userName = state.user?.name ?? '';
      ref.read(pendingNotificationProvider.notifier).state = PendingNotification(
        title: 'Login Berhasil! 🌾',
        message: 'Selamat datang kembali, $userName.',
        type: NotificationType.success,
      );
    } else {
      // Gagal login: tampilkan di sini langsung
      if (mounted) {
        final state = ref.read(authProvider);
        AppNotification.loginError(
          context,
          state.errorMessage ?? 'Login Gagal. Coba lagi.',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  void _checkPendingNotification() {
    if (!mounted) return;
    final pending = ref.read(pendingNotificationProvider);
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = rootNavigatorKey.currentContext ?? context;
        AppNotification.show(
          ctx,
          title: pending.title,
          message: pending.message,
          type: pending.type,
        );
        ref.read(pendingNotificationProvider.notifier).state = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PendingNotification?>(pendingNotificationProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkPendingNotification();
        });
      }
    });

    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthResponsiveWrapper(
      child: Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                
                // Welcome header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 48,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selamat Datang Kembali',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk untuk menggunakan sistem deteksi YOLOv12',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by Tirza Marsena (6150101220009)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                 const SizedBox(height: 16),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Field
                      Text(
                        'Email',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan email Anda',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      Text(
                        'Password',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password Anda',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Options Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.successColor,
                              ),
                              Text(
                                'Ingat Saya',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              AppNotification.forgotPassword(context);
                            },
                            child: Text(
                              'Lupa Password?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.status == AuthStatus.loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.status == AuthStatus.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Masuk'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Register Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text(
                              'Daftar Sekarang',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }
}
