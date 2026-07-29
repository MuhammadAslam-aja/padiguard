import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/providers/core_providers.dart';

import '../../../../core/widgets/auth_responsive_wrapper.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Deteksi Hama Cepat',
      'subtitle': 'Identifikasi wereng coklat, walang sangit, penggerek batang, dan ulat grayak secara real-time dengan kamera smartphone Anda.',
      'imageUrl': 'https://images.unsplash.com/photo-1628352081506-83c43123ed6d?w=600',
      'isAsset': 'false',
    },
    {
      'title': 'Tingkat Kematangan Padi',
      'subtitle': 'Klasifikasikan kematangan padi (Mentah, Setengah Matang, atau Matang) secara instan menggunakan kecerdasan buatan YOLOv12.',
      'imageUrl': 'assets/images/slide2_rice_stalks.png',
      'isAsset': 'true',
    },
    {
      'title': 'Rekomendasi Ahli',
      'subtitle': 'Dapatkan saran penanganan hama terintegrasi dan petunjuk praktis pengelolaan panen untuk menjaga produktivitas sawah Anda.',
      'imageUrl': 'assets/images/slide3_sawah_field.png',
      'isAsset': 'true',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.keyIsFirstTime, false);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AuthResponsiveWrapper(
      child: Scaffold(
        body: Stack(
          children: [
          // Background Color / Pattern
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),
          
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'by Tirza Marsena (6150101220009)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
          
          // Slides PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Slide Image with Frame
                    Hero(
                      tag: 'slide_image_$index',
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: slide['isAsset'] == 'true'
                                ? AssetImage(slide['imageUrl']!) as ImageProvider
                                : NetworkImage(slide['imageUrl']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Slide Title
                    Text(
                      slide['title']!,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Slide Subtitle
                    Text(
                      slide['subtitle']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Navigation controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                
                // Indicators Dot
                Row(
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20))
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                // Next / Finish Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentIndex == _slides.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(_currentIndex == _slides.length - 1 ? 'Mulai' : 'Lanjut'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }
}
