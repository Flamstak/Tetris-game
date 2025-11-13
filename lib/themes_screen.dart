import 'package:flutter/material.dart';
import 'settings_manager.dart';
import 'themes.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart'; // <-- DODAJ TEN IMPORT
import 'tetris_game.dart'; // Import dla ModernBackgroundComponent
import 'tetromino_data.dart'; // Import dla tileSize i worldSize

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late String _currentThemeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final themeId = await SettingsManager.loadThemeSetting();
    if (mounted) {
      setState(() {
        _currentThemeId = themeId;
        _isLoading = false;
      });
    }
  }

  void _showThemePreview(GameTheme theme) {
    showDialog(
      context: context,
      builder: (context) => _ThemePreviewDialog(
        theme: theme,
        onSelect: () {
          setState(() {
            _currentThemeId = theme.id;
          });
          SettingsManager.saveThemeSetting(theme.id);
          Navigator.of(context).pop(); // Zamknij dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${theme.name} theme applied!'),
              backgroundColor: theme.accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jeśli ekran się ładuje, pokaż domyślny wygląd
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.grey[900]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = getThemeById(_currentThemeId);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Themes',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availableThemes.length,
              itemBuilder: (context, index) {
                final itemTheme = availableThemes[index];
                final isSelected = itemTheme.id == _currentThemeId;

                return Card(
                  color: theme.primaryColor.withAlpha((255 * 0.5).round()),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    onTap: () => _showThemePreview(itemTheme),
                    title: Text(
                      itemTheme.name,
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: isSelected ? theme.accentColor : Colors.white,
                      ),
                    ),
                    subtitle: _ThemeColorPreview(colors: itemTheme.tetrominoColors.values.toList()),
                    trailing: itemTheme.isPremium
                        ? const Icon(Icons.lock, color: Colors.amber)
                        : isSelected
                            ? Icon(Icons.check_circle, color: theme.accentColor)
                            : const Icon(Icons.chevron_right, color: Colors.white54),
                  ),
                );
              },
            ),
    );
  }
}

