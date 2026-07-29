import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/api_mock_data.dart';
import '../../../auth/presentation/auth_provider.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  final ApiMockData _mockDb = ApiMockData();
  Map<String, dynamic> _stats = {
    'totalDetections': 0,
    'totalUsers': 0,
    'mostCommonHama': '-',
    'dominantMaturity': '-',
    'hamaDistribution': <String, int>{},
    'maturityDistribution': <String, int>{},
    'weeklyDetections': <dynamic>[]
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
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

  Future<void> _loadStats() async {
    if (AppConstants.useMockApi) {
      if (mounted) {
        setState(() {
          _stats = _mockDb.getAdminDashboardStats();
        });
      }
      return;
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get('api/admin/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _stats = response.data['stats'];
          });
        }
      }
    } catch (_) {}
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar Akun Admin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun admin Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Keluar'),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Analitik'),
            Text(
              'by Tirza Marsena (6150101220009)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadStats();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Sistem',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary cards grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isDesktop ? 1.6 : 1.3,
                    children: [
                      _buildSummaryCard(
                        'Total Deteksi',
                        _stats['totalDetections'].toString(),
                        Icons.analytics,
                        AppTheme.successColor,
                        isDark,
                      ),
                      _buildSummaryCard(
                        'Total Petani',
                        _stats['totalUsers'].toString(),
                        Icons.people,
                        AppTheme.primaryLight,
                        isDark,
                      ),
                      _buildSummaryCard(
                        'Hama Dominan',
                        _stats['mostCommonHama'],
                        Icons.bug_report,
                        AppTheme.accentWarning,
                        isDark,
                      ),
                      _buildSummaryCard(
                        'Kematangan',
                        _stats['dominantMaturity'],
                        Icons.grain,
                        Colors.teal,
                        isDark,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),

                  // Weekly Bar Chart
                  Text(
                    'Deteksi Minggu Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                    ),
                    child: _buildBarChart(_stats['weeklyDetections'], isDark),
                  ),

                  const SizedBox(height: 28),

                  // Distributions Pie Charts
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPestSection(isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMaturitySection(isDark)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildPestSection(isDark),
                            const SizedBox(height: 20),
                            _buildMaturitySection(isDark),
                          ],
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String val, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textDarkMuted : AppTheme.textLightMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPestSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Hama',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          child: _buildPestPieChart(_stats['hamaDistribution']),
        ),
      ],
    );
  }

  Widget _buildMaturitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kematangan Padi',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          child: _buildMaturityPieChart(_stats['maturityDistribution']),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> weeklyData, bool isDark) {
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < weeklyData.length; i++) {
      final item = weeklyData[i];
      final count = (item['count'] as num).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: AppTheme.successColor,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= weeklyData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    weeklyData[index]['day'],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPestPieChart(Map<dynamic, dynamic>? rawData) {
    final Map<String, int> data = {};
    if (rawData != null) {
      rawData.forEach((k, v) {
        data[k.toString()] = (v as num).toInt();
      });
    }
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)));
    }

    final colors = [
      AppTheme.accentWarning,
      Colors.redAccent,
      Colors.amber,
      Colors.deepOrange,
      Colors.orange,
    ];

    int colorIdx = 0;
    final List<PieChartSectionData> sections = [];
    data.forEach((k, v) {
      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          title: '$v',
          color: colors[colorIdx % colors.length],
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
      colorIdx++;
    });

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 20,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: data.keys.map((k) {
            final idx = data.keys.toList().indexOf(k);
            final col = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: col),
                const SizedBox(width: 4),
                Text(k, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMaturityPieChart(Map<dynamic, dynamic>? rawData) {
    final Map<String, int> data = {};
    if (rawData != null) {
      rawData.forEach((k, v) {
        data[k.toString()] = (v as num).toInt();
      });
    }
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)));
    }

    final colors = {
      'Mentah': Colors.green.shade700,
      'Setengah Matang': Colors.lightGreen,
      'Matang': Colors.amber,
    };

    final List<PieChartSectionData> sections = [];
    data.forEach((k, v) {
      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          title: '$v',
          color: colors[k] ?? Colors.grey,
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    });

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 20,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: data.keys.map((k) {
            final col = colors[k] ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: col),
                const SizedBox(width: 4),
                Text(k, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
