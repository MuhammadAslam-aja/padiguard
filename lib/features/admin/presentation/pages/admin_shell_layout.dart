import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../auth/presentation/auth_provider.dart';

class AdminShellLayout extends ConsumerWidget {
  final Widget child;

  const AdminShellLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/detections')) return 2;
    if (location.startsWith('/admin/dataset')) return 3;
    if (location.startsWith('/admin/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        context.go('/admin/detections');
        break;
      case 3:
        context.go('/admin/dataset');
        break;
      case 4:
        context.go('/admin/profile');
        break;
    }
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PendingNotification?>(pendingNotificationProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = rootNavigatorKey.currentContext ?? context;
          AppNotification.show(
            ctx,
            title: next.title,
            message: next.message,
            type: next.type,
          );
          ref.read(pendingNotificationProvider.notifier).state = null;
        });
      }
    });

    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 800;

    // Premium royal purple/indigo theme for Admin (High-tech control center)
    final Color adminPrimaryColor = isDark ? const Color(0xFF9066F5) : const Color(0xFF6366F1);
    final Color adminSecondaryColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF4F46E5);
    final ThemeData adminTheme = Theme.of(context).copyWith(
      primaryColor: adminPrimaryColor,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: adminPrimaryColor,
        secondary: adminSecondaryColor,
      ),
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.textDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        elevation: 6,
        shadowColor: adminPrimaryColor.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: adminPrimaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: adminPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: adminPrimaryColor.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: adminPrimaryColor,
          side: BorderSide(color: adminPrimaryColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: adminPrimaryColor,
        ),
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: adminPrimaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: adminPrimaryColor),
      ),
    );

    Widget content;

    if (isDesktop) {
      content = Scaffold(
        body: Row(
          children: [
            // Left Sidebar - Sleek slate theme
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E1726) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // App Title / Brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, color: adminPrimaryColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'PadiGuard Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 16),
                  
                  // Menu Items
                  _buildSidebarItem(context, 0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', selectedIndex, adminPrimaryColor),
                  _buildSidebarItem(context, 1, Icons.people_outline, Icons.people, 'Kelola User', selectedIndex, adminPrimaryColor),
                  _buildSidebarItem(context, 2, Icons.list_alt_outlined, Icons.list_alt, 'Kelola Deteksi', selectedIndex, adminPrimaryColor),
                  _buildSidebarItem(context, 3, Icons.model_training_outlined, Icons.model_training, 'Dataset & Model', selectedIndex, adminPrimaryColor),
                  _buildSidebarItem(context, 4, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Admin Profil', selectedIndex, adminPrimaryColor),
                  
                  const Spacer(),
                  // Logout sidebar item
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      onTap: () => _showLogoutConfirmation(context, ref),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                      title: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 8),
                  // Footer info
                  Text(
                    'PadiGuard Administrator',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Main page expanded
            Expanded(child: child),
          ],
        ),
      );
    } else {
      content = Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF0E1726) : const Color(0xFFF8FAFC),
            selectedItemColor: adminPrimaryColor,
            unselectedItemColor: isDark ? const Color(0xFF475569) : Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Kelola User',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Deteksi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.model_training_outlined),
                activeIcon: Icon(Icons.model_training),
                label: 'Dataset',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: adminTheme,
      child: content,
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int selectedIndex,
    Color activeColor,
  ) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        onTap: () => _onItemTapped(index, context),
        selected: isSelected,
        selectedTileColor: activeColor.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected
              ? activeColor
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white70 : AppTheme.textDark),
          ),
        ),
      ),
    );
  }
}
