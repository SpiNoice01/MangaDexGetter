import 'package:flutter/material.dart';
import 'dart:ui';

class GlassBadge extends StatelessWidget {
  final String label;

  const GlassBadge({super.key, required this.label});

  bool get _isNsfw {
    final lower = label.toLowerCase();
    return ['ecchi', 'suggestive', 'erotica', 'pornographic', 'smut', 'hentai', 'sexual violence', 'gore'].contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _isNsfw ? Colors.redAccent : Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isNsfw ? baseColor.withValues(alpha: 0.15) : baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isNsfw ? baseColor.withValues(alpha: 0.6) : baseColor.withValues(alpha: 0.2),
              width: _isNsfw ? 1.0 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _isNsfw ? const Color.fromARGB(255, 255, 185, 185) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
