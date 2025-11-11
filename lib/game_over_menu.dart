import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetromino_data.dart'; // Import dla 'worldSize'

/// Komponent menu "Game Over" wyświetlający wynik i najlepsze wyniki.
class GameOverMenuComponent extends PositionComponent {
  /// Końcowy wynik gracza.
  final int score;

  /// Lista 5 najlepszych wyników.
  final List<int> highScores;

  // Właściwości stylizacji menu
  late Vector2 boxSize;
  late Paint backgroundPaint;
  late Paint borderPaint;

  GameOverMenuComponent({required this.score, required this.highScores}) {
    // Definiujemy rozmiar na podstawie worldSize
    final boxWidth = worldSize.x * 0.8;
    final boxHeight = 400.0;
    boxSize = Vector2(boxWidth, boxHeight);

    // Półprzezroczyste czarne tło
    backgroundPaint = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.8);

    // Obramowanie pasujące do reszty UI
    borderPaint = Paint()
      ..color = Colors.blue.shade900.withAlpha(128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
  }

  @override
  Future<void> onLoad() async {
    size = boxSize;
    anchor = Anchor.center; // Wyśrodkuj komponent
    position = worldSize / 2; // Ustaw na środku świata gry

    // Komponent tekstu dla Flame
    final text = TextBoxComponent(
      text: _buildGameOverText(), // Użyj sformatowanego tekstu
      size: Vector2(boxSize.x * 0.9, boxSize.y * 0.9), // Wypełnij menu z marginesem
      align: Anchor.center,
      anchor: Anchor.center,
      position: size / 2, // Wyśrodkuj tekst wewnątrz menu
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Colors.white,
          fontSize: 16,
          height: 1.5, // Interlinia
        ),
      ),
    );
    add(text);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Rysuje tło i obramowanie menu
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  /// Prywatna metoda budująca sformatowany tekst dla menu.
  String _buildGameOverText() {
    String text = 'GAME OVER\nTwój wynik: $score\n\nNAJLEPSZE WYNIKI:\n';

    for (int i = 0; i < highScores.length; i++) {
      text += '${i + 1}. ${highScores[i]}\n';
    }

    text += '\n(Stuknij by zrestartować)';
    return text;
  }
}