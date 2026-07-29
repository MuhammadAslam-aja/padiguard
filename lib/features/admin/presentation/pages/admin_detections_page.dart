import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../services/api_mock_data.dart';
import '../../../history/presentation/widgets/detection_detail_sheet.dart';

class AdminDetectionsPage extends ConsumerStatefulWidget {
  const AdminDetectionsPage({super.key});

  @override
  ConsumerState<AdminDetectionsPage> createState() => _AdminDetectionsPageState();
}

class _AdminDetectionsPageState extends ConsumerState<AdminDetectionsPage> {
  final ApiMockData _mockDb = ApiMockData();
  List<Map<String, dynamic>> _detectionsList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _pestFilter = 'Semua'; // 'Semua', 'Wereng Coklat', 'Walang Sangit', 'Penggerek Batang', 'Ulat Grayak', 'Sehat'
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    if (AppConstants.useMockApi) {
      if (mounted) {
        setState(() {
          _detectionsList = _mockDb.getDetectionHistory(null);
        });
      }
      return;
    }

    if (mounted) {
      setState(() { _isLoading = true; });
    }
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('api/admin/detections');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _detectionsList = List<Map<String, dynamic>>.from(response.data['detections']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin detections: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _deleteDetection(String id) async {
    if (AppConstants.useMockApi) {
      _mockDb.deleteDetection(id);
      _loadDetections();
      return;
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.delete('api/detection/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _loadDetections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data deteksi berhasil dihapus.'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal menghapus data deteksi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
      _pestFilter = 'Semua';
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final allDetections = _detectionsList;

    // Apply filters
    final filteredList = allDetections.where((det) {
      // 1. Search Query
      final userName = det['userName']?.toString() ?? '';
      final userEmail = det['userEmail']?.toString() ?? '';
      final matchesSearch = _searchQuery.isEmpty ||
          userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          userEmail.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // 2. Date Filter
      bool matchesDate = true;
      if (_selectedDate != null && det['date'] != null) {
        try {
          final detDate = DateTime.parse(det['date'].toString());
          matchesDate = detDate.year == _selectedDate!.year &&
              detDate.month == _selectedDate!.month &&
              detDate.day == _selectedDate!.day;
        } catch (_) {}
      }

      // 3. Pest Filter
      bool matchesPest = true;
      if (_pestFilter != 'Semua') {
        if (_pestFilter == 'Sehat') {
          matchesPest = det['hamaName'] == null;
        } else {
          matchesPest = det['hamaName'] == _pestFilter;
        }
      }

      return matchesSearch && matchesDate && matchesPest;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Semua Data Deteksi'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          if (_selectedDate != null || _pestFilter != 'Semua' || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: AppTheme.errorColor),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan nama/email petani...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Date & Pest Filter Row
            Row(
              children: [
                // Date picker trigger
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(
                      hintText: 'Pilih Tanggal',
                      prefixIcon: Icon(Icons.calendar_today, size: 16),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Pest filter dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pestFilter,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua Hama', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Wereng Coklat', child: Text('Wereng Coklat', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Walang Sangit', child: Text('Walang Sangit', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Penggerek Batang', child: Text('Penggerek Batang', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Ulat Grayak', child: Text('Ulat Grayak', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Sehat', child: Text('Sehat (Aman)', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _pestFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // List view
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('Data deteksi tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final date = DateTime.parse(item['date']);
                            final formattedDate = DateFormat('dd MMM, HH:mm').format(date);
                            final isHama = item['hamaName'] != null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                        _deleteDetection(id);
                                      },
                                    ),
                                  );
                                },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              isHama ? 'Hama: ${item['hamaName']}' : 'Tanaman Sehat',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Petani: ${item['userName']}', style: const TextStyle(fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(formattedDate, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isHama
                                    ? AppTheme.accentWarning.withOpacity(0.12)
                                    : AppTheme.successColor.withOpacity(0.12),
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
            ),
          ],
        ),
      ),
    );
  }
}
