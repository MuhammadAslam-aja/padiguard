import 'package:flutter/material.dart';

class AuthResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const AuthResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Toggle width constraints based on screen size (desktop/tablet vs mobile phone)
    if (width >= 600) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: child,
            ),
          ),
        ),
      );
    }

    // Default full screen view on mobile phones
    return child;
  }
}
