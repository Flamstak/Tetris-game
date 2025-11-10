import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetris_game.dart';
import 'tetromino_data.dart'; // <-- NOWY IMPORT

class LandedTilesComponent extends PositionComponent with HasGameReference<TetrisGame> {
  LandedTilesComponent() {
    size = worldSize; // Używa worldSize
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final borderPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Używa 'rows' i 'columns'
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final color = game.grid[x][y];
        if (color != null) {
          final rect = Rect.fromLTWH(
            x * tileSize, // Używa tileSize
            y * tileSize, // Używa tileSize
            tileSize,     // Używa tileSize
            tileSize,
          );
          canvas.drawRect(rect, Paint()..color = color);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }
  }
}