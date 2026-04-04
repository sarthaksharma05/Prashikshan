import 'package:flutter/material.dart';

/// Canonical domain list — used across Students, Jobs, Hackathons tabs.
/// Labels must match EXACTLY what is stored in Firestore and returned by backend.
const List<Map<String, dynamic>> kDomains = [
  {'label': 'AI/ML',               'icon': Icons.memory},
  {'label': 'Web Development',     'icon': Icons.web},
  {'label': 'Android Development', 'icon': Icons.phone_android},
  {'label': 'Data Engineering',    'icon': Icons.storage},
  {'label': 'Cloud & DevOps',      'icon': Icons.cloud},
  {'label': 'Cybersecurity',       'icon': Icons.security},
  {'label': 'UI/UX Design',        'icon': Icons.design_services},
  {'label': 'Backend Development', 'icon': Icons.settings},
  {'label': 'Game Development',    'icon': Icons.videogame_asset},
  {'label': 'Blockchain',          'icon': Icons.currency_bitcoin},
];

/// Returns a soft color for a domain index — used for avatar backgrounds.
Color domainColor(String domain) {
  const colors = [
    Color(0xFF1565C0), // blue — AI/ML
    Color(0xFF00695C), // teal — Web Dev
    Color(0xFF2E7D32), // green — Android
    Color(0xFF4527A0), // deep purple — Data Eng
    Color(0xFF00838F), // cyan — Cloud/DevOps
    Color(0xFFC62828), // red — Cybersec
    Color(0xFF6A1B9A), // purple — UI/UX
    Color(0xFF37474F), // blue grey — Backend
    Color(0xFF558B2F), // light green — Game Dev
    Color(0xFFE65100), // deep orange — Blockchain
  ];
  final idx = kDomains.indexWhere((d) => d['label'] == domain);
  if (idx >= 0) return colors[idx % colors.length];
  return Colors.grey.shade700;
}

/// Returns initials from a full name
String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
