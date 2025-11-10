import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart'; 
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flame_audio/flame_audio.dart';

// Importy gry
import 'tetromino_data.dart'; 
import 'tetromino_component.dart';
import 'landed_tiles_component.dart';
import 'game_over_menu.dart'; 

// --- POPRAWKA TUTAJ: Usunięto 'LongPressCallbacks' ---
class TetrisGame extends FlameGame 
    with DragCallbacks, TapCallbacks, DoubleTapCallbacks {
  
  // Właściwości gry
  late TetrominoComponent currentTetromino;
  double fallSpeed = 0.8; 
  double fallTimer = 0.0; 
  double _dragAccumulatedX = 0.0;
  double _dragAccumulatedY = 0.0;
  int? _dragPointerId;
  late List<List<Color?>> grid;
  bool isGameOver = false;
  final ValueNotifier<int> score = ValueNotifier(0);
  List<int> highScores = [];

  // Właściwości dla "Next" i "Hold"
  final ValueNotifier<String> nextTetrominoType = ValueNotifier('');
  final ValueNotifier<String?> heldTetrominoType = ValueNotifier(null); 
  
  bool _canHold = true;

  String _getRandomTetrominoType() {
    final keys = tetrominoShapes.keys.toList();
    return (keys..shuffle()).first;
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0A23); 

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    camera.viewport = FixedResolutionViewport(resolution: worldSize);
    camera.viewfinder.position = worldSize / 2;
    camera.viewfinder.anchor = Anchor.center;
    
    await FlameAudio.audioCache.loadAll([
      'theme.mp3',
      'rotate.wav',
      'land.wav',
      'clear_line.mp3',
      'game_over.mp3',
    ]);
    
    grid = List.generate(columns, (_) => List.filled(rows, null));
    add(GradientBackgroundComponent());
    add(GridBackground());
    add(LandedTilesComponent());
    
    await _loadHighScores();
    nextTetrominoType.value = _getRandomTetrominoType();
    spawnNewTetromino();
    
    FlameAudio.bgm.play('theme.mp3');
  }

  // Tworzy nowy klocek z kolejki "Next"
  void spawnNewTetromino() {
    final String currentType = nextTetrominoType.value;
    final shape = List<Vector2>.from(tetrominoShapes[currentType]!);
    final color = tetrominoColors[currentType]!;
    final startPos = Vector2(4, 1);

    if (!isValidPosition(startPos, shape)) {
      gameOver();
    } else {
      currentTetromino = TetrominoComponent(
        tetrominoType: currentType,
        shape: shape,
        color: color,
        startGridPosition: startPos,
      );
      add(currentTetromino);
      _canHold = true; 
      nextTetrominoType.value = _getRandomTetrominoType();
    }
  }

  // Tworzy klocek o konkretnym typie (używane przez "Hold")
  void spawnSpecificTetromino(String type) {
    final shape = List<Vector2>.from(tetrominoShapes[type]!);
    final color = tetrominoColors[type]!;
    final startPos = Vector2(4, 1);

    if (!isValidPosition(startPos, shape)) {
      gameOver();
    } else {
      currentTetromino = TetrominoComponent(
        tetrominoType: type,
        shape: shape,
        color: color,
        startGridPosition: startPos,
      );
      add(currentTetromino);
      _canHold = true;
    }
  }

  // --- Logika "Hold" ---
  void holdTetromino() {
    if (!_canHold || isGameOver) return;
    _canHold = false; 

    // Opcjonalnie: FlameAudio.play('hold.wav');

    final String typeToHold = currentTetromino.tetrominoType;
    remove(currentTetromino); 

    final String? previouslyHeldType = heldTetrominoType.value;

    if (previouslyHeldType == null) {
      heldTetrominoType.value = typeToHold;
      spawnNewTetromino();
    } else {
      heldTetrominoType.value = typeToHold;
      spawnSpecificTetromino(previouslyHeldType);
    }
  }

  // --- Obsługa gestów ---

  // --- POPRAWKA TUTAJ: Zmiana nazwy metody i typu eventu ---
  @override
  void onLongTapDown(TapDownEvent event) {
    if (isGameOver) return;
    holdTetromino();
    super.onLongTapDown(event); // Wywołujemy poprawną metodę 'super'
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (isGameOver) return; 
    if (_dragPointerId == null) {
      _dragPointerId = event.pointerId; _dragAccumulatedX = 0.0; _dragAccumulatedY = 0.0;
    }
    super.onDragStart(event);
  }
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isGameOver) return; 
    if (event.pointerId == _dragPointerId) {
      _dragAccumulatedX += event.canvasDelta.x;
      if (event.canvasDelta.y > 0) _dragAccumulatedY += event.canvasDelta.y;
      if (_dragAccumulatedX.abs() > tileSize * 1.5) { 
        final direction = _dragAccumulatedX > 0 ? 1 : -1; 
        currentTetromino.tryMove(Vector2(direction.toDouble(), 0));
        _dragAccumulatedX = 0.0;
      }
      if (_dragAccumulatedY > tileSize) {
        currentTetromino.tryMove(Vector2(0, 1));
        fallTimer = 0.0; 
        _dragAccumulatedY = 0.0;
      }
    }
    super.onDragUpdate(event);
  }
  @override
  void onDragEnd(DragEndEvent event) {
    if (isGameOver) return; 
    if (event.pointerId == _dragPointerId) {
      _dragPointerId = null; _dragAccumulatedX = 0.0; _dragAccumulatedY = 0.0;
    }
    super.onDragEnd(event);
  }
  @override
  void onDragCancel(DragCancelEvent event) {
     if (isGameOver) return; 
     if (event.pointerId == _dragPointerId) {
      _dragPointerId = null; _dragAccumulatedX = 0.0; _dragAccumulatedY = 0.0;
    }
    super.onDragCancel(event);
  }
  @override
  void onTapUp(TapUpEvent event) {
    if (isGameOver) {
      restartGame();
      return;
    }
    currentTetromino.rotate();
    super.onTapUp(event);
  }
  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (isGameOver) return;
    currentTetromino.hardDrop();
    super.onDoubleTapDown(event);
  }
  // --- Koniec obsługi gestów ---


  // --- Logika gry (bez zmian) ---
  bool isValidPosition(Vector2 tetrominoPos, List<Vector2> shape) {
    for (final offset in shape) {
      final tilePos = tetrominoPos + offset;
      final x = tilePos.x.toInt();
      final y = tilePos.y.toInt();
      if (x < 0 || x >= columns || y >= rows) return false;
      if (y >= 0) {
         if (grid[x][y] != null) return false;
      }
    }
    return true;
  }

  void landTetromino(TetrominoComponent tetromino) {
    FlameAudio.play('land.wav');
    for (final tile in tetromino.tiles) {
      final x = tile.gridPosition.x.toInt();
      final y = tile.gridPosition.y.toInt();
      if (x >= 0 && x < columns && y >= 0 && y < rows) {
        grid[x][y] = tile.color;
      }
    }
    remove(tetromino); 
    checkAndClearLines();
    if (!isGameOver) {
      spawnNewTetromino();
    }
  }

  void checkAndClearLines() {
    int linesClearedThisTurn = 0;
    int y = rows - 1;
    while (y >= 0) {
      bool isLineFull = true;
      for (int x = 0; x < columns; x++) {
        if (grid[x][y] == null) {
          isLineFull = false;
          break; 
        }
      }
      if (isLineFull) {
        clearLogicalLine(y);
        linesClearedThisTurn++;
      } else {
        y--;
      }
    }
    if (linesClearedThisTurn > 0) {
      FlameAudio.play('clear_line.mp3');
      addScore(linesClearedThisTurn);
    }
  }

  void clearLogicalLine(int y) {
    for (int r = y; r > 0; r--) {
      for (int c = 0; c < columns; c++) {
        grid[c][r] = grid[c][r - 1];
      }
    }
    for (int c = 0; c < columns; c++) {
      grid[c][0] = null;
    }
  }

  void addScore(int linesCleared) {
    int points = 0;
    if (linesCleared == 1) {
      points = 100;
    } else if (linesCleared == 2) {
      points = 300;
    } else if (linesCleared == 3) {
      points = 500;
    } else if (linesCleared >= 4) {
      points = 800;
    }
    score.value += points;
  }

  @override
  void update(double dt) {
    super.update(dt); 
    if (isGameOver) return;
    fallTimer += dt;
    if (fallTimer >= fallSpeed) {
      currentTetromino.tryMove(Vector2(0, 1)); 
      fallTimer = 0.0;
    }
  }

  Future<void> gameOver() async {
    isGameOver = true;
    FlameAudio.bgm.stop(); 
    FlameAudio.play('game_over.mp3');

    await _updateAndSaveHighScores(score.value);
    final menu = GameOverMenuComponent(
      score: score.value,
      highScores: highScores,
    );
    add(menu); 
  }

  void restartGame() {
    grid = List.generate(columns, (_) => List.filled(rows, null));
    removeAll(children.whereType<GameOverMenuComponent>());
    removeAll(children.whereType<TetrominoComponent>());
    score.value = 0; 
    isGameOver = false;
    heldTetrominoType.value = null;
    _canHold = true;
    nextTetrominoType.value = _getRandomTetrominoType();
    spawnNewTetromino();
    FlameAudio.bgm.play('theme.mp3');
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = prefs.getStringList('highScores') ?? [];
    highScores = scoreStrings.map((s) => int.parse(s)).toList();
  }

  Future<void> _updateAndSaveHighScores(int newScore) async {
    highScores.add(newScore);
    highScores.sort((a, b) => b.compareTo(a));
    highScores = highScores.take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = highScores.map((s) => s.toString()).toList();
    await prefs.setStringList('highScores', scoreStrings);
  }
}

// --- Komponenty Tła (bez zmian) ---
class GradientBackgroundComponent extends PositionComponent with HasGameReference<TetrisGame> {
  GradientBackgroundComponent() {
    size = worldSize;
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0A23), 
        Colors.black,            
      ],
    );
    final paint = Paint()..shader = gradient.createShader(size.toRect());
    canvas.drawRect(size.toRect(), paint);
  }
}

class GridBackground extends PositionComponent {
  GridBackground() { size = worldSize; }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = Colors.blue.shade900.withAlpha(128) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var x = 0.0; x <= size.x; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (var y = 0.0; y <= size.y; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }
}