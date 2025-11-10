import 'package:flame/components.dart';
import 'package:flutter/material.dart'; 
import 'tetromino_data.dart'; // <-- NOWY IMPORT

class GameOverMenuComponent extends PositionComponent {
  final int score;
  final List<int> highScores;

  late Vector2 boxSize;
  late Paint backgroundPaint;
  late Paint borderPaint;

  GameOverMenuComponent({required this.score, required this.highScores}) {
    // Definiujemy rozmiar na podstawie worldSize
    final boxWidth = worldSize.x * 0.8;
    final boxHeight = 400.0;
    boxSize = Vector2(boxWidth, boxHeight);
    
    backgroundPaint = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.8);
    
    borderPaint = Paint()
      ..color = Colors.blue.shade900.withAlpha(128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  @override
  Future<void> onLoad() async {
    size = boxSize; 
    anchor = Anchor.center;
    position = worldSize / 2; // Używa worldSize
    
    final text = TextBoxComponent(
      text: _buildGameOverText(),
      size: Vector2(boxSize.x * 0.9, boxSize.y * 0.9),
      align: Anchor.center,
      anchor: Anchor.center,
      position: size / 2, 
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Colors.white,
          fontSize: 16, 
          height: 1.5,
        ),
      ),
    );
    add(text);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); 

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  String _buildGameOverText() {
    String text = 'GAME OVER\nTwój wynik: $score\n\nNAJLEPSZE WYNIKI:\n';
    
    for (int i = 0; i < highScores.length; i++) {
      text += '${i + 1}. ${highScores[i]}\n';
    }
    
    text += '\n(Stuknij by zrestartować)';
    return text;
  }
}