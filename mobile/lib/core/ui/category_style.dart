import 'package:flutter/material.dart';

/// Icons that can be chosen for a category.
/// Keys are the names stored on the server.
const categoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'directions_bus': Icons.directions_bus,
  'home': Icons.home,
  'movie': Icons.movie,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'checkroom': Icons.checkroom,
  'subscriptions': Icons.subscriptions,
  'local_cafe': Icons.local_cafe,
  'sports_esports': Icons.sports_esports,
  'fitness_center': Icons.fitness_center,
  'pets': Icons.pets,
  'flight': Icons.flight,
  'phone_android': Icons.phone_android,
  'work': Icons.work,
  'card_giftcard': Icons.card_giftcard,
  'attach_money': Icons.attach_money,
  'more_horiz': Icons.more_horiz,
  'category': Icons.category,
};

/// Colors that can be chosen for a category.
const categoryColors = <String>[
  '#E53935',
  '#D81B60',
  '#8E24AA',
  '#3949AB',
  '#1E88E5',
  '#00897B',
  '#43A047',
  '#EF6C00',
  '#6D4C41',
  '#757575',
];

IconData iconFromName(String name) => categoryIcons[name] ?? Icons.category;

/// "#1E88E5" -> Color(0xFF1E88E5)
Color colorFromHex(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);