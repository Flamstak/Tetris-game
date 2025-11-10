import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// --- STAŁE GRY ---
const int rows = 20;
const int columns = 10;
const double tileSize = 30.0;
final Vector2 worldSize = Vector2(columns * tileSize, rows * tileSize);

// --- DEFINICJE KSZTAŁTÓW ---
final Map<String, List<Vector2>> tetrominoShapes = {
  'I': [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
  'J': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  'L': [Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  'O': [Vector2(0, -1), Vector2(1, -1), Vector2(0, 0), Vector2(1, 0)],
  'S': [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(0, 0)],
  'T': [Vector2(0, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)],
  'Z': [Vector2(-1, -1), Vector2(0, -1), Vector2(0, 0), Vector2(1, 0)],
};

// --- DEFINICJE KOLORÓW ---
final Map<String, Color> tetrominoColors = {
  'I': Colors.cyanAccent.shade400,
  'J': Colors.blueAccent.shade400,
  'L': Colors.orangeAccent.shade400,
  'O': Colors.yellowAccent.shade400,
  'S': Colors.greenAccent.shade400,
  'T': Colors.purpleAccent.shade400,
  'Z': Colors.redAccent.shade400,
};

// --- MAPA DLA PODGLĄDU NASTĘPNEGO KLOCKA ---
// Definiuje pozycje klocków w siatce 4x4 (indeksy 0-15)
final Map<String, List<int>> nextPieceGrid = {
  'I': [4, 5, 6, 7], // Poziomo na drugim rzędzie
  'J': [1, 5, 9, 10],
  'L': [2, 6, 10, 9],
  'O': [5, 6, 9, 10], // Idealnie na środku
  'S': [6, 7, 9, 10],
  'T': [5, 6, 7, 10],
  'Z': [4, 5, 9, 10],
};