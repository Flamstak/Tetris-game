import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'tetromino_data.dart'; // Import dla 'worldSize'

/// Komponent menu "Game Over" wyświetlający wynik i najlepsze wyniki.
class GameOverMenuComponent extends PositionComponent implements OpacityProvider {
  /// Końcowy wynik gracza.
  final int score;

  /// Lista 5 najlepszych wyników.
  final List<int> highScores;

  // Właściwości stylizacji menu
  late Vector2 boxSize;
  late Paint backgroundPaint;
  late Paint borderPaint;

  // --- DODANO: Implementacja interfejsu OpacityProvider ---
  double _opacity = 1.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    // Przekaż przezroczystość do potomków (tekstu)
    children.whereType<OpacityProvider>().forEach((child) => child.opacity = value);
  }

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

    // --- DODANO ANIMACJĘ ---
    // Ustaw stan początkowy dla animacji
    scale = Vector2.all(0.0);
    // Dzieci komponentu (tekst) również będą dziedziczyć przezroczystość
    // Użyjemy `OpacityEffect.fadeIn` dla prostoty.
    // --- KONIEC DODAWANIA ---

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

    // --- DODANO ANIMACJĘ ---
    // Dodaj efekt skalowania z "elastyczną" krzywą animacji
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.6, curve: Curves.elasticOut),
      ),
    );

    // Dodaj efekt płynnego pojawiania się (zwiększania przezroczystości)
    add(OpacityEffect.fadeIn(EffectController(duration: 0.3)));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Rysuje tło i obramowanie menu
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8.0),
    );

    // Użyj aktualnej wartości `opacity` do rysowania tła i ramki
    final backgroundPaintWithOpacity = Paint()..color = backgroundPaint.color.withOpacity(opacity * 0.8);
    final borderPaintWithOpacity = Paint()..color = borderPaint.color.withOpacity(opacity);

    canvas.drawRRect(rrect, backgroundPaintWithOpacity);
    canvas.drawRRect(rrect, borderPaint..color = borderPaint.color.withOpacity(opacity));
  }

  /// Prywatna metoda budująca sformatowany tekst dla menu.
  String _buildGameOverText() {
    String text = 'GAME OVER\nYour score: $score\n\nHIGH SCORES:\n';

    for (int i = 0; i < highScores.length; i++) {
      text += '${i + 1}. ${highScores[i]}\n';
    }

    text += '\n(Tap to restart)';
    return text;
  }
}