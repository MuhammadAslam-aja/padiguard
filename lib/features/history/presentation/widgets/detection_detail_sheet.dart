import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/yolo_bounding_box.dart';

class DetectionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> detection;
  final Function(String id) onDelete;

  const DetectionDetailSheet({
    super.key,
    required this.detection,
    required this.onDelete,
  });

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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Data Deteksi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus data deteksi ini dari riwayat? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete(detection['id']);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Riwayat deteksi berhasil dihapus.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(detection['date']);
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(date);
    final isHama = detection['hamaName'] != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Hasil Deteksi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Info (User & Date)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengirim: ${detection['userName']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            detection['userEmail'],
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Frame with YOLO bounding box overlay
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: YoloBoundingBox(
                      imageUrl: detection['imageUrl'],
                      boundingBoxes: detection['boundingBoxes'] ?? [],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Statistics Cards (Hama & Kematangan)
                  Row(
                    children: [
                      // Pest Class Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHama ? AppTheme.accentWarning.withOpacity(0.3) : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Klasifikasi Hama',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isHama ? detection['hamaName'] : 'Padi Sehat',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isHama ? AppTheme.accentWarning : AppTheme.successColor,
                                ),
                              ),
                              if (isHama) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Akurasi: ${(detection['hamaConfidence'] * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Maturity Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kematangan Tanaman',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detection['kematangan'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Akurasi: ${(detection['kematanganConfidence'] * 100).toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Danger level indicator
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
                          color: _getDangerColor(detection['dangerLevel']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getDangerColor(detection['dangerLevel']),
                          ),
                        ),
                        child: Text(
                          detection['dangerLevel'],
                          style: TextStyle(
                            color: _getDangerColor(detection['dangerLevel']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Detail description
                  Text(
                    'Deskripsi Kondisi Tanaman',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detection['description'] ?? 'Deskripsi tanaman tidak tersedia.',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Treatment Recommendation
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
                      detection['treatment'] ?? 'Tidak ada rekomendasi khusus.',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
