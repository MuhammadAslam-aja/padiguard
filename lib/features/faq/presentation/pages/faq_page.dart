import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme.dart';

/// Model data untuk setiap item FAQ
class FaqItem {
  final IconData icon;
  final Color iconColor;
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.icon,
    required this.iconColor,
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// Daftar lengkap FAQ PadiGuard
const List<FaqItem> _allFaqItems = [
  FaqItem(
    icon: Icons.camera_alt_outlined,
    iconColor: Color(0xFF22C55E),
    question: 'Bagaimana cara mengambil foto tanaman padi?',
    answer:
        'Buka menu "Scan Padi" dari navigation bar bawah, lalu tekan tombol Kamera.\n\n'
        'Tips agar hasil deteksi akurat:\n'
        '• Pastikan pencahayaan cukup (sebaiknya di luar ruangan).\n'
        '• Fokuskan kamera pada bagian bulir padi atau area yang diduga terserang hama.\n'
        '• Hindari foto yang buram atau goyang.\n'
        '• Gunakan kamera belakang untuk kualitas terbaik.',
    category: 'Pengambilan Foto',
  ),
  FaqItem(
    icon: Icons.photo_library_outlined,
    iconColor: Color(0xFF3B82F6),
    question: 'Bagaimana cara memilih gambar dari galeri?',
    answer:
        'Dari halaman Scan Padi, tekan tombol "Galeri" untuk membuka galeri foto perangkat Anda.\n\n'
        'Pilih foto tanaman padi yang ingin dianalisis. Aplikasi mendukung format JPG dan PNG.\n\n'
        'Tips memilih gambar dari galeri:\n'
        '• Pilih gambar dengan resolusi minimal 480×480 piksel.\n'
        '• Pastikan gambar menampilkan bagian padi yang jelas (bulir, daun, atau batang).\n'
        '• Hindari gambar yang sangat gelap atau terlalu terang (overexposed).',
    category: 'Pengambilan Foto',
  ),
  FaqItem(
    icon: Icons.analytics_outlined,
    iconColor: Color(0xFF8B5CF6),
    question: 'Bagaimana cara melakukan proses deteksi?',
    answer:
        '1. Pilih atau ambil foto tanaman padi.\n'
        '2. Gambar akan tampil di area pratinjau.\n'
        '3. Tekan tombol "Mulai Analisis" berwarna hijau.\n'
        '4. Tunggu proses analisis selesai (biasanya 5–15 detik tergantung koneksi internet).\n'
        '5. Hasil deteksi berupa nama hama, tingkat kematangan, confidence score, dan rekomendasi penanganan akan ditampilkan.',
    category: 'Cara Penggunaan',
  ),
  FaqItem(
    icon: Icons.bug_report_outlined,
    iconColor: Color(0xFFF97316),
    question: 'Apa arti hasil deteksi hama?',
    answer:
        'Setelah analisis selesai, aplikasi akan menampilkan:\n\n'
        '🔴 Nama Hama: Jenis hama yang terdeteksi (Wereng Coklat atau Penggerek Batang).\n\n'
        '📊 Akurasi/Confidence: Tingkat keyakinan model (misal: 88%) – semakin tinggi semakin akurat.\n\n'
        '⚠️ Tingkat Ancaman:\n'
        '• Aman – Tidak ada hama terdeteksi\n'
        '• Sedang – Hama ada, perlu perhatian\n'
        '• Tinggi – Hama parah, perlu segera ditangani\n\n'
        '📍 Bounding Box: Kotak merah pada gambar menandai lokasi hama yang terdeteksi.\n\n'
        '💊 Rekomendasi: Saran penanganan spesifik sesuai jenis hama.',
    category: 'Memahami Hasil',
  ),
  FaqItem(
    icon: Icons.eco_outlined,
    iconColor: Color(0xFF10B981),
    question: 'Apa arti hasil klasifikasi kematangan padi?',
    answer:
        'Aplikasi mendeteksi tiga tahap kematangan padi:\n\n'
        '🟢 Mentah – Bulir masih berupa cairan, warna hijau, belum siap panen. Pastikan air dan nutrisi tercukupi.\n\n'
        '🟡 Setengah Matang – Bulir mulai mengeras dan menguning. Kurangi penggenangan air untuk mempercepat pematangan.\n\n'
        '🟠 Matang – Lebih dari 90% bulir telah menguning sempurna, siap panen dalam 1–2 minggu.\n\n'
        'Nilai Akurasi Kematangan menunjukkan seberapa yakin model terhadap klasifikasi tersebut.',
    category: 'Memahami Hasil',
  ),
  FaqItem(
    icon: Icons.warning_amber_outlined,
    iconColor: Color(0xFFEF4444),
    question: 'Mengapa gambar saya gagal diproses?',
    answer:
        'Ada beberapa kemungkinan penyebab gambar gagal diproses:\n\n'
        '🌿 Gambar bukan tanaman padi – Aplikasi hanya dapat menganalisis gambar tanaman padi. Gambar rumput, gulma, atau objek lain akan ditolak secara otomatis.\n\n'
        '📶 Koneksi internet lemah – Pastikan koneksi internet stabil saat melakukan analisis.\n\n'
        '💡 Kualitas gambar buruk – Foto terlalu gelap, buram, atau resolusi sangat rendah.\n\n'
        '🔄 Server sedang sibuk – Coba ulangi beberapa detik kemudian.\n\n'
        'Solusi: Pastikan foto menampilkan tanaman padi yang jelas dengan pencahayaan baik dan koneksi internet yang stabil.',
    category: 'Pemecahan Masalah',
  ),
  FaqItem(
    icon: Icons.wifi_outlined,
    iconColor: Color(0xFF64748B),
    question: 'Apakah aplikasi memerlukan koneksi internet?',
    answer:
        'Ya, aplikasi PadiGuard memerlukan koneksi internet aktif untuk:\n\n'
        '• Mengunggah gambar ke server untuk dianalisis oleh model YOLOv12\n'
        '• Menyimpan dan mengambil riwayat deteksi\n'
        '• Login dan autentikasi akun\n\n'
        'Tanpa koneksi internet, proses deteksi tidak dapat dilakukan. Pastikan perangkat terhubung ke WiFi atau data seluler yang stabil sebelum menggunakan fitur Scan Padi.\n\n'
        'Kecepatan rekomendasi: minimal 3G / 1 Mbps untuk pengalaman terbaik.',
    category: 'Teknis',
  ),
];

/// Halaman FAQ / Panduan Penggunaan PadiGuard
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  int? _expandedIndex;

