// Implementasi kamera web via getUserMedia API (desktop & mobile browser)
// Menampilkan dialog dengan preview live kamera, lalu capture ke bytes.
//
// CATATAN: navigator.mediaDevices hanya tersedia di konteks AMAN (HTTPS atau localhost).
// Jika diakses via HTTP (misal: 192.168.x.x:port), API ini akan null di browser HP.
// Dalam kasus itu, captureFromWebCamera() mengembalikan null agar
// detection_page.dart bisa fallback ke ImagePicker native (input type=file).

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cek apakah MediaDevices API tersedia (memerlukan HTTPS atau localhost)
bool isMediaDevicesAvailable() {
  return html.window.navigator.mediaDevices != null;
}

/// Membuka file picker galeri (fallback)
Future<XFile?> openWebCameraInput() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  final bytes = reader.result as Uint8List;
  return XFile.fromData(bytes, name: file.name, mimeType: file.type);
}

/// Membuka file picker dengan capture kamera (fallback untuk HTTP di mobile).
/// Menggunakan input[type=file][capture=environment] agar browser HP buka kamera langsung.
///
/// Foto dari kamera HP bisa sangat besar (10-20MP). Image.memory di Flutter Web
/// tidak bisa render gambar besar → preview kosong. Fix: resize ke max 1024px
/// via Canvas sebelum disimpan, sama seperti _capturePhoto di dialog kamera desktop.
Future<Uint8List?> captureFromNativeCamera() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'environment')
    ..style.display = 'none';

  // Tambahkan ke DOM — dibutuhkan oleh beberapa browser HP agar onChange terpicu
  html.document.body?.children.add(input);

  try {
    input.click();
    await input.onChange.first;

    final file = input.files?.first;
    if (file == null) return null;

    // Baca sebagai DataURL
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final dataUrl = reader.result as String;

    // Muat ke ImageElement untuk mendapatkan dimensi asli
    final img = html.ImageElement(src: dataUrl);
    await img.onLoad.first;

    // Resize ke maks 1024px agar Image.memory Flutter Web bisa render
    // (foto kamera HP bisa 10-20MP → terlalu besar untuk CanvasKit)
    const int maxDim = 1024;
    int w = img.naturalWidth > 0 ? img.naturalWidth : 640;
    int h = img.naturalHeight > 0 ? img.naturalHeight : 480;

    if (w > maxDim || h > maxDim) {
      if (w >= h) {
        h = (h * maxDim ~/ w);
        w = maxDim;
      } else {
        w = (w * maxDim ~/ h);
        h = maxDim;
      }
    }

    // Gambar ke canvas lalu re-encode sebagai JPEG (sama dengan _capturePhoto desktop)
    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImageScaled(img, 0, 0, w, h);
    final resizedDataUrl = canvas.toDataUrl('image/jpeg', 0.88);

    final base64Data = resizedDataUrl.split(',').last;
    return base64Decode(base64Data);
  } catch (e) {
    return null;
  } finally {
    // Selalu hapus elemen dari DOM setelah selesai
    input.remove();
  }
}


/// Membuka dialog kamera menggunakan getUserMedia API.
/// Jika MediaDevices tidak tersedia (akses HTTP di mobile browser),
/// mengembalikan null agar pemanggil bisa fallback ke native camera picker.
Future<Uint8List?> captureFromWebCamera(BuildContext context) async {
  // Jika tidak di HTTPS / localhost, mediaDevices tidak tersedia di browser HP
  if (!isMediaDevicesAvailable()) {
    // Langsung pakai native camera input (input[capture=environment])
    // agar HP bisa buka kamera tanpa perlu HTTPS
    return await captureFromNativeCamera();
  }

  return await showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _WebCameraDialog(),
  );
}

