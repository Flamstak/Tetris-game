import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/particles.dart';
import 'dart:math';
import 'tetris_game.dart';
import 'tetromino_data.dart';
import 'vfx.dart';

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
  void startLineClearAnimation(List<int> lines) {
    linesBeingCleared.addAll(lines);
    animationProgress = 0.0;
  }

  /// Resetuje stan animacji (kończy ją).
  void stopLineClearAnimation() {
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
          // --- NOWA LOGIKA: Użyj funkcji animacji z aktywnego pakietu VFX ---
          if (color != null) {
            final shouldDrawNormally = game.currentVfxPack.lineClearAnimation(
              canvas,
              animationProgress,
              x,
              y * tileSize, // Przekazujemy pozycję Y na płótnie
              color,
              tileSize, // Przekazujemy standardowy rozmiar kafelka
              borderPaint,
            );
            // Jeśli funkcja animacji zwróci `true`, oznacza to, że mamy
            // narysować kafelek w standardowy sposób.
            if (shouldDrawNormally) {
              // --- TO JEST KLUCZOWA POPRAWKA ---
              // Rysuj kafelek normalnie, jeśli funkcja animacji tak zdecydowała.
              final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
              canvas.drawRect(rect, Paint()..color = color);
              canvas.drawRect(rect, borderPaint);
            }
            // Jeśli funkcja zwróciła `false`, oznacza to, że sama narysowała
            // animację (np. zanikanie) lub kafelek ma być niewidoczny. W obu
            // przypadkach przechodzimy do następnej iteracji.
            continue;
          }
        } 
        if (color != null) {
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