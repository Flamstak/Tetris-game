// Plik: tetris_game.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
// --- DODANO IMPORT DLA HAPTYKI ---
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'dart:async';
import 'dart:math';
// import 'package:shared_preferences/shared_preferences.dart'; // <-- USUNIĘTE, teraz w SettingsManager
import 'package:flame_audio/flame_audio.dart';

// --- DODANO IMPORT DLA MOCNYCH WIBRACJI ---
import 'package:vibration/vibration.dart';

// --- DODANO IMPORT DLA MANAGERA USTAWIEŃ ---
import 'settings_manager.dart';

import 'tetromino_data.dart';
import 'tetromino_component.dart';
import 'landed_tiles_component.dart';
import 'game_over_menu.dart';

/// Reprezentuje możliwe stany logiki gry.
enum GameState {
  /// Tetromino spada, użytkownik ma kontrolę.
  playing,

  /// Trwa animacja czyszczenia linii.
  lineClearing,

  /// Tworzone jest nowe tetromino.
  spawning,

  /// Koniec gry, wyświetlane jest menu z wynikiem.
  gameOver,

  /// Gra jest ręcznie zapauzowana (np. w menu ustawień).
  paused
}

// --- DODANO ENUM HAPTYKI ---
/// Definiuje typy haptyki dla różnych zdarzeń w grze.
enum HapticType {
  rotate, // Obrót
  move, // Przesunięcie
  land, // Lądowanie
  hold, // Przechowanie
  lineClear, // Czyszczenie linii
  gameOver, // Koniec gry
}

