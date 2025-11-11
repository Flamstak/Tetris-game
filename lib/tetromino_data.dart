import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// --- STAŁE SIATKI I ROZMIARU ---

/// Liczba rzędów (wysokość) siatki gry.
const int rows = 20;

/// Liczba kolumn (szerokość) siatki gry.
const int columns = 10;

/// Rozmiar (w pikselach) boku jednego kafelka.
const double tileSize = 30.0;

/// Całkowity rozmiar świata gry (planszy) w pikselach.
final Vector2 worldSize = Vector2(columns * tileSize, rows * tileSize);

// --- DEFINICJE KSZTAŁTÓW TETROMINO ---
// Kształty są zdefiniowane przez 4 wektory (Vector2)
// względem punktu centralnego (0, 0) na siatce logicznej.

final Map<String, List<Vector2>> tetrominoShapes = {
  // **** (I)
  'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
  // * (J)
  // ***
  'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  //   * (L)
  // ***
  'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  // ** (O)
  // **
  'O': [Vector2(0, -1), Vector2(1, -1), Vector2(0, 0), Vector2(1, 0)],
  //  ** (S)
  // **
  'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
  //  * (T)
  // ***
  'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  // ** (Z)
  //  **
  'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
};

// --- DEFINICJE KOLORÓW ---
// Standardowe kolory Tetrisa
final Map<String, Color> tetrominoColors = {
  'I': Colors.cyanAccent.shade400,
  'J': Colors.blueAccent.shade400,
  'L': Colors.orangeAccent.shade400,
  'O': Colors.yellowAccent.shade400,
  'S': Colors.greenAccent.shade400,
  'T': Colors.purpleAccent.shade400,
  'Z': Colors.redAccent.shade400,
};

// --- MAPA DLA PODGLĄDU NASTĘPNEGO KLOCKA (Next/Hold Box) ---
// Definiuje pozycje klocków w siatce 4x4 (indeksy 0-15)
// 0  1  2  3
// 4  5  6  7
// 8  9  10 11
// 12 13 14 15
final Map<String, List<int>> nextPieceGrid = {
  'I': [4, 5, 6, 7], // Poziomo na drugim rzędzie
  'J': [1, 5, 9, 10], // Kształt 'J'
  'L': [2, 6, 10, 9], // Kształt 'L'
  'O': [5, 6, 9, 10], // Idealnie na środku
  'S': [6, 7, 9, 10], // Kształt 'S'
  'T': [5, 6, 7, 10], // Kształt 'T'
  'Z': [4, 5, 9, 10], // Kształt 'Z'
};