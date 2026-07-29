import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../../services/api_mock_data.dart';
import '../../../../services/weather_service.dart';
import '../../../history/presentation/widgets/detection_detail_sheet.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_notification.dart';
import 'package:dio/dio.dart';

class PetaniHomePage extends ConsumerStatefulWidget {
  const PetaniHomePage({super.key});

  @override
  ConsumerState<PetaniHomePage> createState() => _PetaniHomePageState();
}

class _PetaniHomePageState extends ConsumerState<PetaniHomePage> {
  WeatherData? _weather;
  bool _isLoadingWeather = true;
  String _weatherError = '';
  List<Map<String, dynamic>> _recentDetections = [];
  bool _isLoadingHistory = false;

  // GoRouter listener untuk refresh riwayat saat kembali ke beranda
  void _routerListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/petani/home')) {
        _loadHistory();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pasang listener GoRouter saat context sudah siap
    final router = GoRouter.of(context);
    router.routerDelegate.removeListener(_routerListener);
    router.routerDelegate.addListener(_routerListener);
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
  void dispose() {
    // Bersihkan listener saat widget dihapus
    try {
      final router = GoRouter.of(context);
      router.routerDelegate.removeListener(_routerListener);
    } catch (_) {}
    super.dispose();
  }

  ImageProvider? _getUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (kIsWeb || avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://') || avatarUrl.startsWith('blob:')) {
      return NetworkImage(avatarUrl);
    }
    return FileImage(File(avatarUrl));
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    if (AppConstants.useMockApi) {
      final mockDb = ApiMockData();
      final authState = ref.read(authProvider);
      final emailFilter = authState.user?.email;
      setState(() {
        _recentDetections = mockDb.getDetectionHistory(emailFilter).take(3).toList();
      });
      return;
    }

    setState(() { _isLoadingHistory = true; });
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('api/detection/history');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          final history = List<Map<String, dynamic>>.from(response.data['history']);
          setState(() {
            _recentDetections = history.take(3).toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() { _isLoadingHistory = false; });
    }
  }

  Future<void> _deleteHistoryItem(String id) async {
    if (AppConstants.useMockApi) {
      final mockDb = ApiMockData();
      mockDb.deleteDetection(id);
      _loadHistory();
      return;
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.delete('api/detection/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat berhasil dihapus.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menghapus riwayat.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() { _isLoadingWeather = true; _weatherError = ''; });
    try {
      final position = await WeatherService.getCurrentPosition();
      if (position != null) {
        final weather = await WeatherService.fetchWeatherByCoords(
          position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _weather = weather;
            _isLoadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _weatherError = 'Izin lokasi ditolak';
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = 'Gagal memuat cuaca';
          _isLoadingWeather = false;
        });
      }
    }
  }


  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar Akun',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
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

  // Open readable article dialog
  void _showTipDialog(BuildContext context, Map<String, String> tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage(tip['imageUrl']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tip['category']!,
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip['title']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip['desc']!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textDarkMuted
                          : AppTheme.textLightMuted,
                    ),
                  ),
                ],
              ),
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
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final recentDetections = _recentDetections;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, Petani!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        user?.name ?? 'Pengguna',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by Tirza Marsena (6150101220009)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9),
                        backgroundImage: _getUserAvatar(user?.avatar),
                        child: user?.avatar == null || user!.avatar.isEmpty
                            ? const Icon(Icons.person, color: AppTheme.successColor)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppTheme.errorColor, size: 22),
                        onPressed: () => _showLogoutConfirmation(context, ref),
                        tooltip: 'Keluar',
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Weather Dashboard Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isLoadingWeather
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Memuat data cuaca...', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      )
                    : _weather == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.location_off, color: Colors.white70, size: 18),
                                    const SizedBox(width: 4),
                                    Text(_weatherError.isEmpty ? 'Lokasi tidak tersedia' : _weatherError,
                                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                  ]),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                    onPressed: _loadWeather,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white, size: 18),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _weather!.regionName,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 14),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _loadWeather,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(WeatherService.getWeatherIcon(_weather!.icon),
                                          color: Colors.white, size: 40),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_weather!.description,
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600)),
                                          Text('Kelembapan: ${_weather!.humidity}%',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_weather!.temperature.round()}°C',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      WeatherService.getFarmingRecommendation(_weather!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: 28),

              // Scan Quick Action Button
              GestureDetector(
                onTap: () => context.go('/petani/scan'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF1B5E20),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pindai/Scan Padi',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ambil foto bulir padi & deteksi hama',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Recent Detections List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Deteksi Terakhir',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/petani/history'),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (recentDetections.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(Icons.crop_original, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada riwayat deteksi.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentDetections.length,
                  itemBuilder: (context, index) {
                    final item = recentDetections[index];
                    final date = DateTime.parse(item['date']);
                    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                    final hama = item['hamaName'] ?? 'Tidak Terdeteksi';
                    final isHama = item['hamaName'] != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => DetectionDetailSheet(
                              detection: item,
                              onDelete: (id) {
                                _deleteHistoryItem(id);
                              },
                            ),
                          );
                        },
                        leading: Hero(
                          tag: 'recent_det_img_${item['id']}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          isHama ? 'Hama: $hama' : 'Tanaman Sehat',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kematangan: ${item['kematangan']}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHama
                                ? AppTheme.accentWarning.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHama ? 'Terinfeksi' : 'Aman',
                            style: TextStyle(
                              color: isHama ? AppTheme.accentWarning : AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
