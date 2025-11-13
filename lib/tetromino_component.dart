import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tile_component.dart';
import 'tetris_game.dart';
import 'package:flame_audio/flame_audio.dart';

/// Reprezentuje aktywne, spadające tetromino (klocek),
/// składające się z wielu [TileComponent].
class TetrominoComponent extends PositionComponent
    with HasGameReference<TetrisGame> {
  /// Obecna pozycja lewego górnego rogu "pudełka" klocka na siatce logicznej.
  Vector2 gridPosition;

  /// Lista wektorów definiująca aktualny kształt klocka (względem [gridPosition]).
  List<Vector2> shape;

  /// Kolor kafelków tego klocka.
  final Color color;

  /// Typ klocka (np. 'I', 'L', 'O').
  final String tetrominoType;

  /// Lista komponentów kafelków tworzących ten klocek.
  List<TileComponent> tiles = [];

  /// Flaga, czy klocek właśnie wylądował (przed dodaniem do siatki).
  bool isLanded = false;

  /// Lista kafelków "ducha" pokazujących, gdzie wyląduje klocek.
  List<TileComponent> ghostTiles = [];

  TetrominoComponent({
    required this.tetrominoType,
    required this.shape,
    required this.color,
    required Vector2 startGridPosition,
  }) : gridPosition = startGridPosition;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Stwórz kafelki dla klocka i jego "ducha"
    for (final offset in shape) {
      final tilePos = gridPosition + offset;

      // Normalny kafelek
      final tile = TileComponent(
        gridPosition: tilePos,
        color: color,
        isGhost: false,
      );
      tiles.add(tile);
      add(tile);

      // Kafelek "ducha"
      final ghostTile = TileComponent(
        gridPosition: tilePos,
        color: color,
        isGhost: true,
      );
      ghostTiles.add(ghostTile);
      add(ghostTile);
    }
    updateGhostPosition(); // Ustaw "ducha" na właściwej pozycji

    // Poinformuj grę, że komponent jest w pełni załadowany i można grać
  }

  /// Aktualizuje pozycje wszystkich kafelków na podstawie [gridPosition] i [shape].
  void updateTilePositions() {
    for (int i = 0; i < tiles.length; i++) {
      tiles[i].gridPosition = gridPosition + shape[i];
    }
    updateGhostPosition();
  }

  /// Próbuje przesunąć klocek w danym kierunku (np. [0, 1] - w dół).
  void tryMove(Vector2 direction) {
    if (isLanded) return;
    final newGridPosition = gridPosition + direction;

    if (game.isValidPosition(newGridPosition, shape)) {
      // Jeśli nowa pozycja jest prawidłowa, przesuń klocek
      gridPosition = newGridPosition;
      updateTilePositions();
    } else {
      // Jeśli pozycja jest nieprawidłowa...
      if (direction.y > 0) {
        // ... a ruch był w dół, to znaczy, że klocek wylądował.
        isLanded = true;
        hideGhost();
        game.landTetromino(this);
      }
    }
  }

  /// Obraca klocek (jeśli to nie 'O') o 90 stopni zgodnie z ruchem wskazówek zegara.
  /// Implementuje logikę "wall kick" do testowania alternatywnych pozycji.
  void rotate() {
    if (tetrominoType == 'O') return; // Klocek 'O' się nie obraca

    // 1. Oblicz nowy kształt po obrocie
    // Logika obrotu (macierz rotacji [0, -1], [1, 0])
    // (x, y) -> (-y, x)
    final List<Vector2> newShape = [];
    for (final offset in shape) {
      newShape.add(Vector2(-offset.y, offset.x));
    }

    // 2. Zdefiniuj listę "kopnięć" (przesunięć) do przetestowania
    //    Zaczynamy od (0,0) - czyli brak "kopnięcia".
    //    Następnie testujemy przesunięcie w lewo i prawo.
    List<Vector2> kickOffsets = [
      Vector2(0, 0),   // Pozycja 0 (bez kicka)
      Vector2(-1, 0),  // Kick w lewo o 1
      Vector2(1, 0),   // Kick w prawo o 1
    ];

    // Klocek 'I' ma specyficzne, szersze "kopnięcia"
    if (tetrominoType == 'I') {
      kickOffsets.addAll([
        Vector2(-2, 0), // Kick w lewo o 2
        Vector2(2, 0),  // Kick w prawo o 2
      ]);
    }

    // 3. Przetestuj każdą pozycję "kick"
    for (final offset in kickOffsets) {
      final Vector2 newTestPosition = gridPosition + offset;

      // Sprawdź, czy nowa pozycja (po "kopnięciu") jest prawidłowa dla nowego kształtu
      if (game.isValidPosition(newTestPosition, newShape)) {
        // ZNALEZIONO PRAWIDŁOWĄ POZYCJĘ!

        // Zastosuj obrót (nowy kształt)
        shape = newShape;
        // Zastosuj "kopnięcie" (nowa pozycja)
        gridPosition = newTestPosition;
        
        // Zaktualizuj pozycje wizualne kafelków
        updateTilePositions();
        
        game.triggerHaptics(HapticType.rotate);

        // Odtwórz dźwięk obrotu, jeśli SFX są włączone
        if (game.isSfxEnabled.value) {
          FlameAudio.play('rotate.wav');
        }

        // Zakończ metodę, obrót się powiódł
        return;
      }
    }

    // 4. Jeśli pętla się zakończyła, żaden "kick" nie zadziałał.
    //    Obrót się nie udaje, nic nie rób.
  }

  /// Ukrywa "ducha" (używane po wylądowaniu klocka).
  void hideGhost() {
    for (final tile in ghostTiles) {
      tile.isHidden = true;
    }
  }

  /// Znajduje najniższą możliwą pozycję dla "ducha" i aktualizuje jego kafelki.
  void updateGhostPosition() {
    if (isLanded) return;

    Vector2 ghostPosition = gridPosition;
    // Pętla "spuszczania" ducha w dół, aż napotka przeszkodę
    while (game.isValidPosition(ghostPosition + Vector2(0, 1), shape)) {
      ghostPosition += Vector2(0, 1);
    }

    // Ustaw pozycje kafelków ducha
    for (int i = 0; i < ghostTiles.length; i++) {
      ghostTiles[i].gridPosition = ghostPosition + shape[i];
      ghostTiles[i].isHidden = false;
    }
  }
}