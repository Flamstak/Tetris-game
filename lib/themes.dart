import 'package:flutter/material.dart';

/// Reprezentuje pojedynczy motyw kolorystyczny w grze.
class GameTheme {
  final String id; // Unikalny identyfikator, np. 'classic'
  final String name; // Wyświetlana nazwa, np. 'Classic'
  final bool isPremium; // Dla przyszłych płatnych motywów
  final Map<String, Color> tetrominoColors;
  final Color backgroundColor;
  final Color primaryColor;
  final Color accentColor;

  const GameTheme({
    required this.id,
    required this.name,
    this.isPremium = false,
    required this.tetrominoColors,
    required this.backgroundColor,
    required this.primaryColor,
    required this.accentColor,
  });
}

/// Lista wszystkich dostępnych motywów w grze.
final List<GameTheme> availableThemes = [
  // 1. Motyw klasyczny (domyślny)
  GameTheme(
    id: 'classic',
    name: 'Classic',
    backgroundColor: const Color(0xFF0A0A23), // Ciemny granat tła
    primaryColor: Colors.blue.shade900, // Ciemnoniebieski dla UI
    accentColor: Colors.blueAccent,
    tetrominoColors: {
      'I': Colors.cyanAccent,
      'J': Colors.blueAccent,
      'L': Colors.orangeAccent,
      'O': Colors.yellowAccent,
      'S': Colors.greenAccent,
      'T': Colors.purpleAccent,
      'Z': Colors.redAccent,
    },
  ),
  // 2. Nowy motyw "Forest"
  const GameTheme(
    id: 'forest',
    name: 'Forest',
    backgroundColor: Color(0xFF1E2B22),
    primaryColor: Color(0xFF3A7D44),
    accentColor: Color(0xFFC58940),
    tetrominoColors: {
      'I': Color(0xFF5DBE8A), // Jasny zielony
      'J': Color(0xFF3A7D44), // Ciemny zielony
      'L': Color(0xFFC58940), // Brązowy
      'O': Color(0xFFF9E076), // Jasny żółty
      'S': Color(0xFF8A9A5B), // Mech
      'T': Color(0xFF6B4226), // Ciemny brąz
      'Z': Color(0xFFB44C43), // Czerwono-brązowy
    },
  ),
  // 3. Nowy motyw "Ocean" (jako przykład premium)
  const GameTheme(
    id: 'ocean',
    name: 'Ocean',
    isPremium: true,
    backgroundColor: Color(0xFF001F3F),
    primaryColor: Color(0xFF003366),
    accentColor: Color(0xFF89CFF0),
    tetrominoColors: {
      'I': Color(0xFF89CFF0), 'J': Color(0xFF005A9C), 'L': Color(0xFF00A591),
      'O': Color(0xFFF0E68C), 'S': Color(0xFF50C878), 'T': Color(0xFF9F2B68),
      'Z': Color(0xFF4682B4),
    },
  ),
];

/// Zwraca motyw na podstawie jego ID. Domyślnie zwraca 'classic'.
GameTheme getThemeById(String id) {
  return availableThemes.firstWhere((theme) => theme.id == id, orElse: () => availableThemes.first);
}