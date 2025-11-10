import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tile_component.dart';
import 'tetris_game.dart'; 
import 'package:flame_audio/flame_audio.dart'; // Import audio

class TetrominoComponent extends Component with HasGameReference<TetrisGame> {
  Vector2 gridPosition; 
  List<Vector2> shape; 
  final Color color;
  final String tetrominoType; 
  List<TileComponent> tiles = [];
  bool isLanded = false;

  TetrominoComponent({
    required this.tetrominoType, 
    required this.shape,
    required this.color,
    required Vector2 startGridPosition,
  }) : gridPosition = startGridPosition;

  @override
  Future<void> onLoad() async {
    // (Ta metoda pozostaje bez zmian)
    await super.onLoad();
    for (final offset in shape) {
      final tilePos = gridPosition + offset;
      final tile = TileComponent(
        gridPosition: tilePos,
        color: color,
      );
      tiles.add(tile);
      add(tile); 
    }
  }
  
  void updateTilePositions() {
    // (Ta metoda pozostaje bez zmian)
    for (int i = 0; i < tiles.length; i++) {
      tiles[i].gridPosition = gridPosition + shape[i];
    }
  }

  void tryMove(Vector2 direction) {
    // (Ta metoda pozostaje bez zmian)
    if (isLanded) return;
    final newGridPosition = gridPosition + direction;

    if (game.isValidPosition(newGridPosition, shape)) {
      gridPosition = newGridPosition;
      updateTilePositions();
    } else {
      if (direction.y > 0) {
        isLanded = true; 
        game.landTetromino(this);
      }
    }
  }

  // --- ZMODYFIKOWANE ---
  void rotate() {
    if (tetrominoType == 'O') return; // 'O' się nie obraca

    final List<Vector2> newShape = [];
    for (final offset in shape) {
      newShape.add(Vector2(-offset.y, offset.x));
    }

    if (game.isValidPosition(gridPosition, newShape)) {
      shape = newShape; 
      updateTilePositions(); 
      
      // Odtwórz dźwięk obrotu
      FlameAudio.play('rotate.wav');
    }
  }

  // NOWA METODA: Hard Drop
  void hardDrop() {
    if (isLanded) return; // Już wylądował, nie rób nic

    Vector2 finalPosition = gridPosition;

    // Pętlą szukamy najniższej dozwolonej pozycji
    while (game.isValidPosition(finalPosition + Vector2(0, 1), shape)) {
      finalPosition += Vector2(0, 1);
    }

    // Znaleźliśmy ostateczne miejsce, ustawmy je
    gridPosition = finalPosition;
    updateTilePositions();
    
    // Natychmiast wyląduj klocek
    isLanded = true;
    game.landTetromino(this);
  }
}