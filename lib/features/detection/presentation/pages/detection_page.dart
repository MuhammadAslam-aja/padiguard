import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/yolo_bounding_box.dart';
import '../../../../core/utils/web_camera_stub.dart'
    if (dart.library.html) '../../../../core/utils/web_camera_web.dart';
import '../../../faq/presentation/pages/faq_page.dart';

// ─── Langkah proses inferensi YOLO ─────────────────────────────────────────
const List<String> _inferenceSteps = [
  '📤  Gambar dikirim ke server...',
  '🔍  Model YOLOv12 melakukan inferensi...',
  '🌾  Menganalisis kematangan padi...',
  '✅  Hasil deteksi berhasil diperoleh!',
];

class DetectionPage extends ConsumerStatefulWidget {
  const DetectionPage({super.key});

  @override
  ConsumerState<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends ConsumerState<DetectionPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _detectionResult;
  String? _errorMessage;
  bool _isNonRice = false;

  // Loading step animation
  int _currentStep = 0;
  Timer? _stepTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Start cycling through inference step labels ──────────────────────────
  void _startStepAnimation() {
    _currentStep = 0;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _currentStep =
            (_currentStep + 1).clamp(0, _inferenceSteps.length - 1);
      });
      if (_currentStep == _inferenceSteps.length - 1) t.cancel();
    });
  }

  void _stopStepAnimation() {
    _stepTimer?.cancel();
  }

  // ─── Image Picking ────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source,
      {CameraDevice preferredCamera = CameraDevice.rear}) async {
    try {
      final XFile? file = kIsWeb
          ? await _picker.pickImage(
              source: source, preferredCameraDevice: preferredCamera)
          : await _picker.pickImage(
              source: source,
              preferredCameraDevice: preferredCamera,
              imageQuality: 85,
              maxWidth: 1024,
            );

      if (file != null) {
        Uint8List? bytes;
        try {
          bytes = await file.readAsBytes();
        } catch (_) {}
        setState(() {
          _pickedFile = file;
          _webImageBytes = bytes;
          _detectionResult = null;
          _errorMessage = null;
          _isNonRice = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengakses media: ${e.toString()}';
      });
    }
  }

  void _showCameraOptions(BuildContext context) {
    if (kIsWeb) {
      _openWebCamera();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Kamera',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.camera_rear, color: Color(0xFF4CAF50)),
              title: const Text('Kamera Belakang (Utama)'),
              subtitle: const Text(
                  'Direkomendasikan untuk memfoto sawah & tanaman padi'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera,
                    preferredCamera: CameraDevice.rear);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_front, color: Colors.amber),
              title: const Text('Kamera Depan'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera,
                    preferredCamera: CameraDevice.front);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWebCamera() async {
    try {
      final Uint8List? bytes = await captureFromWebCamera(context);
      if (bytes != null && bytes.isNotEmpty) {
        final name = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file =
            XFile.fromData(bytes, name: name, mimeType: 'image/jpeg');
        setState(() {
          _pickedFile = file;
          _webImageBytes = bytes;
          _detectionResult = null;
          _errorMessage = null;
          _isNonRice = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuka kamera: ${e.toString()}';
      });
    }
  }

  // ─── Analyze Image ────────────────────────────────────────────────────────
  Future<void> _analyzeImage() async {
    if (_pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _isNonRice = false;
      _currentStep = 0;
    });
    _startStepAnimation();

    final dioClient = ref.read(dioClientProvider);

    try {
      final Uint8List imageBytes =
          _webImageBytes ?? await _pickedFile!.readAsBytes();
      final MultipartFile file;
      if (kIsWeb) {
        file = MultipartFile.fromBytes(imageBytes,
            filename: _pickedFile!.name);
      } else {
        file = await MultipartFile.fromFile(_pickedFile!.path,
            filename: _pickedFile!.name);
      }

      final response = await dioClient.dio.post(
        'api/detection',
        data: FormData.fromMap({
          'image': file,
          'image_base64': base64Encode(imageBytes),
        }),
      );

      dynamic resData = response.data;
      if (resData is String) {
        try {
          resData = jsonDecode(resData);
        } catch (_) {}
      }

      _stopStepAnimation();

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          resData is Map &&
          resData['success'] == true) {
        Map<String, dynamic> detection =
            Map<String, dynamic>.from(resData['detection']);
        detection['imageUrl'] =
            (_webImageBytes != null) ? '' : _pickedFile!.path;

        setState(() {
          _detectionResult = detection;
          _isAnalyzing = false;
          _currentStep = _inferenceSteps.length - 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analisis berhasil! Hasil deteksi dimuat.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final serverMsg = (resData is Map && resData['message'] != null)
            ? resData['message'].toString()
            : 'Gagal menganalisis gambar.';

        // Cek apakah pesan merupakan penolakan non-padi
        final isNonRiceMsg = serverMsg.toLowerCase().contains('non-padi') ||
            serverMsg.toLowerCase().contains('bukan tanaman padi') ||
            serverMsg.toLowerCase().contains('gambar terdeteksi sebagai');

        setState(() {
          _errorMessage = serverMsg;
          _isAnalyzing = false;
          _isNonRice = isNonRiceMsg;
        });
      }
    } catch (e) {
      _stopStepAnimation();
      String errMsg = 'Gagal menganalisis gambar.';
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          dynamic errorData = e.response!.data;
          if (errorData is String) {
            try {
              errorData = jsonDecode(errorData);
            } catch (_) {}
          }
          if (errorData is Map && errorData['message'] != null) {
            errMsg = errorData['message'].toString();
          } else if (errorData is String && errorData.isNotEmpty) {
            errMsg = errorData;
          } else {
            errMsg =
                'Respon Server (${e.response!.statusCode}): Gagal memproses gambar.';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errMsg = 'Koneksi gagal: Tidak dapat menghubungi server backend.';
        }
      }

      final isNonRiceErr = errMsg.toLowerCase().contains('non-padi') ||
          errMsg.toLowerCase().contains('bukan tanaman padi') ||
          errMsg.toLowerCase().contains('gambar terdeteksi sebagai');

      setState(() {
        _errorMessage = errMsg;
        _isAnalyzing = false;
        _isNonRice = isNonRiceErr;
      });
      if (mounted && !isNonRiceErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _pickedFile = null;
      _webImageBytes = null;
      _isAnalyzing = false;
      _detectionResult = null;
      _errorMessage = null;
      _isNonRice = false;
      _currentStep = 0;
    });
  }

  Color _getDangerColor(String dangerLevel) {
    switch (dangerLevel) {
      case 'Tinggi':
        return AppTheme.errorColor;
      case 'Sedang':
        return AppTheme.accentWarning;
      case 'Aman':
      default:
        return AppTheme.successColor;
    }
  }

  IconData _getDangerIcon(String dangerLevel) {
    switch (dangerLevel) {
      case 'Tinggi':
        return Icons.warning_rounded;
      case 'Sedang':
        return Icons.warning_amber_rounded;
      case 'Aman':
      default:
        return Icons.check_circle_rounded;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan Padi – YOLOv12'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Panduan Penggunaan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FaqPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Instructions ──────────────────────────────────
            if (_pickedFile == null && !_isAnalyzing) ...[
              Text(
                'Ambil Foto Tanaman Padi',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Foto bulir padi atau daun padi secara dekat untuk mendeteksi hama dan kematangan.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.textDarkMuted
                      : AppTheme.textLightMuted,
                ),
              ),
              const SizedBox(height: 14),
              // Tips row
              _buildTipRow(isDark),
              const SizedBox(height: 18),
            ],

            // ── Image Preview / Loading / Empty State ────────────────
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                height: 300,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isAnalyzing
                        ? AppTheme.successColor.withOpacity(0.4)
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    width: _isAnalyzing ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isAnalyzing
                      ? _buildLoadingState(isDark)
                      : _detectionResult != null
                          ? _buildDetectionResultImage()
                          : _pickedFile != null
                              ? _buildImagePreview()
                              : _buildEmptyState(isDark),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Non-Rice Banner ──────────────────────────────────────
            if (_isNonRice && _errorMessage != null) ...[
              _buildNonRiceBanner(context, isDark),
              const SizedBox(height: 16),
            ] else if (_errorMessage != null && !_isNonRice) ...[
              // Generic error
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.errorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action Buttons ───────────────────────────────────────
            if (_pickedFile == null && !_isAnalyzing) _buildPickButtons(),

            if (_pickedFile != null &&
                _detectionResult == null &&
                !_isAnalyzing)
              _buildAnalyzeButtons(isDark),

            // ── Result Section ───────────────────────────────────────
            if (_detectionResult != null && !_isAnalyzing) ...[
              const SizedBox(height: 8),
              _buildResultSection(isDark),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Loading State ────────────────────────────────────────────────────────
  Widget _buildLoadingState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SpinKitWaveSpinner(
          color: AppTheme.successColor,
          size: 60,
        ),
        const SizedBox(height: 24),
        // Step label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            _inferenceSteps[_currentStep],
            key: ValueKey(_currentStep),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Step dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_inferenceSteps.length, (i) {
            final active = i <= _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.successColor
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.grain_rounded,
            size: 56,
            color: AppTheme.successColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada foto dipilih',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ambil foto atau pilih dari galeri\nuntuk memulai deteksi',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Image Preview ────────────────────────────────────────────────────────
  Widget _buildImagePreview() {
    if (_webImageBytes != null) {
      return Image.memory(_webImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true);
    }
    if (kIsWeb) {
      return Image.network(_pickedFile!.path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity);
    }
    return Image.file(File(_pickedFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity);
  }

  // ─── Detection Result Image with label ───────────────────────────────────
  Widget _buildDetectionResultImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        YoloBoundingBox(
          imageUrl: _detectionResult!['imageUrl'],
          imageBytes: _webImageBytes,
          boundingBoxes: _detectionResult!['boundingBoxes'] ?? [],
        ),
        // Label overlay
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppTheme.successColor, size: 14),
                const SizedBox(width: 5),
                Text(
                  'Hasil Analisis YOLOv12',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tips Row ─────────────────────────────────────────────────────────────
  Widget _buildTipRow(bool isDark) {
    final tips = [
      {'icon': Icons.wb_sunny_outlined, 'label': 'Pencahayaan cukup'},
      {'icon': Icons.center_focus_strong_outlined, 'label': 'Foto jelas'},
      {'icon': Icons.straighten_outlined, 'label': 'Jarak 20–40 cm'},
    ];
    return Row(
      children: tips.map((tip) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(tip['icon'] as IconData,
                    size: 18, color: AppTheme.successColor),
                const SizedBox(height: 4),
                Text(
                  tip['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Non-Rice Banner ──────────────────────────────────────────────────────
  Widget _buildNonRiceBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD43B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD43B).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grass_rounded,
                  color: Color(0xFF856404), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Objek yang terdeteksi bukan tanaman padi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF856404),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sistem mendeteksi gambar ini bukan tanaman padi (sawah, bulir, atau daun padi). '
            'Silakan gunakan gambar tanaman padi yang valid untuk melakukan deteksi hama dan kematangan.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF664D03),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Ganti Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF856404),
                    side: const BorderSide(color: Color(0xFFFFD43B)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FaqPage()),
                  ),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Panduan Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF856404),
                    side: const BorderSide(color: Color(0xFFFFD43B)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Pick Buttons (empty state) ───────────────────────────────────────────
  Widget _buildPickButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeri'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showCameraOptions(context),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Analyze / Reset Buttons ──────────────────────────────────────────────
  Widget _buildAnalyzeButtons(bool isDark) {
    return Column(
      children: [
        // Quick action: change photo
        if (_isNonRice)
          const SizedBox.shrink()
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _analyzeImage,
                  icon: const Icon(Icons.biotech_rounded),
                  label: const Text('Mulai Analisis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1B5E20),
                    foregroundColor:
                        isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Change photo row
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Ganti dari Galeri',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textLightMuted),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showCameraOptions(context),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Ganti Kamera',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textLightMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Result Section ───────────────────────────────────────────────────────
  Widget _buildResultSection(bool isDark) {
    final result = _detectionResult!;
    final hamaName = result['hamaName'] as String?;
    final hamaConf = (result['hamaConfidence'] ?? 0.0) as num;
    final kematangan = result['kematangan'] as String? ?? '-';
    final kematanganConf = (result['kematanganConfidence'] ?? 0.0) as num;
    final dangerLevel = result['dangerLevel'] as String? ?? 'Aman';
    final description = result['description'] as String? ?? '';
    final treatment = result['treatment'] as String? ?? '';
    final date = result['date'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.analytics_rounded,
                color: AppTheme.successColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Hasil Deteksi YOLOv12',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(
            'Waktu deteksi: $date',
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
        const SizedBox(height: 14),

        // ── Hama & Kematangan Cards ────────────────────────────
        Row(
          children: [
            // Hama Card
            Expanded(
              child: _buildDetectionCard(
                isDark: isDark,
                icon: Icons.bug_report_rounded,
                iconColor: hamaName != null
                    ? AppTheme.accentWarning
                    : AppTheme.successColor,
                label: 'Hama Terdeteksi',
                value: hamaName ?? 'Padi Sehat',
                confidence: hamaName != null ? hamaConf.toDouble() : null,
                bgColor: isDark
                    ? const Color(0xFF1E293B)
                    : (hamaName != null
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE8F5E9)),
                borderColor: hamaName != null
                    ? AppTheme.accentWarning.withOpacity(0.4)
                    : AppTheme.successColor.withOpacity(0.3),
                valueColor: hamaName != null
                    ? AppTheme.accentWarning
                    : AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            // Kematangan Card
            Expanded(
              child: _buildDetectionCard(
                isDark: isDark,
                icon: Icons.eco_rounded,
                iconColor: AppTheme.successColor,
                label: 'Kematangan Padi',
                value: kematangan,
                confidence: kematanganConf.toDouble(),
                bgColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE8F5E9),
                borderColor: AppTheme.successColor.withOpacity(0.3),
                valueColor: AppTheme.successColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Danger Level Badge ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _getDangerColor(dangerLevel).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getDangerIcon(dangerLevel),
                color: _getDangerColor(dangerLevel),
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tingkat Ancaman',
                      style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    dangerLevel,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _getDangerColor(dangerLevel),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDangerColor(dangerLevel).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dangerLevel == 'Aman'
                      ? 'Tidak ada hama'
                      : 'Perlu penanganan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getDangerColor(dangerLevel),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Description ─────────────────────────────────────────
        _buildSectionCard(
          isDark: isDark,
          icon: Icons.description_outlined,
          title: 'Deskripsi Hasil Analisis',
          content: description,
        ),

        const SizedBox(height: 14),

        // ── Treatment ────────────────────────────────────────────
        _buildSectionCard(
          isDark: isDark,
          icon: Icons.medical_services_outlined,
          title: 'Rekomendasi Penanganan',
          content: treatment,
          accentColor: AppTheme.successColor,
        ),

        const SizedBox(height: 32),

        // ── Bottom Action Buttons ───────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Scan Ulang'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Deteksi berhasil disimpan ke riwayat.'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/petani/history');
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ke Riwayat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF1B5E20),
                  foregroundColor:
                      isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── Detection Info Card (Hama / Kematangan) ─────────────────────────────
  Widget _buildDetectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    double? confidence,
    required Color bgColor,
    required Color borderColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(height: 6),
            // Confidence progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(valueColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Akurasi: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Section Info Card (Description / Treatment) ──────────────────────────
  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
    Color accentColor = AppTheme.textLightMuted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            height: 1,
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.65,
              color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
            ),
          ),
        ],
      ),
    );
  }
}