  final List<String> _categories = [
    'Semua',
    'Pengambilan Foto',
    'Cara Penggunaan',
    'Memahami Hasil',
    'Pemecahan Masalah',
    'Teknis',
  ];

  List<FaqItem> get _filteredFaq {
    return _allFaqItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Semua' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredFaq;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Penggunaan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Bantuan & FAQ PadiGuard',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Column(
        children: [
          // ── Header Banner ──────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF166534), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ada yang bisa kami bantu?',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_allFaqItems.length} topik panduan tersedia',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _expandedIndex = null;
              }),
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _expandedIndex = null;
                          });
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.successColor,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
              ),
            ),
          ),

          // ── Category Filter Chips ──────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat;
                    _expandedIndex = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.successColor
                          : (isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.successColor
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.grey.shade700),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── FAQ List ───────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildFaqCard(context, filtered[index], index, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(
      BuildContext context, FaqItem item, int index, bool isDark) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppTheme.successColor.withOpacity(0.4)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(
                () => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                // Question row
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: item.iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      // Question text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: item.iconColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.question,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                // Answer (animated expand)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.answer,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.7,
                            color: isDark
                                ? AppTheme.textDarkMuted
                                : AppTheme.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil untuk\n"$_searchQuery"',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci yang berbeda',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
