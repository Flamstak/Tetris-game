import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetris_game.dart';
import 'tetromino_data.dart';

/// Komponent odpowiedzialny za rysowanie wszystkich kafelków, które już wylądowały
/// (tzn. znajdują się w [game.grid]) oraz za animację czyszczenia linii.
class LandedTilesComponent extends PositionComponent
    with HasGameReference<TetrisGame> {
  /// Lista rzędów (Y), które są obecnie w trakcie animacji czyszczenia.
  List<int> linesBeingCleared = [];

  /// Postęp animacji czyszczenia linii (w zakresie od 0.0 do 1.0).
  double animationProgress = 0.0;

  LandedTilesComponent() {
    // Ustawia rozmiar komponentu na cały świat gry
    size = worldSize;
  }

  /// Rozpoczyna animację dla podanych linii.
  void startAnimation(List<int> lines) {
    linesBeingCleared.addAll(lines);
    animationProgress = 0.0;
  }

  /// Resetuje stan animacji (kończy ją).
  void stopAnimation() {
    linesBeingCleared.clear();
    animationProgress = 0.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Pędzel do rysowania obramowania kafelków
    final borderPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Iteruj po całej logicznej siatce gry (game.grid)
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final color = game.grid[x][y];

        if (linesBeingCleared.contains(y)) {
          // --- Logika Migania (Animacja Czyszczenia) ---
          
          // Proste miganie (widoczny/niewidoczny) co 10% postępu
          // (0.0-0.1: W, 0.1-0.2: OFF, 0.2-0.3: W, itd.)
          final isVisible = (animationProgress * 10).floor() % 2 == 0;

          // Kolor animacji (biały lub oryginalny, w zależności od cyklu)
          final animColor = isVisible ? Colors.white : color!;

          final rect = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawRect(rect, Paint()..color = animColor);
          canvas.drawRect(rect, borderPaint); // Narysuj też obramowanie
          
        } else if (color != null) {
          // --- Normalne Rysowanie Wylądowanego Kafelka ---
          final rect = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawRect(rect, Paint()..color = color);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }
  }
}