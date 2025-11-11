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
  void rotate() {
    if (tetrominoType == 'O') return; // Klocek 'O' się nie obraca

    // Logika obrotu (macierz rotacji [0, -1], [1, 0])
    // (x, y) -> (-y, x)
    final List<Vector2> newShape = [];
    for (final offset in shape) {
      newShape.add(Vector2(-offset.y, offset.x));
    }

    // Sprawdź, czy nowa pozycja po obrocie jest prawidłowa
    if (game.isValidPosition(gridPosition, newShape)) {
      shape = newShape;
      updateTilePositions();

      // Odtwórz dźwięk obrotu, jeśli SFX są włączone
      if (game.isSfxEnabled.value) {
        FlameAudio.play('rotate.wav');
      }
    }
    // TODO: Dodać logikę "wall kick" (odpychania od ściany), jeśli obrót się nie powiedzie
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