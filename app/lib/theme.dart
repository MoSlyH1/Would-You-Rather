import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF12060A);
  static const bgTop = Color(0xFF3A0A17);
  static const crimson = Color(0xFFD7263D);
  static const optionA = Color(0xFFE63946); // red side
  static const optionB = Color(0xFF2A9D8F); // teal side
  static const card = Color(0xFF1E0C12);
  static const muted = Color(0xFFB98E98);

  static const categories = <String>[
    'All',
    'Football',
    'Lebanon',
    'Lebanese Politics',
    'Technology',
    'Food',
    'Community',
  ];

  static const categorySubmit = <String>[
    'Football',
    'Lebanon',
    'Lebanese Politics',
    'Technology',
    'Food',
    'Community',
  ];

  static Color categoryColor(String c) {
    switch (c) {
      case 'Football':
        return const Color(0xFF2A9D8F);
      case 'Lebanon':
        return const Color(0xFFE76F51);
      case 'Lebanese Politics':
        return const Color(0xFF9B5DE5);
      case 'Technology':
        return const Color(0xFF4895EF);
      case 'Food':
        return const Color(0xFFF4A261);
      default:
        return const Color(0xFFB5179E);
    }
  }

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: crimson,
        secondary: optionB,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static BoxDecoration get pageGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bg],
        ),
      );
}
