import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tetromino_data.dart';

/// Reprezentuje pojedynczy, kolorowy kafelek na siatce gry.
/// Używany zarówno do aktywnych klocków, "duchów", jak i wylądowanych kafelków.
class TileComponent extends PositionComponent {
  // Prywatna zmienna przechowująca pozycję na siatce logicznej (np. [2, 3])
  Vector2 _gridPosition;

  /// Kolor kafelka.
  final Color color;

  /// Czy kafelek jest "duchem" (przezroczystym podglądem)?
  final bool isGhost;

  /// Właściwość pozwalająca ukryć kafelek (np. ducha po wylądowaniu klocka).
  bool isHidden = false;

  TileComponent({
    required Vector2 gridPosition,
    required this.color,
    this.isGhost = false,
  }) : _gridPosition = gridPosition {
    size = Vector2.all(tileSize);
    updatePosition();
  }

  /// Publiczny dostęp (getter) do pozycji na siatce.
  Vector2 get gridPosition => _gridPosition;

  /// Publiczny dostęp (setter) do pozycji na siatce.
  /// Automatycznie aktualizuje pozycję wizualną komponentu.
  set gridPosition(Vector2 newPos) {
    _gridPosition = newPos;
    updatePosition();
  }

  /// Przelicza pozycję na siatce (np. [2, 3]) na pozycję na ekranie (np. [60.0, 90.0]).
  void updatePosition() {
    position = _gridPosition * tileSize;
  }

  @override
  void render(Canvas canvas) {
    // Jeśli komponent jest ukryty, w ogóle go nie rysuj.
    if (isHidden) {
      return;
    }

    super.render(canvas);

    // Zaokrąglony prostokąt dla kafelka
    final rect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(4.0),
    );

    if (isGhost) {
      // Rysowanie "ducha" (przezroczysty z wypełnieniem)
      final paint = Paint()
        ..color = color.withAlpha(50)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
    } else {
      // Rysowanie normalnego kafelka (pełny kolor)
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);

      // Dodanie małego "połysku" na górze kafelka dla efektu 3D
      final shinePaint = Paint()
        ..color = Colors.white.withAlpha(77)
        ..style = PaintingStyle.fill;

      final shineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.1, // Odsunięcie
          size.y * 0.1, // Odsunięcie
          size.x * 0.8, // Szerokość
          size.y * 0.2, // Wysokość
        ),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(shineRect, shinePaint);
    }
  }
}