/// Mały widget pokazujący podgląd kolorów motywu.
class _ThemeColorPreview extends StatelessWidget {
  final List<Color> colors;
  const _ThemeColorPreview({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: colors.map((color) {
          return Expanded(
            child: Container(
              height: 10,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Okno dialogowe do podglądu i wyboru motywu.
class _ThemePreviewDialog extends StatefulWidget {
  final GameTheme theme;
  final VoidCallback onSelect;

  const _ThemePreviewDialog({required this.theme, required this.onSelect});

  @override
  State<_ThemePreviewDialog> createState() => _ThemePreviewDialogState();
}

class _ThemePreviewDialogState extends State<_ThemePreviewDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: widget.theme.accentColor, width: 2),
      ),
      title: Text(
        widget.theme.name,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Podgląd animowanego tła
          SizedBox(
            width: worldSize.x,
            height: worldSize.y * 0.6, // Pokaż większą część planszy
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: GameWidget(
                // Tworzymy mini-instancję gry tylko do podglądu tła
                game: _ThemePreviewGame(widget.theme),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // --- DODANO: Rząd "oddychających" klocków ---
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: widget.theme.tetrominoColors.entries.map((entry) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(
                      parent: _animationController, curve: Curves.easeInOut),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CustomPaint(
                    painter: _TetrominoPainter(
                      shape: tetrominoShapes[entry.key]!,
                      color: entry.value,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (widget.theme.isPremium)
          ElevatedButton.icon(
            onPressed: () {
              // Logika zakupu w przyszłości
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            icon: const Icon(Icons.lock_open, color: Colors.black),
            label: const Text(
              'Unlock',
              style: TextStyle(fontFamily: 'PressStart2P', color: Colors.black),
            ),
          )
        else
          ElevatedButton(
            onPressed: widget.onSelect,
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.accentColor),
            child: const Text(
              'Select',
              style: TextStyle(fontFamily: 'PressStart2P', color: Colors.black),
            ),
          ),
      ],
    );
  }
}

/// Painter do rysowania pojedynczego, wyśrodkowanego tetromino.
class _TetrominoPainter extends CustomPainter {
  final List<Vector2> shape;
  final Color color;

  _TetrominoPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double miniTileSize = 8.0;

    // Znajdź środek kształtu, aby go wycentrować
    double minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (var p in shape) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
    }
    final shapeWidth = (maxX - minX + 1) * miniTileSize;
    final shapeHeight = (maxY - minY + 1) * miniTileSize;

    for (final offset in shape) {
      final x =
          (size.width - shapeWidth) / 2 + (offset.x - minX) * miniTileSize;
      final y =
          (size.height - shapeHeight) / 2 + (offset.y - minY) * miniTileSize;
      canvas.drawRect(Rect.fromLTWH(x, y, miniTileSize, miniTileSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Minimalna instancja gry Flame, która renderuje tylko animowane tło.
class _ThemePreviewGame extends FlameGame {
  final GameTheme theme;

  _ThemePreviewGame(this.theme);

  @override
  Color backgroundColor() => theme.backgroundColor;

  @override
  Future<void> onLoad() async {
    // Musimy stworzyć fałszywą klasę `TetrisGame`, aby `ModernBackgroundComponent`
    // miał dostęp do `game.currentTheme`.
    final fakeGame = TetrisGame()..currentTheme = theme;
    
    // Używamy `preAdd` aby upewnić się, że `game` jest dostępne w `onLoad` tła.
    await addAll([
      ModernBackgroundComponent()..game = fakeGame,
      GridBackground()..game = fakeGame,
      _FallingTetrominoPreview(theme),
    ]);
  }
}

/// Reprezentuje pojedyncze, spadające tetromino w podglądzie.
class _FallingTetromino {
  Vector2 position;
  List<Vector2> shape;
  final Color color;
  double speed;

  _FallingTetromino(
      {required this.position, required this.shape, required this.color, required this.speed});
}

/// Komponent symulujący spadające tetromino dla podglądu motywu.
class _FallingTetrominoPreview extends PositionComponent {
  final GameTheme theme;
  final Random _random = Random();
  final List<_FallingTetromino> _tetrominoes = [];
  final int _laneCount = 5; // Liczba "torów", po których spadają klocki

  _FallingTetrominoPreview(this.theme);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = worldSize;

    // Stwórz początkowe tetromino w losowych pozycjach na swoich torach
    for (int i = 0; i < _laneCount; i++) {
      _tetrominoes.add(_createNewTetromino(laneIndex: i, isInitial: true));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (int i = 0; i < _tetrominoes.length; i++) {
      final tetromino = _tetrominoes[i];
      tetromino.position.y += tetromino.speed * dt;
      // Jeśli klocek wyleci poza ekran, zresetuj go na górze na tym samym torze
      if (tetromino.position.y > size.y) {
        _tetrominoes[i] = _createNewTetromino(laneIndex: i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint();
    for (final tetromino in _tetrominoes) {
      paint.color = tetromino.color;
      for (final offset in tetromino.shape) {
        final pos = tetromino.position + offset * tileSize;
        canvas.drawRect(Rect.fromLTWH(pos.x, pos.y, tileSize, tileSize), paint);
      }
    }
  }

  /// Tworzy nowe, losowe tetromino na określonym torze.
  _FallingTetromino _createNewTetromino({required int laneIndex, bool isInitial = false}) {
    final types = theme.tetrominoColors.keys.toList();
    final type = types[_random.nextInt(types.length)];
    final laneWidth = size.x / _laneCount;

    return _FallingTetromino(
      position: Vector2(
        laneIndex * laneWidth + (laneWidth / 2) - (tileSize * 1.5), // Wyśrodkuj na torze
        isInitial ? _random.nextDouble() * size.y : -tileSize * 4, // Zacznij nad ekranem
      ),
      shape: tetrominoShapes[type]!,
      color: theme.tetrominoColors[type]!,
      speed: _random.nextDouble() * 50 + 40, // Losowa prędkość
    );
  }
}