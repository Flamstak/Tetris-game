// Plik: game_screen.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'tetris_game.dart';
import 'tetromino_data.dart';
import 'ui_helpers.dart'; 

/// Widget hostujący instancję gry Tetris i powiązany z nią interfejs Flutter.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TetrisGame game;

  @override
  void initState() {
    super.initState();
    game = TetrisGame();
  }

  // --- NOWA METODA OBSŁUGI COFANIA ---
  Future<bool> _onWillPop() async {
    // 1. Najpierw pauzujemy grę
    game.pauseGame();

    // 2. Pokazujemy dialog potwierdzenia
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Użytkownik musi wybrać przycisk
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: Colors.blue.shade900.withAlpha(128),
            width: 2.0,
          ),
        ),
        title: const Text(
          'Exit Game?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Are you sure you want to quit?\nYour progress will be lost.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            color: Colors.white70,
            fontSize: 10,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // Przycisk NIE (Zostań w grze)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'NO',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          // Przycisk TAK (Wyjdź)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'YES',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.redAccent.shade200, // Czerwony dla ostrzeżenia
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    // 3. Obsługa decyzji
    if (shouldQuit == true) {
      return true; // Pozwól systemowi zamknąć ekran (wróć do menu)
    } else {
      // Jeśli użytkownik anulował wyjście, wznów grę
      game.resumeGame();
      return false; // Zablokuj wyjście
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Używamy WillPopScope z naszą nową metodą _onWillPop
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          final NavigatorState navigator = Navigator.of(context);
          if (await _onWillPop()) {
            navigator.pop();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Górny Pasek UI ---
              SizedBox(
                width: worldSize.x,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 'Hold' Box
                    Flexible(
                      flex: 1,
                      child: HoldPieceBox(listenable: game.heldTetrominoType, theme: game.currentTheme),
                    ),
                    const SizedBox(width: 10),
                    // 2. Kolumna Wyniku i Poziomu
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.8),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)),
                          border: Border.all(
                            color: Colors.blue.shade900.withAlpha(128),
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 2a. WYNIK
                            ValueListenableBuilder<int>(
                              valueListenable: game.score,
                              builder: (context, value, child) {
                                return Text(
                                  'Score: $value',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // 2b. POZIOM
                            ValueListenableBuilder<int>(
                              valueListenable: game.level,
                              builder: (context, value, child) {
                                return Text(
                                  'Level: $value',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 3. Kolumna 'Next' i Ustawień
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 3a. 'Next' Box
                          NextPieceBox(listenable: game.nextTetrominoType, theme: game.currentTheme),
                          // 3b. Przycisk Ustawień
                          const SizedBox(height: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white70,
                              size: 30,
                            ),
                            onPressed: () {
                              _showSettingsDialog(context, game);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Odstęp
              // --- Widżet Gry ---
              SizedBox(
                width: worldSize.x,
                height: worldSize.y,
                child: GameWidget(game: game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- (Funkcja _showSettingsDialog pozostaje bez zmian - skopiuj ją z poprzedniej wersji pliku) ---
void _showSettingsDialog(BuildContext context, TetrisGame game) {
  // Pauzuj grę PRZED otwarciem dialogu
  game.pauseGame();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side:
              BorderSide(color: Colors.blue.shade900.withAlpha(128), width: 2.0),
        ),
        title: const Text(
          'Paused',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Audio & Haptics',
                  style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.white70,
                      fontSize: 14),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isMusicEnabled,
                        builder: (context, isEnabled, child) {
                          return InkWell(
                            onTap: () => game.toggleMusic(),
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEnabled
                                        ? Icons.music_note
                                        : Icons.music_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Music',
                                    style: TextStyle(
                                      fontFamily: 'PressStart2P',
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isSfxEnabled,
                        builder: (context, isEnabled, child) {
                          return InkWell(
                            onTap: () => game.toggleSfx(),
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEnabled
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'SFX',
                                    style: TextStyle(
                                      fontFamily: 'PressStart2P',
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isHapticsEnabled,
                        builder: (context, isEnabled, child) {
                          return InkWell(
                            onTap: () => game.toggleHaptics(),
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEnabled
                                        ? Icons.vibration
                                        : Icons.phone_android,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Haptics',
                                    style: TextStyle(
                                      fontFamily: 'PressStart2P',
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                const Text(
                  'How to Play',
                  style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.white70,
                      fontSize: 14),
                ),
                const SizedBox(height: 15),
                const InstructionRow(
                  icon: Icons.touch_app_outlined,
                  action: 'Rotate',
                  description: 'Tap anywhere',
                ),
                const InstructionRow(
                  icon: Icons.arrow_right_alt,
                  action: 'Move',
                  description: 'Drag left or right',
                ),
                const InstructionRow(
                  icon: Icons.arrow_downward,
                  action: 'Soft Drop',
                  description: 'Drag down',
                ),
                const InstructionRow(
                  icon: Icons.back_hand_outlined,
                  action: 'Hold',
                  description: 'Press and hold',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Close',
              style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.blueAccent,
                  fontSize: 12),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  ).then((_) {
    game.resumeGame();
  });
}