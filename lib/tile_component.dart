import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetromino_data.dart'; 

class TileComponent extends PositionComponent {
  Vector2 _gridPosition; 
  final Color color;
  final bool isGhost;

  // --- NOWA WŁAŚCIWOŚĆ ---
  // Sami definiujemy tę właściwość, ponieważ Flame jej nie ma!
  bool isHidden = false;

  TileComponent({
    required Vector2 gridPosition, 
    required this.color,
    this.isGhost = false, 
  }) : _gridPosition = gridPosition {
    size = Vector2.all(tileSize);
    updatePosition(); 
  }

  Vector2 get gridPosition => _gridPosition;

  set gridPosition(Vector2 newPos) {
    _gridPosition = newPos;
    updatePosition();
  }

  void updatePosition() {
    position = _gridPosition * tileSize;
  }

  // --- ZMODYFIKOWANA METODA RENDER ---
  @override
  void render(Canvas canvas) {
    // --- NOWA LOGIKA ---
    // Jeśli komponent jest ukryty, w ogóle go nie rysuj.
    if (isHidden) {
      return; 
    }
    // -------------------

    super.render(canvas);
    
    final rect = RRect.fromRectAndRadius(
      size.toRect(), 
      const Radius.circular(4.0),
    );

    if (isGhost) {
      final paint = Paint()
        ..color = color.withAlpha(50)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
    } else {
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
      
      final shinePaint = Paint()
        ..color = Colors.white.withAlpha(77)
        ..style = PaintingStyle.fill;
          
      final shineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.1, 
          size.y * 0.1, 
          size.x * 0.8, 
          size.y * 0.2, 
        ),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(shineRect, shinePaint);
    }
  }
}