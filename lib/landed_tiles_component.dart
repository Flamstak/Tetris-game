import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/particles.dart';
import 'dart:math';
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

  /// Generator liczb losowych dla cząsteczek.
  final Random _random = Random();

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

  /// Tworzy i dodaje efekt cząsteczkowy dla wyczyszczonych linii.
  void spawnClearLineParticles(List<int> lines) {
    for (final y in lines) {
      for (int x = 0; x < columns; x++) {
        final tileColor = game.grid[x][y];
        if (tileColor == null) continue;

        // Pozycja środka kafelka
        final position = Vector2(
          x * tileSize + tileSize / 2,
          y * tileSize + tileSize / 2,
        );

        // Tworzymy system cząsteczek dla każdego kafelka
        final particleComponent = ParticleSystemComponent(
          particle: Particle.generate(
            count: 10, // 10 iskierek na kafelek
            lifespan: 0.6,
            generator: (i) {
              // Losowa prędkość w górę i na boki
              final speed = _random.nextDouble() * 150 + 50;
              final angle = _random.nextDouble() * pi - (pi * 1.5); // Kierunek "fontanny"
              final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

              // Cząsteczki zaczynają jako małe kółka
              return AcceleratedParticle(
                speed: velocity,
                // Grawitacja ściąga cząsteczki w dół
                acceleration: Vector2(0, 200),
                child: CircleParticle(
                  radius: _random.nextDouble() * 2 + 1,
                  // Mieszanka białego i koloru kafelka
                  paint: Paint()..color = Color.lerp(tileColor, Colors.white, _random.nextDouble() * 0.5)!,
                ),
              );
            },
          ),
          position: position,
        );
        parent?.add(particleComponent);
      }
    }
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
          // --- NOWA, BARDZIEJ EFEKTOWNA ANIMACJA ---

          // 1. Faza błysku (pierwsze 20% animacji)
          if (animationProgress < 0.2) {
            final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
            // Jasny, biały błysk
            canvas.drawRect(rect, Paint()..color = Colors.white);
            canvas.drawRect(rect, borderPaint);
            continue; // Przejdź do następnego kafelka
          }

          // 2. Faza "wymazywania" od środka na zewnątrz
          // Przeskaluj postęp animacji do zakresu 0.0-1.0 dla tej fazy
          final wipePhaseProgress = (animationProgress - 0.2) / 0.8;

          final centerColumn = (columns - 1) / 2.0;
          final distanceFromCenter = (x - centerColumn).abs();

          // `wipeThreshold` rośnie od 0 do `centerColumn`.
          // Kafelki znikają, gdy ich odległość od centrum jest mniejsza niż próg.
          final wipeThreshold = wipePhaseProgress * (centerColumn + 1);

          if (distanceFromCenter < wipeThreshold) {
            // Ten kafelek już "zniknął" w tej klatce animacji, więc go nie rysuj.
            continue;
          } else {
            // Jeśli kafelek jeszcze nie zniknął, narysuj go normalnie.
            // To tworzy efekt wymazywania od środka.
            final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
            canvas.drawRect(rect, Paint()..color = color!);
            canvas.drawRect(rect, borderPaint);
          }
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