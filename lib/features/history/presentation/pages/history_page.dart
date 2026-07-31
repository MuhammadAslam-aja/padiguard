import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../services/api_mock_data.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../widgets/detection_detail_sheet.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final ApiMockData _mockDb = ApiMockData();
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = false;
  String _selectedFilter = 'Semua'; // 'Semua', 'Hama', 'Kematangan'
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  String _formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image')) {
      return url;
    }
    final apiBase = AppConstants.baseUrl;
    final origin = apiBase.replaceAll(RegExp(r'api/?$'), '');
    if (url.startsWith('/')) {
      return '$origin${url.substring(1)}';
    }
    if (url.startsWith('uploads/')) {
      final filename = url.substring('uploads/'.length);
      return '${apiBase}image?file=$filename';
    }
    return '$origin$url';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (AppConstants.useMockApi) {
      if (mounted) {
        final authState = ref.read(authProvider);
        final emailFilter = authState.user?.role == 'admin' ? null : authState.user?.email;
        setState(() {
          _historyList = _mockDb.getDetectionHistory(emailFilter);
        });
      }
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('api/detection/history');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _historyList = List<Map<String, dynamic>>.from(response.data['history']);
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteHistoryItem(String id) async {
    if (AppConstants.useMockApi) {
      _mockDb.deleteDetection(id);
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

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _searchController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _searchController.clear();
    });
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Data Deteksi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin menghapus data deteksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allHistory = _historyList;

    // Apply Filter (Semua, Hama, Kematangan)
    var filteredList = allHistory.where((item) {
      if (_selectedFilter == 'Hama') {
        return item['hamaName'] != null;
      }
      if (_selectedFilter == 'Kematangan') {
        return item['hamaName'] == null;
      }
      return true;
    }).toList();

    // Apply Date Filter
    if (_selectedDate != null) {
      filteredList = filteredList.where((item) {
        final itemDate = DateTime.parse(item['date']);
        return itemDate.year == _selectedDate!.year &&
            itemDate.month == _selectedDate!.month &&
            itemDate.day == _selectedDate!.day;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Deteksi Padi'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // Search by Date field
            TextField(
              controller: _searchController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan tanggal...',
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                suffixIcon: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearDateFilter,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),

            // Segmented Filters (All, Hama, Kematangan)
            Row(
              children: [
                _buildFilterButton('Semua'),
                const SizedBox(width: 8),
                _buildFilterButton('Hama'),
                const SizedBox(width: 8),
                _buildFilterButton('Kematangan'),
              ],
            ),
            
            const SizedBox(height: 20),

            // History ListView
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada riwayat ditemukan',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final date = DateTime.parse(item['date']);
                            final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(date);
                            final isHama = item['hamaName'] != null;
                            final hamaLabel = item['hamaName'] ?? 'Sehat';

                            return Dismissible(
                              key: Key('history_item_${item['id']}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) => _confirmDelete(context),
                              onDismissed: (direction) {
                                _deleteHistoryItem(item['id']);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 14),
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
                                tag: 'det_img_${item['id']}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _formatImageUrl(item['imageUrl']),
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 54,
                                      height: 54,
                                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
                                      child: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                isHama ? 'Hama: $hamaLabel' : 'Tanaman Padi Sehat',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kematangan: ${item['kematangan']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isHama
                                      ? AppTheme.accentWarning.withOpacity(0.12)
                                      : AppTheme.successColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onFilterChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF4CAF50) : AppTheme.primaryLight)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : AppTheme.textDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
