import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetromino_data.dart'; // <-- NOWY IMPORT
// Import tetris_game.dart nie jest już potrzebny, jeśli nie ma HasGameReference
// import 'tetris_game.dart'; 

class TileComponent extends PositionComponent {
  Vector2 _gridPosition; 
  final Color color;

  TileComponent({required Vector2 gridPosition, required this.color}) 
      : _gridPosition = gridPosition {
    size = Vector2.all(tileSize); // Używa tileSize
    updatePosition(); 
  }

  Vector2 get gridPosition => _gridPosition;

  set gridPosition(Vector2 newPos) {
    _gridPosition = newPos;
    updatePosition();
  }

  void updatePosition() {
    position = _gridPosition * tileSize; // Używa tileSize
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final rect = RRect.fromRectAndRadius(
      size.toRect(), 
      const Radius.circular(4.0),
    );
    
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