/// Główna klasa gry Tetris, zbudowana przy użyciu Flame.
///
/// Zarządza stanem gry, pętlą aktualizacji, wejściem użytkownika,
/// punktacją, dźwiękiem i wszystkimi komponentami gry.
class TetrisGame extends FlameGame
    with DragCallbacks, TapCallbacks, DoubleTapCallbacks, WidgetsBindingObserver {
  /// Obecny logiczny stan gry.
  var gameState = GameState.spawning;

  /// Przechowuje [gameState] sprzed pauzy.
  GameState? _previousState;

  /// Czasomierz dla animacji czyszczenia linii.
  double lineClearTimer = 0.0;

  /// Całkowity czas trwania animacji czyszczenia linii.
  final double lineClearAnimationDuration = 0.5;

  /// Lista indeksów rzędów (Y), które są pełne i czekają na usunięcie.
  List<int> linesToClear = [];

  /// Obecnie aktywne, kontrolowane przez gracza tetromino.
  late TetrominoComponent currentTetromino;

  /// Podstawowy czas (w sekundach) spadania klocka o jeden kafelek.
  /// Wartość ta maleje wraz ze wzrostem poziomu.
  double fallSpeed = 0.8;

  /// Akumulator dla czasomierza spadania, resetowany po każdym opadnięciu kafelka.
  double fallTimer = 0.0;

  /// Akumuluje dystans przeciągnięcia w poziomie, aby określić ruch o kafelek.
  double _dragAccumulatedX = 0.0;

  /// Akumuluje dystans przeciągnięcia w pionie dla miękkiego opadania (soft drop).
  double _dragAccumulatedY = 0.0;

  /// ID wskaźnika dla głównego zdarzenia przeciągania (zapobiega konfliktom wielodotyku).
  int? _dragPointerId;

  /// Logiczna siatka 2D reprezentująca wszystkie wylądowane kafelki.
  /// `null` oznacza pustą komórkę.
  late List<List<Color?>> grid;

  /// Notifier dla obecnego wyniku gracza.
  final ValueNotifier<int> score = ValueNotifier(0);

  /// Notifier dla obecnego poziomu gracza.
  final ValueNotifier<int> level = ValueNotifier(1);

  /// Całkowita liczba linii wyczyszczonych w bieżącej grze.
  int totalLinesCleared = 0;

  /// Liczba linii wymagana do awansu na kolejny poziom.
  static const int linesPerLevel = 10;

  /// Lista 5 najlepszych wyników, ładowana z [SettingsManager].
  /// Wciąż tu przechowywana na potrzeby menu GameOver.
  List<int> highScores = [];

  /// Notifier dla typu *następnego* tetromino (dla pola podglądu).
  final ValueNotifier<String> nextTetrominoType = ValueNotifier('');

  /// Notifier dla typu *przechowywanego* tetromino (dla pola "Hold").
  final ValueNotifier<String?> heldTetrominoType = ValueNotifier(null);

  /// Flaga kontrolująca, czy akcja "Hold" jest dostępna (resetowana przy spawnie nowego klocka).
  bool _canHold = true;

  /// Notifier dla ustawienia włączenia/wyłączenia muzyki.
  final ValueNotifier<bool> isMusicEnabled = ValueNotifier(true);

  /// Notifier dla ustawienia włączenia/wyłączenia efektów dźwiękowych (SFX).
  final ValueNotifier<bool> isSfxEnabled = ValueNotifier(true);

  /// Notifier dla ustawienia włączenia/wyłączenia wibracji (haptyki).
  final ValueNotifier<bool> isHapticsEnabled = ValueNotifier(true);

  /// Zwraca losowy typ tetromino (np. 'I', 'L') z mapy kształtów.
  String _getRandomTetrominoType() {
    final keys = tetrominoShapes.keys.toList();
    return (keys..shuffle()).first;
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0A23);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Ustawienia kamery i viewportu
    camera.viewport = FixedResolutionViewport(resolution: worldSize);
    camera.viewfinder.position = worldSize / 2;
    camera.viewfinder.anchor = Anchor.center;

    // Wstępne ładowanie wszystkich zasobów audio
    await FlameAudio.audioCache.loadAll([
      'theme.mp3',
      'rotate.wav',
      'land.wav',
      'clear_line.mp3',
      'game_over.mp3',
    ]);

    // Inicjalizacja logicznej siatki
    grid = List.generate(columns, (_) => List.filled(rows, null));

    // Dodanie komponentów tła
    add(GradientBackgroundComponent());
    add(GridBackground());

    // Dodanie komponentu odpowiedzialnego za renderowanie siatki
    add(LandedTilesComponent());

    // --- ZAKTUALIZOWANE ŁADOWANIE DANYCH ---
    // Ładowanie trwałych danych przez SettingsManager
    await _loadAllSettingsFromManager();

    // Ustawienie "następnego" klocka
    nextTetrominoType.value = _getRandomTetrominoType();

    // Rozpoczęcie gry przez stworzenie pierwszego klocka
    spawnNewTetromino();

    // Uruchomienie muzyki w tle, jeśli włączona
    if (isMusicEnabled.value) {
      FlameAudio.bgm.play('theme.mp3');
    }

    // Rejestracja obserwatora cyklu życia aplikacji
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onRemove() {
    // Wyrejestrowanie obserwatora cyklu życia
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  /// Tworzy nowe [TetrominoComponent] na podstawie [nextTetrominoType].
  void spawnNewTetromino() {
    final String currentType = nextTetrominoType.value;
    final shape = List<Vector2>.from(tetrominoShapes[currentType]!);
    final color = tetrominoColors[currentType]!;
    final startPos = Vector2(4, 1); // Start blisko góry i środka

    // Sprawdzenie "Block Out" (Game Over)
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

    _canHold = true; // Zezwól na przechowanie tego nowego klocka
    nextTetrominoType.value = _getRandomTetrominoType(); // Ustaw następny klocek

    // --- POPRAWKA BLOKOWANIA ---
    // Natychmiast ustawiamy stan 'playing', aby odblokować sterowanie.
    gameState = GameState.playing;
  }

  /// Tworzy konkretny [TetrominoComponent] według [type].
  /// Używane podczas zamiany klocka z pola "Hold".
  void spawnSpecificTetromino(String type) {
    final shape = List<Vector2>.from(tetrominoShapes[type]!);
    final color = tetrominoColors[type]!;
    final startPos = Vector2(4, 1);

    // Sprawdzenie "Block Out" (Game Over)
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
    _canHold = true; // Zawsze zezwalaj na "Hold" po spawnie (choć tu rzadko używane)

    // --- POPRAWKA BLOKOWANIA ---
    // Natychmiast ustawiamy stan 'playing', tak jak w 'spawnNewTetromino'.
    gameState = GameState.playing;
  }

  /// Logika akcji "Hold" (przechowania klocka).
  void holdTetromino() {
    if (!_canHold || gameState != GameState.playing) return;

    // --- DODANO HAPTYKĘ ---
    triggerHaptics(HapticType.hold);
    _canHold = false;
    final String typeToHold = currentTetromino.tetrominoType;
    remove(currentTetromino); // Usuń obecny klocek z gry

    final String? previouslyHeldType = heldTetrominoType.value;

    gameState = GameState.spawning; // Zmień stan, aby zapobiec konfliktom
    _dragPointerId = null; // Zresetuj przeciąganie

    if (previouslyHeldType == null) {
      // Jeśli "Hold" jest pusty, schowaj tam obecny klocek i stwórz nowy
      heldTetrominoType.value = typeToHold;
      spawnNewTetromino();
    } else {
      // Jeśli "Hold" coś zawiera, zamień klocki
      heldTetrominoType.value = typeToHold;
      spawnSpecificTetromino(previouslyHeldType);
    }
  }

  /// Obsługa długiego naciśnięcia (wywołuje "Hold").
  @override
  void onLongTapDown(TapDownEvent event) {
    if (gameState != GameState.playing) return;
    holdTetromino();
    super.onLongTapDown(event);
  }

  /// Rozpoczyna śledzenie przeciągania.
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

  /// Aktualizuje pozycję klocka na podstawie przeciągania.
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState != GameState.playing) return;
    // Upewnij się, że mamy ID wskaźnika
    if (_dragPointerId == null) {
      _dragPointerId = event.pointerId;
      _dragAccumulatedX = 0.0;
      _dragAccumulatedY = 0.0;
    }

    // Przetwarzaj tylko zdarzenie od głównego wskaźnika
    if (event.pointerId == _dragPointerId) {
      _dragAccumulatedX += event.canvasDelta.x;
      // Akumuluj only ruch w dół (dla soft drop)
      if (event.canvasDelta.y > 0) _dragAccumulatedY += event.canvasDelta.y;

      // Przesunięcie w poziomie
      if (_dragAccumulatedX.abs() > tileSize * 1.5) {
        final direction = _dragAccumulatedX > 0 ? 1 : -1;
        currentTetromino.tryMove(Vector2(direction.toDouble(), 0));

        // --- DODANO HAPTYKĘ ---
        triggerHaptics(HapticType.move);
        _dragAccumulatedX = 0.0; // Resetuj akumulator
      }

      // Przesunięcie w pionie (soft drop)
      if (_dragAccumulatedY > tileSize) {
        currentTetromino.tryMove(Vector2(0, 1));
        fallTimer = 0.0; // Resetuj timer grawitacji
        _dragAccumulatedY = 0.0; // Resetuj akumulator
      }
    }
    super.onDragUpdate(event);
  }

  /// Kończy przeciąganie, resetuje stan.
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

  /// Anuluje przeciąganie, resetuje stan.
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

  /// Obsługa dotknięcia (obraca klocek).
  @override
  void onTapUp(TapUpEvent event) {
    if (gameState == GameState.gameOver) {
      // Jeśli gra się skończyła, dotknięcie restartuje grę
      restartGame();
      return;
    }
    if (gameState != GameState.playing) return;

    // Logika haptyki dla obrotu znajduje się w
    // `tetromino_component.dart` w metodzie `rotate()`,
    // ponieważ only komponent wie, czy obrót się powiódł.
    currentTetromino.rotate();
    super.onTapUp(event);
  }

  /// Obsługuje zdarzenia cyklu życia aplikacji (np. minimalizowanie).
  /// Służy do automatycznego pauzowania/wznawiania muzyki w tle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Wznów muzykę only jeśli jest włączona, gra nie jest skończona,
        // ORAZ jeśli nie jesteśmy ręcznie spauzowani (w menu)
        if (isMusicEnabled.value &&
            gameState != GameState.gameOver &&
            gameState != GameState.paused) {
          FlameAudio.bgm.resume();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Zawsze pauzuj muzykę, gdy aplikacja traci fokus
        FlameAudio.bgm.pause();
        break;
    }
  }

  /// Sprawdza, czy dana pozycja i kształt są prawidłowe.
  /// (nie kolidują z wylądowanymi klockami i mieszczą się w granicach).
  bool isValidPosition(Vector2 tetrominoPos, List<Vector2> shape) {
    for (final offset in shape) {
      final tilePos = tetrominoPos + offset;
      final x = tilePos.x.toInt();
      final y = tilePos.y.toInt();

      // Sprawdzenie granic poziomych i dolnej granicy
      if (x < 0 || x >= columns || y >= rows) return false;

      // Sprawdzenie kolizji z siatką (tylko dla kafelków wewnątrz siatki, y >= 0)
      if (y >= 0) {
        if (grid[x][y] != null) return false;
      }
    }
    return true;
  }

  /// "Ląduje" klockiem - przenosi jego kafelki do logicznej siatki [grid].
  void landTetromino(TetrominoComponent tetromino) {
    if (isSfxEnabled.value) {
      FlameAudio.play('land.wav');
    }
    // --- DODANO HAPTYKĘ ---
    triggerHaptics(HapticType.land);

    // Przenieś kafelki z komponentu do siatki logicznej
    for (final tile in tetromino.tiles) {
      final x = tile.gridPosition.x.toInt();
      final y = tile.gridPosition.y.toInt();
      if (x >= 0 && x < columns && y >= 0 && y < rows) {
        grid[x][y] = tile.color;
      }
    }
    remove(tetromino); // Usuń komponent klocka z gry
    checkAndClearLines(); // Sprawdź, czy jakaś linia została ukończona
  }

  /// Sprawdza, czy któreś linie są pełne i inicjuje ich czyszczenie.
  void checkAndClearLines() {
    List<int> fullLines = [];
    int y = rows - 1; // Zaczynamy sprawdzanie od dołu

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
      if (isSfxEnabled.value) {
        FlameAudio.play('clear_line.mp3');
      }
      // --- DODANO HAPTYKĘ ---
      triggerHaptics(HapticType.lineClear);

      gameState = GameState.lineClearing;
      _dragPointerId = null; // Zablokuj sterowanie
      linesToClear.addAll(fullLines);
      lineClearTimer = 0.0;

      // Powiadom komponent siatki, aby rozpoczął animację
      children
          .whereType<LandedTilesComponent>()
          .first
          .startAnimation(linesToClear);
    } else if (gameState == GameState.playing) {
      // Jeśli nie ma linii do czyszczenia, od razu stwórz nowy klocek
      gameState = GameState.spawning;
      _dragPointerId = null;
      spawnNewTetromino();
    }
  }

  /// Usuwa jeden rząd (o indeksie [y]) z logicznej siatki
  /// i przesuwa wszystko powyżej w dół.
  void clearLogicalLine(int y) {
    // Przesuń wszystkie rzędy powyżej 'y' o jeden w dół
    for (int r = y; r > 0; r--) {
      for (int c = 0; c < columns; c++) {
        grid[c][r] = grid[c][r - 1];
      }
    }
    // Wyczyść górny rząd
    for (int c = 0; c < columns; c++) {
      grid[c][0] = null;
    }
  }

  /// Dodaje punkty za wyczyszczone linie i zarządza awansem na wyższy poziom.
  void addScore(int linesCleared) {
    int points = 0;
    // Punktacja Tetrisa (uproszczona)
    if (linesCleared == 1) {
      points = 100 * level.value; // Single
    } else if (linesCleared == 2) {
      points = 300 * level.value; // Double
    } else if (linesCleared == 3) {
      points = 500 * level.value; // Triple
    } else if (linesCleared >= 4) {
      points = 800 * level.value; // Tetris!
    }
    score.value += points;

    // Logika poziomów
    totalLinesCleared += linesCleared;
    if (totalLinesCleared >= (level.value * linesPerLevel)) {
      level.value++;
      // Zwiększ prędkość spadania
      double newSpeed = 0.8 - (level.value - 1) * 0.05;
      fallSpeed = max(0.1, newSpeed); // Ustal minimalną prędkość
    }
  }

  /// Główna pętla gry, wywoływana co klatkę.
  @override
  void update(double dt) {
    super.update(dt);

    // Maszyna stanów gry
    switch (gameState) {
      case GameState.playing:
        // Grawitacja
        fallTimer += dt;
        if (fallTimer >= fallSpeed) {
          currentTetromino.tryMove(Vector2(0, 1)); // Przesuń w dół
          fallTimer = 0.0; // Zresetuj timer
        }
        break;
      case GameState.lineClearing:
        // Animacja czyszczenia linii
        lineClearTimer += dt;
        // Aktualizuj postęp animacji w komponencie siatki
        children.whereType<LandedTilesComponent>().first.animationProgress =
            lineClearTimer / lineClearAnimationDuration;

        if (lineClearTimer >= lineClearAnimationDuration) {
          _finishLineClear(); // Zakończ czyszczenie
        }
        break;
      case GameState.spawning:
      // Nic nie rób, stan jest już ustawiony na 'playing' w 'spawnNewTetromino'
      case GameState.gameOver:
      // Nic nie rób, czekaj na restart
      case GameState.paused:
        // Nic nie rób, czekaj na wznowienie
        break;
    }
  }

  /// Kończy proces czyszczenia linii (po animacji).
  void _finishLineClear() {
    // Usuń linie z siatki logicznej (w odwrotnej kolejności, aby uniknąć błędów indeksowania)
    for (final y in linesToClear.reversed) {
      clearLogicalLine(y);
    }
    addScore(linesToClear.length); // Dodaj punkty

    linesToClear.clear();
    lineClearTimer = 0;

    // Zakończ animację w komponencie siatki
    children.whereType<LandedTilesComponent>().first.stopAnimation();

    // Stwórz nowy klocek
    gameState = GameState.spawning;
    spawnNewTetromino();
  }

  /// Inicjuje stan końca gry.
  Future<void> gameOver() async {
    // 1. NATYCHMIAST ustaw stan, aby zatrzymać pętlę 'update' i sterowanie
    gameState = GameState.gameOver;
    _dragPointerId = null;

    // 2. Odpal wibracje "w tle" (BEZ 'await')
    triggerHaptics(HapticType.gameOver);

    // 3. Zatrzymaj muzykę w tle
    FlameAudio.bgm.stop();

    // 4. --- ZAKTUALIZOWANY ZAPIS WYNIKU ---
    // ZAPISZ WYNIK. Użyj SettingsManager do zapisu i pobierz zaktualizowaną listę
    highScores = await SettingsManager.saveNewHighScore(score.value);

    // 5. DOPIERO TERAZ odtwórz dźwięk "Game Over".
    if (isSfxEnabled.value) {
      FlameAudio.play('game_over.mp3');
    }

    // 6. Pokaż menu
    final menu = GameOverMenuComponent(
      score: score.value,
      highScores: highScores, // Przekaż zaktualizowaną listę
    );
    add(menu);
  }

  /// Resetuje wszystkie stany gry do wartości początkowych.
  void restartGame() {
    // Wyczyść siatkę logiczną
    grid = List.generate(columns, (_) => List.filled(rows, null));

    // Usuń menu i wszystkie pozostałe klocki
    removeAll(children.whereType<GameOverMenuComponent>());
    removeAll(children.whereType<TetrominoComponent>());

    // Zresetuj statystyki
    score.value = 0;
    level.value = 1;
    totalLinesCleared = 0;
    fallSpeed = 0.8;

    // Zresetuj stan gry
    gameState = GameState.spawning;
    heldTetrominoType.value = null;
    _canHold = true;
    _dragPointerId = null;

    // Przygotuj nowy zestaw klocków
    nextTetrominoType.value = _getRandomTetrominoType();
    spawnNewTetromino();

    // Uruchom ponownie muzykę
    FlameAudio.bgm.stop();
    if (isMusicEnabled.value) {
      FlameAudio.bgm.play('theme.mp3');
    }
  }

  // --- Zarządzanie Trwałymi Danymi (przez SettingsManager) ---

  /// NOWA METODA: Wczytuje wszystkie ustawienia przy starcie gry
  Future<void> _loadAllSettingsFromManager() async {
    isMusicEnabled.value = await SettingsManager.loadMusicSetting();
    isSfxEnabled.value = await SettingsManager.loadSfxSetting();
    isHapticsEnabled.value = await SettingsManager.loadHapticsSetting();
    highScores = await SettingsManager.loadHighScores(); // Potrzebne do menu GameOver
  }

  // --- USUNIĘTE METODY ZARZĄDZANIA SHPREFS ---
  // usunięto: _loadHighScores()
  // usunięto: _updateAndSaveHighScores()
  // usunięto: _loadSettings()
  // usunięto: _saveSettings()
  // -------------------------------------------

  /// Przełącza stan muzyki (wł./wył.).
  void toggleMusic() {
    isMusicEnabled.value = !isMusicEnabled.value;
    if (isMusicEnabled.value) {
      // Odtwórz tylko, jeśli gra nie jest skończona
      if (gameState != GameState.gameOver) {
        FlameAudio.bgm.play('theme.mp3');
      }
    } else {
      FlameAudio.bgm.stop();
    }
    // ZAKTUALIZOWANE: Zapisz przez Managera
    SettingsManager.saveMusicSetting(isMusicEnabled.value);
  }

  /// Przełącza stan efektów dźwiękowych (wł./wył.).
  void toggleSfx() {
    isSfxEnabled.value = !isSfxEnabled.value;
    // ZAKTUALIZOWANE: Zapisz przez Managera
    SettingsManager.saveSfxSetting(isSfxEnabled.value);
  }

  /// Przełącza stan wibracji (wł./wył.).
  void toggleHaptics() {
    isHapticsEnabled.value = !isHapticsEnabled.value;
    // ZAKTUALIZOWANE: Zapisz przez Managera
    SettingsManager.saveHapticsSetting(isHapticsEnabled.value);
  }

  // --- Zarządzanie Stanem Pauzy ---

  /// Pauzuje grę, zapamiętując poprzedni stan.
  void pauseGame() {
    // Nie pauzuj, jeśli już jest zapauzowana lub gra się skończyła
    if (gameState == GameState.paused || gameState == GameState.gameOver) return;

    _previousState = gameState;
    gameState = GameState.paused;

    // Zatrzymaj też muzykę BGM podczas pauzy
    FlameAudio.bgm.pause();
  }

  /// Wznawia grę ze stanu pauzy.
  void resumeGame() {
    if (gameState != GameState.paused) return; // Wznów only, jeśli była pauza

    // Wróć do poprzedniego stanu (lub domyślnego 'spawning', jeśli coś poszło nie tak)
    gameState = _previousState ?? GameState.spawning;
    _previousState = null;

    // Wznów muzykę, jeśli jest włączona i gra nie jest skończona
    if (isMusicEnabled.value && gameState != GameState.gameOver) {
      FlameAudio.bgm.resume();
    }
  }

  // --- ZAKTUALIZOWANA METODA HAPTYKI (Wersja Hybrydowa) ---
  /// Wywołuje określony typ wibracji (haptyki).
  Future<void> triggerHaptics(HapticType type) async {
    // Jeśli haptyka jest wyłączona, przerwij.
    if (!isHapticsEnabled.value) return;

    // --- NOWA LOGIKA DLA GAME OVER ---
    // Dla Game Over używamy potężnego pakietu 'vibration',
    // aby stworzyć własny, mocny wzorzec "buzz".
    if (type == HapticType.gameOver) {
      // Sprawdź, czy urządzenie w ogóle ma wibracje
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) { // Użyj ?? false dla bezpieczeństwa
        Vibration.vibrate(pattern: [0, 150, 350, 150, 350, 800]);
      }
      // Ważne: Zakończ funkcję tutaj, aby nie przechodzić do 'switch'
      return;
    }
    
    // --- STARA LOGIKA DLA SZYBKICH AKCJI ---
    // Dla wszystkich innych akcji (ruch, obrót) używamy 'HapticFeedback',
    // ponieważ daje on natychmiastowe "kliknięcie", a nie "bzyczenie".
    switch (type) {
      case HapticType.rotate:
      case HapticType.move:
      case HapticType.hold:
        HapticFeedback.selectionClick();
        break;
      case HapticType.land:
        HapticFeedback.lightImpact();
        break;
      case HapticType.lineClear:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.gameOver:
        // Ten przypadek jest już obsłużony powyżej,
        // ale musi tu być, aby 'switch' był poprawny.
        break;
    }
  }
} // --- Koniec klasy TetrisGame ---

// --- Komponenty Tła ---

/// Prosty komponent rysujący gradient jako tło gry.
class GradientBackgroundComponent extends PositionComponent
    with HasGameReference<TetrisGame> {
  GradientBackgroundComponent() {
    size = worldSize; // Rozmiar tła równy światu gry
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0A23), // Ciemnoniebieski
        Colors.black, // Czarny
      ],
    );
    final paint = Paint()..shader = gradient.createShader(size.toRect());
    canvas.drawRect(size.toRect(), paint);
  }
}

/// Prosty komponent rysujący siatkę w tle.
class GridBackground extends PositionComponent {
  GridBackground() {
    size = worldSize;
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = Colors.blue.shade900.withAlpha(128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Linie pionowe
    for (var x = 0.0; x <= size.x; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    // Linie poziome
    for (var y = 0.0; y <= size.y; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }
}