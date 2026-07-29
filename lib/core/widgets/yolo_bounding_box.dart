import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class YoloBoundingBox extends StatelessWidget {
  final String imageUrl;
  final Uint8List? imageBytes;
  final List<dynamic> boundingBoxes;

  const YoloBoundingBox({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    required this.boundingBoxes,
  });

  @override
  Widget build(BuildContext context) {
    // imageBytes (dari kamera HP) selalu diprioritaskan.
    // imageUrl dipakai hanya jika imageBytes null/kosong.
    final bool hasBytes = imageBytes != null && imageBytes!.isNotEmpty;
    final bool isNetwork = !hasBytes &&
        (kIsWeb ||
            imageUrl.startsWith('http://') ||
            imageUrl.startsWith('https://') ||
            imageUrl.startsWith('blob:'));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerWidth = constraints.maxWidth;
        final double containerHeight = constraints.maxHeight.isInfinite ? 300 : constraints.maxHeight;

        Widget imageWidget;
        if (hasBytes) {
          // Gambar dari kamera HP (bytes in-memory) — paling prioritas
          imageWidget = Image.memory(
            imageBytes!,
            width: containerWidth,
            height: containerHeight,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _buildErrorContainer(containerWidth, containerHeight),
          );
        } else if (isNetwork) {
          imageWidget = Image.network(
            imageUrl,
            width: containerWidth,
            height: containerHeight,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) => _buildErrorContainer(containerWidth, containerHeight),
          );
        } else if (imageUrl.isNotEmpty) {
          imageWidget = Image.file(
            File(imageUrl),
            width: containerWidth,
            height: containerHeight,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) => _buildErrorContainer(containerWidth, containerHeight),
          );
        } else {
          // Tidak ada gambar sama sekali
          imageWidget = _buildErrorContainer(containerWidth, containerHeight);
        }

        return Stack(
          children: [
            // Image Base
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageWidget,
            ),
            
            // Bounding Box Overlays
            ...boundingBoxes.map((box) {
              final double xMin = (box['xMin'] as num).toDouble();
              final double yMin = (box['yMin'] as num).toDouble();
              final double xMax = (box['xMax'] as num).toDouble();
              final double yMax = (box['yMax'] as num).toDouble();
              final String label = box['label'] ?? '';
              final bool isHama = box['isHama'] ?? false;

              // Calculate positions
              final double left = xMin * containerWidth;
              final double top = yMin * containerHeight;
              final double width = (xMax - xMin) * containerWidth;
              final double height = (yMax - yMin) * containerHeight;

              // Box and Label Colors
              final Color boxColor = isHama ? AppTheme.accentWarning : AppTheme.successColor;

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: boxColor, width: 2.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Tag Label
                      Positioned(
                        top: -24,
                        left: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildErrorContainer(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade800,
      child: const Icon(Icons.broken_image, color: Colors.white24, size: 50),
    );
  }
}