// Counter statis untuk membuat ID unik setiap dialog kamera baru
int _cameraViewCounter = 0;

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog();

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  bool _isReady = false;
  bool _hasError = false;
  bool _isWaitingPermission = true; // true saat menunggu izin browser
  String _errorMsg = '';
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _cameraViewCounter++;
    _viewId = 'webcam-view-$_cameraViewCounter';
    _startCamera();
    // Timeout 30 detik — jika kamera belum siap, tampilkan pesan
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && !_isReady && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMsg =
              'Waktu habis menunggu izin kamera.\n\nPastikan Anda mengklik "Izinkan" pada popup izin kamera di browser, lalu tekan "Coba Lagi".';
        });
      }
    });
  }

  Future<void> _startCamera() async {
    try {
      if (html.window.navigator.mediaDevices == null) {
        throw Exception('MediaDevices API tidak tersedia.');
      }

      // Tampilkan status: menunggu izin
      if (mounted) setState(() => _isWaitingPermission = true);

      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      // Izin diberikan, mulai streaming
      if (mounted) setState(() => _isWaitingPermission = false);

      _stream = stream;
      final video = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '12px'
        ..style.display = 'block';

      _videoElement = video;

      // Daftarkan view factory agar HtmlElementView bisa merender video element
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => video,
      );

      // Langsung set isReady=true agar HtmlElementView dirender ke DOM.
      // Video akan autoplay setelah elemen masuk ke DOM (karena autoplay=true).
      // Jangan await onLoadedMetadata di sini — video belum di-DOM, jadi tidak akan fire!
      if (mounted) {
        setState(() => _isReady = true);
      }

      // Play dilakukan setelah satu frame render selesai
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        await video.play();
      } catch (_) {
        // autoplay mungkin sudah berjalan, abaikan error
      }
    } catch (e) {
      if (mounted) {
        String msg;
        final errStr = e.toString();
        if (errStr.contains('NotAllowedError') || errStr.contains('Permission')) {
          msg = 'Izin kamera ditolak.\n\nKlik ikon kunci/kamera di address bar browser lalu izinkan akses kamera, kemudian coba lagi.';
        } else if (errStr.contains('NotFoundError') || errStr.contains('DevicesNotFound')) {
          msg = 'Kamera tidak ditemukan.\n\nPastikan kamera terhubung dan driver terinstal.';
        } else if (errStr.contains('NotReadableError')) {
          msg = 'Kamera sedang digunakan aplikasi lain.\n\nTutup aplikasi lain yang menggunakan kamera.';
        } else if (errStr.contains('MediaDevices') || errStr.contains('mediaDevices')) {
          msg = 'Akses kamera memerlukan koneksi HTTPS.\n\nBuka aplikasi melalui HTTPS, atau gunakan fitur "Ambil Foto" dari galeri HP.';
        } else {
          msg = 'Gagal membuka kamera.\n\n$errStr';
        }
        setState(() {
          _hasError = true;
          _errorMsg = msg;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    final video = _videoElement;
    if (video == null) return;

    final w = video.videoWidth > 0 ? video.videoWidth : 640;
    final h = video.videoHeight > 0 ? video.videoHeight : 480;

    final canvas = html.CanvasElement(width: w, height: h);
    final ctx = canvas.context2D;
    ctx.drawImage(video, 0, 0);

    // Konversi canvas ke JPEG base64 lalu ke bytes
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
    final base64 = dataUrl.split(',').last;
    final bytes = _base64ToBytes(base64);

    _stopCamera();
    if (mounted) {
      Navigator.of(context).pop(bytes);
    }
  }

  Uint8List _base64ToBytes(String base64) {
    final binary = html.window.atob(base64);
    final bytes = Uint8List(binary.length);
    for (int i = 0; i < binary.length; i++) {
      bytes[i] = binary.codeUnitAt(i);
    }
    return bytes;
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((t) => t.stop());
    _videoElement?.srcObject = null;
    _stream = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 640, maxWidth: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Color(0xFF4CAF50), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Kamera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      _stopCamera();
                      Navigator.of(context).pop(null);
                    },
                  ),
                ],
              ),
            ),

            // ── Video Preview ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1E293B),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.videocam_off,
                                  color: Colors.redAccent, size: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMsg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _isReady = false;
                                  _errorMsg = '';
                                });
                                _startCamera();
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _isReady
                      ? HtmlElementView(viewType: _viewId)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Color(0xFF4CAF50), strokeWidth: 3),
                                const SizedBox(height: 20),
                                const Text(
                                  'Menghubungkan ke kamera...',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                if (_isWaitingPermission) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF4CAF50).withOpacity(0.4)),
                                    ),
                                    child: const Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Color(0xFF4CAF50), size: 18),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Izin kamera dibutuhkan',
                                                style: TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Cari popup izin di bagian atas browser (dekat address bar) dan klik "Izinkan" atau "Allow".',
                                          style: TextStyle(
                                              color: Colors.white70, fontSize: 12, height: 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_upward,
                                          color: Colors.white38, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Lihat di bagian atas browser',
                                        style: TextStyle(
                                            color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
            ),

            // ── Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _stopCamera();
                      Navigator.of(context).pop(null);
                    },
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white54, size: 18),
                    label: const Text('Batal',
                        style: TextStyle(color: Colors.white54)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isReady ? _capturePhoto : null,
                      icon: const Icon(Icons.camera, size: 22),
                      label: const Text(
                        'Ambil Foto',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        disabledBackgroundColor:
                            Colors.grey.shade800.withOpacity(0.5),
                        disabledForegroundColor: Colors.white30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
