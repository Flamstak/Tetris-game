import 'package:flame/game.dart';
import 'package:flutter/material.dart'; 
import 'package:flame/components.dart';
import 'package:flame/camera.dart'; 
import 'package:flame/events.dart'; 
import 'dart:async'; 
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flame_audio/flame_audio.dart';

import 'tetromino_data.dart'; 
import 'tetromino_component.dart';
import 'tile_component.dart'; 
import 'landed_tiles_component.dart';
import 'game_over_menu.dart'; 

enum GameState { playing, lineClearing, spawning, gameOver }

class TetrisGame extends FlameGame 
    with DragCallbacks, TapCallbacks, DoubleTapCallbacks, WidgetsBindingObserver { 
  
  var gameState = GameState.spawning;
  double lineClearTimer = 0.0;
  final double lineClearAnimationDuration = 0.5;
  List<int> linesToClear = [];
  
  late TetrominoComponent currentTetromino;
  double fallSpeed = 0.8; 
  double fallTimer = 0.0; 
  double _dragAccumulatedX = 0.0;
  double _dragAccumulatedY = 0.0;
  int? _dragPointerId;
  late List<List<Color?>> grid;
  
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> level = ValueNotifier(1);
  int totalLinesCleared = 0;
  static const int linesPerLevel = 10;
  List<int> highScores = [];
  final ValueNotifier<String> nextTetrominoType = ValueNotifier('');
  final ValueNotifier<String?> heldTetrominoType = ValueNotifier(null); 
  bool _canHold = true;

  // --- Właściwości Ustawień ---
  final ValueNotifier<bool> isMusicEnabled = ValueNotifier(true);
  final ValueNotifier<bool> isSfxEnabled = ValueNotifier(true);
  // --- USUNIĘTO 'isSettingsVisible' ---
  // -------------------------

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
      'theme.mp3', 'rotate.wav', 'land.wav', 'clear_line.mp3', 'game_over.mp3',
    ]);
    
    grid = List.generate(columns, (_) => List.filled(rows, null));
    add(GradientBackgroundComponent());
    add(GridBackground());
    add(LandedTilesComponent());
    await _loadHighScores();
    
    await _loadSettings(); 
    
    nextTetrominoType.value = _getRandomTetrominoType();
    
    spawnNewTetromino(); 
    
    if (isMusicEnabled.value) {
      FlameAudio.bgm.play('theme.mp3');
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  void spawnNewTetromino() {
    // ... (bez zmian)
    final String currentType = nextTetrominoType.value;
    final shape = List<Vector2>.from(tetrominoShapes[currentType]!);
    final color = tetrominoColors[currentType]!;
    final startPos = Vector2(4, 1);

    if (!isValidPosition(startPos, shape)) {
      gameOver();
      return;
    }
    
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

  void spawnSpecificTetromino(String type) {
    // ... (bez zmian)
    final shape = List<Vector2>.from(tetrominoShapes[type]!);
    final color = tetrominoColors[type]!;
    final startPos = Vector2(4, 1);

    if (!isValidPosition(startPos, shape)) {
      gameOver();
      return;
    }
    
    currentTetromino = TetrominoComponent(
      tetrominoType: type,
      shape: shape,
      color: color,
      startGridPosition: startPos,
    );
    add(currentTetromino);
    _canHold = true;
  }

  void holdTetromino() {
    // ... (bez zmian)
    if (!_canHold || gameState != GameState.playing) return;
    _canHold = false; 
    final String typeToHold = currentTetromino.tetrominoType;
    remove(currentTetromino); 
    final String? previouslyHeldType = heldTetrominoType.value;

    gameState = GameState.spawning; 
    _dragPointerId = null; 
    
    if (previouslyHeldType == null) {
      heldTetrominoType.value = typeToHold;
      spawnNewTetromino(); 
    } else {
      heldTetrominoType.value = typeToHold;
      spawnSpecificTetromino(previouslyHeldType); 
    }
  }
  
  @override
  void onLongTapDown(TapDownEvent event) {
    // ... (bez zmian)
    if (gameState != GameState.playing) return;
    holdTetromino();
    super.onLongTapDown(event);
  }
  
  // ... (metody onDrag... bez zmian) ...
  @override
  void onDragStart(DragStartEvent event) {
    if (gameState != GameState.playing) return;
    if (_dragPointerId == null) {
      _dragPointerId = event.pointerId; 
      _dragAccumulatedX = 0.0; 
      _dragAccumulatedY = 0.0;
    }
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState != GameState.playing) return;
    if (_dragPointerId == null) {
      _dragPointerId = event.pointerId; 
      _dragAccumulatedX = 0.0; 
      _dragAccumulatedY = 0.0;
    }
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
    if (gameState != GameState.playing) return;
    if (event.pointerId == _dragPointerId) {
      _dragPointerId = null; 
      _dragAccumulatedX = 0.0; 
      _dragAccumulatedY = 0.0;
    }
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
     if (gameState != GameState.playing) return;
     if (event.pointerId == _dragPointerId) {
      _dragPointerId = null; 
      _dragAccumulatedX = 0.0; 
      _dragAccumulatedY = 0.0;
    }
    super.onDragCancel(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    // ... (bez zmian)
    if (gameState == GameState.gameOver) {
      restartGame();
      return;
    }
    if (gameState != GameState.playing) return;
    currentTetromino.rotate();
    super.onTapUp(event);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ... (bez zmian)
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (isMusicEnabled.value && gameState != GameState.gameOver) {
          FlameAudio.bgm.resume();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        FlameAudio.bgm.pause();
        break;
    }
  }
  
  bool isValidPosition(Vector2 tetrominoPos, List<Vector2> shape) {
    // ... (bez zmian)
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
    // ... (bez zmian)
    if (isSfxEnabled.value) {
      FlameAudio.play('land.wav');
    }
    for (final tile in tetromino.tiles) {
      final x = tile.gridPosition.x.toInt();
      final y = tile.gridPosition.y.toInt();
      if (x >= 0 && x < columns && y >= 0 && y < rows) {
        grid[x][y] = tile.color;
      }
    }
    remove(tetromino); 
    checkAndClearLines();
  }

  void checkAndClearLines() {
    // ... (bez zmian)
    List<int> fullLines = [];
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
        fullLines.add(y);
      }
      y--;
    }

    if (fullLines.isNotEmpty) {
      if (isMusicEnabled.value) {
        FlameAudio.bgm.play('clear_line.mp3');
      }
      gameState = GameState.lineClearing;
      _dragPointerId = null;
      linesToClear.addAll(fullLines);
      lineClearTimer = 0.0;
      
      children.whereType<LandedTilesComponent>().first.startAnimation(linesToClear);
      
    } else if (gameState == GameState.playing) {
      gameState = GameState.spawning;
      _dragPointerId = null; 
      spawnNewTetromino();
    }
  }

  void clearLogicalLine(int y) {
    // ... (bez zmian)
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
    // ... (bez zmian)
    int points = 0;
    if (linesCleared == 1) {
      points = 100 * level.value;
    } else if (linesCleared == 2) {
      points = 300 * level.value;
    } else if (linesCleared == 3) {
      points = 500 * level.value;
    } else if (linesCleared >= 4) {
      points = 800 * level.value;
    }
    score.value += points;

    totalLinesCleared += linesCleared;
    if (totalLinesCleared >= (level.value * linesPerLevel)) {
      level.value++;
      double newSpeed = 0.8 - (level.value - 1) * 0.05;
      fallSpeed = max(0.1, newSpeed);
    }
  }

  @override
  void update(double dt) {
    // ... (bez zmian)
    super.update(dt); 
    
    switch (gameState) {
      case GameState.playing:
        fallTimer += dt;
        if (fallTimer >= fallSpeed) {
          currentTetromino.tryMove(Vector2(0, 1)); 
          fallTimer = 0.0;
        }
        break;
      case GameState.lineClearing:
        lineClearTimer += dt;
        children.whereType<LandedTilesComponent>().first.animationProgress = 
            lineClearTimer / lineClearAnimationDuration;
        if (lineClearTimer >= lineClearAnimationDuration) {
          _finishLineClear();
        }
        break;
      case GameState.spawning: 
      case GameState.gameOver:
        break;
    }
  }

  void _finishLineClear() {
    // ... (bez zmian)
    for (final y in linesToClear.reversed) {
      clearLogicalLine(y);
    }
    addScore(linesToClear.length);
    linesToClear.clear();
    lineClearTimer = 0;
    children.whereType<LandedTilesComponent>().first.stopAnimation();
    gameState = GameState.spawning;
    spawnNewTetromino(); 
  }

  Future<void> gameOver() async {
    // ... (bez zmian)
    gameState = GameState.gameOver;
    _dragPointerId = null; 
    FlameAudio.bgm.stop(); 
    
    if (isMusicEnabled.value) {
      FlameAudio.bgm.play('game_over.mp3');
    }
    
    await _updateAndSaveHighScores(score.value);
    final menu = GameOverMenuComponent(
      score: score.value,
      highScores: highScores,
    );
    add(menu); 
  }

  void restartGame() {
    // ... (bez zmian)
    grid = List.generate(columns, (_) => List.filled(rows, null));
    removeAll(children.whereType<GameOverMenuComponent>());
    removeAll(children.whereType<TetrominoComponent>());
    
    score.value = 0; 
    level.value = 1;
    totalLinesCleared = 0;
    fallSpeed = 0.8;
    
    gameState = GameState.spawning;
    heldTetrominoType.value = null;
    _canHold = true;
    _dragPointerId = null; 
    
    nextTetrominoType.value = _getRandomTetrominoType();
    spawnNewTetromino(); 

    FlameAudio.bgm.stop(); 
    if (isMusicEnabled.value) {
      FlameAudio.bgm.play('theme.mp3'); 
    }
  }

  Future<void> _loadHighScores() async {
    // ... (bez zmian)
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = prefs.getStringList('highScores') ?? [];
    highScores = scoreStrings.map((s) => int.parse(s)).toList();
  }
  Future<void> _updateAndSaveHighScores(int newScore) async {
    // ... (bez zmian)
    highScores.add(newScore);
    highScores.sort((a, b) => b.compareTo(a));
    highScores = highScores.take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = highScores.map((s) => s.toString()).toList();
    await prefs.setStringList('highScores', scoreStrings);
  }

  // --- Metody Zarządzania Ustawieniami ---

  Future<void> _loadSettings() async {
    // ... (bez zmian)
    final prefs = await SharedPreferences.getInstance();
    isMusicEnabled.value = prefs.getBool('isMusicEnabled') ?? true;
    isSfxEnabled.value = prefs.getBool('isSfxEnabled') ?? true;
  }

  Future<void> _saveSettings() async {
    // ... (bez zmian)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicEnabled', isMusicEnabled.value);
    await prefs.setBool('isSfxEnabled', isSfxEnabled.value);
  }

  void toggleMusic() {
    // ... (bez zmian)
    isMusicEnabled.value = !isMusicEnabled.value;
    if (isMusicEnabled.value) {
      if (gameState != GameState.gameOver) {
        FlameAudio.bgm.play('theme.mp3');
      }
    } else {
      FlameAudio.bgm.stop();
    }
    _saveSettings();
  }

  void toggleSfx() {
    // ... (bez zmian)
    isSfxEnabled.value = !isSfxEnabled.value;
    _saveSettings();
  }
  
  // --- USUNIĘTO 'toggleSettingsVisibility' ---

} // --- Koniec klasy TetrisGame ---


// (Komponenty tła bez zmian)
class GradientBackgroundComponent extends PositionComponent with HasGameReference<TetrisGame> {
// ... (bez zmian)
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
// ... (bez zmian)
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