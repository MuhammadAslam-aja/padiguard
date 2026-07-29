import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/auth_responsive_wrapper.dart';
import '../auth_provider.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Auth State to trigger redirects inside GoRouter.
    // Watch authState so it registers inside Riverpod.
    ref.watch(authProvider);

    return AuthResponsiveWrapper(
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20), // Deep Forest Green
              Color(0xFF0F172A), // Slate 900
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: 50,
                  color: Color(0xFF81C784),
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'PadiGuard',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              // Tagline
              Text(
                'Deteksi Hama & Kematangan Padi YOLOv12',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'by Tirza Marsena (6150101220009)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              // Loader
              const SpinKitRing(
                color: Color(0xFF81C784),
                size: 40,
                lineWidth: 3,
              ),
            ],
          ),
        ),
      ),
    ),);
  }
}
