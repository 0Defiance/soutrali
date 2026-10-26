import 'package:flutter/material.dart';

/// Icône de charte d’un service.
///
/// L’API renvoie la clé `icon` de la catégorie (`GET /api/v1/categories`
/// et `category.icon` des annonces) : cette carte la traduit en icône
/// Material. Les clés sont celles de `Category::ICONS` côté backend —
/// ajouter une clé suppose de la définir des deux côtés. Une clé inconnue
/// ou absente retombe sur l’icône générique de catégorie.
IconData categoryIcon(String? key) => _icons[key] ?? Icons.category;

const Map<String, IconData> _icons = {
  // Référentiel initial (D-07).
  'repair': Icons.handyman,
  'house': Icons.cleaning_services,
  'beauty': Icons.content_cut,
  'education': Icons.school,
  'digital': Icons.devices,
  'moving': Icons.local_shipping,
  'help': Icons.volunteer_activism,
  'misc': Icons.category,

  // Services ajoutés le 26 octobre 2026.
  'plumbing': Icons.plumbing,
  'electricity': Icons.electrical_services,
  'carpentry': Icons.carpenter,
  'painting': Icons.format_paint,
  'masonry': Icons.construction,
  'gardening': Icons.grass,
  'childcare': Icons.child_care,
  'elderly': Icons.elderly,
  'catering': Icons.restaurant,
  'health': Icons.spa,
  'sport': Icons.fitness_center,
  'photo': Icons.photo_camera,
  'events': Icons.celebration,
  'auto': Icons.directions_car,
  'delivery': Icons.delivery_dining,
  'business': Icons.calculate,
  'legal': Icons.gavel,
  'languages': Icons.translate,
  'security': Icons.security,
  'pets': Icons.pets,
  'arts': Icons.music_note,
  'marketing': Icons.campaign,
  'commerce': Icons.storefront,
  'agriculture': Icons.agriculture,
};
