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

class DetectionPage extends ConsumerStatefulWidget {
  const DetectionPage({super.key});

  @override
  ConsumerState<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends ConsumerState<DetectionPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  Uint8List? _webImageBytes; // bytes untuk preview web
  bool _isAnalyzing = false;
  Map<String, dynamic>? _detectionResult;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = kIsWeb
          ? await _picker.pickImage(source: source)
          : await _picker.pickImage(
              source: source,
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
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengakses media: ${e.toString()}';
      });
    }
  }

  /// Membuka dialog kamera web / browser secara live.
  /// - Di laptop (HTTPS/localhost): menampilkan dialog kamera getUserMedia
  /// - Di HP via HTTP: langsung membuka kamera native HP via input[capture=environment]
  /// - Jika dibatalkan (bytes == null): tidak melakukan apa-apa
  Future<void> _openWebCamera() async {
    try {
      final Uint8List? bytes = await captureFromWebCamera(context);
      if (bytes != null && bytes.isNotEmpty) {
        final name = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = XFile.fromData(bytes, name: name, mimeType: 'image/jpeg');
        setState(() {
          _pickedFile = file;
          _webImageBytes = bytes;
          _detectionResult = null;
          _errorMessage = null;
        });
      }
      // Jika null (user batal / tidak memilih foto), tidak lakukan apa-apa
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuka kamera: ${e.toString()}';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    final dioClient = ref.read(dioClientProvider);

    try {
      final Uint8List imageBytes = _webImageBytes ?? await _pickedFile!.readAsBytes();
      final MultipartFile file;
      if (kIsWeb) {
        file = MultipartFile.fromBytes(imageBytes, filename: _pickedFile!.name);
      } else {
        file = await MultipartFile.fromFile(_pickedFile!.path, filename: _pickedFile!.name);
      }

      final response = await dioClient.dio.post(
        'api/detection',
        data: FormData.fromMap({
          'image': file,
        }),
      );

      dynamic resData = response.data;
      if (resData is String) {
        try {
          resData = jsonDecode(resData);
        } catch (_) {}
      }

      if ((response.statusCode == 200 || response.statusCode == 201) && resData is Map && resData['success'] == true) {
        Map<String, dynamic> detection = Map<String, dynamic>.from(resData['detection']);
        // Jika ada _webImageBytes (dari kamera HP), imageUrl tidak dipakai karena
        // XFile.fromData tidak punya path file yang valid. Set kosong agar
        // YoloBoundingBox otomatis pakai imageBytes (Image.memory).
        detection['imageUrl'] = (_webImageBytes != null) ? '' : _pickedFile!.path;

        setState(() {
          _detectionResult = detection;
          _isAnalyzing = false;
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
        setState(() {
          _errorMessage = serverMsg;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
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
            errMsg = 'Respon Server (${e.response!.statusCode}): Gagal memproses gambar.';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.sendTimeout ||
                   e.type == DioExceptionType.receiveTimeout ||
                   e.type == DioExceptionType.connectionError) {
          errMsg = 'Koneksi gagal: Tidak dapat menghubungi server backend.';
        }
      }
      setState(() {
        _errorMessage = errMsg;
        _isAnalyzing = false;
      });
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deteksi YOLOv12'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
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
                'Ambil foto bulir padi secara dekat atau pilih dari galeri untuk mendeteksi hama dan kematangan.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                ),
              ),
              const SizedBox(height: 28),
            ],

            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                height: 320,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isAnalyzing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SpinKitWaveSpinner(
                            color: AppTheme.successColor,
                            size: 70,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Mengunggah gambar ke server...',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          Text(
                            'Menganalisis dengan YOLOv12...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      )
                    : _detectionResult != null
                        // YOLO bounding box rendering
                        ? YoloBoundingBox(
                            imageUrl: _detectionResult!['imageUrl'],
                            imageBytes: _webImageBytes,
                            boundingBoxes: _detectionResult!['boundingBoxes'] ?? [],
                          )
                        : _pickedFile != null
                            // Selected file preview
                            ? (_webImageBytes != null
                                ? Image.memory(
                                    _webImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    gaplessPlayback: true,
                                  )
                                : (kIsWeb
                                    ? Image.network(
                                        _pickedFile!.path,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.file(
                                        File(_pickedFile!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )))
                            // Empty State selector
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada foto yang dipilih',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
              ),
            )),
            
            const SizedBox(height: 28),

            // ERROR MESSAGE
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // CASE 1: No file selected
            if (_pickedFile == null && !_isAnalyzing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (kIsWeb) {
                          _openWebCamera();
                        } else {
                          _pickImage(ImageSource.camera);
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // CASE 2: Image picked, waiting for analysis
            if (_pickedFile != null && _detectionResult == null && !_isAnalyzing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analyzeImage,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Mulai Analisis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // CASE 3: Result loaded
            if (_detectionResult != null && !_isAnalyzing) ...[
              // Bounding box legend
              Text(
                'Hasil Deteksi YOLOv12',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  // Hama Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _detectionResult!['hamaName'] != null
                              ? AppTheme.accentWarning.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hama Terdeteksi', style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            _detectionResult!['hamaName'] ?? 'Padi Sehat',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _detectionResult!['hamaName'] != null
                                  ? AppTheme.accentWarning
                                  : AppTheme.successColor,
                            ),
                          ),
                          if (_detectionResult!['hamaName'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Akurasi: ${(_detectionResult!['hamaConfidence'] * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kematangan Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kematangan Padi', style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            _detectionResult!['kematangan'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Akurasi: ${(_detectionResult!['kematanganConfidence'] * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text(
                    'Tingkat Ancaman:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDangerColor(_detectionResult!['dangerLevel']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getDangerColor(_detectionResult!['dangerLevel']),
                      ),
                    ),
                    child: Text(
                      _detectionResult!['dangerLevel'],
                      style: TextStyle(
                        color: _getDangerColor(_detectionResult!['dangerLevel']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Deskripsi Hasil Analisis',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _detectionResult!['description'] ?? '',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              
              const SizedBox(height: 20),

              Text(
                'Rekomendasi Penanganan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Text(
                  _detectionResult!['treatment'] ?? '',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Ulang'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Deteksi berhasil disimpan ke riwayat.'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.go('/petani/history');
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Ke Riwayat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
