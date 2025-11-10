import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tile_component.dart'; 
import 'tetris_game.dart'; 
import 'package:flame_audio/flame_audio.dart';

class TetrominoComponent extends PositionComponent with HasGameReference<TetrisGame> {
  Vector2 gridPosition; 
  List<Vector2> shape; 
  final Color color; 
  final String tetrominoType; 
  List<TileComponent> tiles = []; 
  bool isLanded = false; 

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
    for (final offset in shape) { 
      final tilePos = gridPosition + offset; 
      
      final tile = TileComponent( 
        gridPosition: tilePos, 
        color: color, 
        isGhost: false, 
      );
      tiles.add(tile); 
      add(tile); 

      final ghostTile = TileComponent( 
        gridPosition: tilePos, 
        color: color, 
        isGhost: true, 
      );
      ghostTiles.add(ghostTile); 
      add(ghostTile); 
    }
    updateGhostPosition(); 

    // Poinformuj grę, że komponent jest w pełni załadowany i można grać.
    game.gameState = GameState.playing; 
  }
  
  void updateTilePositions() {
    for (int i = 0; i < tiles.length; i++) { 
      tiles[i].gridPosition = gridPosition + shape[i]; 
    }
    updateGhostPosition(); 
  }

  void tryMove(Vector2 direction) {
    if (isLanded) return; 
    final newGridPosition = gridPosition + direction; 

    if (game.isValidPosition(newGridPosition, shape)) { 
      gridPosition = newGridPosition; 
      updateTilePositions(); 
    } else {
      if (direction.y > 0) { 
        isLanded = true; 
        hideGhost(); 
        game.landTetromino(this); 
      }
    }
  }

  void rotate() {
    if (tetrominoType == 'O') return; 

    final List<Vector2> newShape = []; 
    for (final offset in shape) { 
      newShape.add(Vector2(-offset.y, offset.x)); 
    }

    if (game.isValidPosition(gridPosition, newShape)) { 
      shape = newShape; 
      updateTilePositions(); 
      
      // --- POPRAWKA: Sprawdź ustawienia SFX przed odtworzeniem dźwięku ---
      if (game.isSfxEnabled.value) {
        FlameAudio.play('rotate.wav'); 
      }
    }
  }

  void hideGhost() {
    for (final tile in ghostTiles) { 
      tile.isHidden = true; 
    }
  }

  void updateGhostPosition() {
    if (isLanded) return; 

    Vector2 ghostPosition = gridPosition; 
    while (game.isValidPosition(ghostPosition + Vector2(0, 1), shape)) { 
      ghostPosition += Vector2(0, 1); 
    }

    for (int i = 0; i < ghostTiles.length; i++) { 
      ghostTiles[i].gridPosition = ghostPosition + shape[i]; 
      ghostTiles[i].isHidden = false; 
    }
  }
}