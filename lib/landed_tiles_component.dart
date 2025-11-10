import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetris_game.dart';
import 'tetromino_data.dart'; 

class LandedTilesComponent extends PositionComponent with HasGameReference<TetrisGame> {
  
  // --- NOWE WŁAŚCIWOŚCI ANIMACJI ---
  List<int> linesBeingCleared = [];
  double animationProgress = 0.0;
  
  LandedTilesComponent() {
    size = worldSize;
  }

  // --- NOWE METODY STERUJĄCE ---
  void startAnimation(List<int> lines) {
    linesBeingCleared.addAll(lines);
    animationProgress = 0.0;
  }

  void stopAnimation() {
    linesBeingCleared.clear();
    animationProgress = 0.0;
  }

  // --- ZMODYFIKOWANA METODA 'render' ---
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final borderPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final color = game.grid[x][y];
        
        if (linesBeingCleared.contains(y)) {
          // --- LOGIKA MIGANIA ---
          // Proste miganie (widoczny/niewidoczny) co 10% postępu
          // (0.0-0.1: W, 0.1-0.2: OFF, 0.2-0.3: W, itd.)
          final isVisible = (animationProgress * 10).floor() % 2 == 0;
          
          final animColor = isVisible ? Colors.white : color!;
          
          final rect = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawRect(rect, Paint()..color = animColor);
          canvas.drawRect(rect, borderPaint);
          
        } else if (color != null) {
          // --- NORMALNE RYSOWANIE ---
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