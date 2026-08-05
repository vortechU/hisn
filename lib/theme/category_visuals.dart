import 'package:flutter/material.dart';

/// Maps a category id to a presentational icon and accent colour.
///
/// Keeping this out of the JSON lets content stay purely textual while the UI
/// owns how each category looks.
class CategoryVisuals {
  const CategoryVisuals(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const Map<String, CategoryVisuals> _map = {
    'morning': CategoryVisuals(Icons.wb_sunny_outlined, Color(0xFFE0A12E)),
    'evening': CategoryVisuals(Icons.wb_twilight, Color(0xFF8E6BB0)),
    'after_salah': CategoryVisuals(Icons.mosque_outlined, Color(0xFF0E6B5C)),
    'sleep': CategoryVisuals(Icons.bedtime_outlined, Color(0xFF3F6CB0)),
    'waking': CategoryVisuals(Icons.alarm, Color(0xFFD2784B)),
    'daily': CategoryVisuals(Icons.auto_awesome_outlined, Color(0xFF4A9E8C)),
    'forgiveness': CategoryVisuals(Icons.spa_outlined, Color(0xFF5BA199)),
    'distress': CategoryVisuals(Icons.self_improvement, Color(0xFF6373C4)),
    'travel': CategoryVisuals(Icons.luggage_outlined, Color(0xFF4F93C4)),
    'mosque': CategoryVisuals(Icons.door_front_door_outlined, Color(0xFFB08D57)),
    'custom': CategoryVisuals(Icons.volunteer_activism_outlined, Color(0xFF2E9E83)),
  };

  static CategoryVisuals of(String categoryId) =>
      _map[categoryId] ??
      const CategoryVisuals(Icons.menu_book_outlined, Color(0xFF0E6B5C));
}
