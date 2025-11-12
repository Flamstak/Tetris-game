import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart';
import 'tetromino_data.dart'; // Import dla 'worldSize' i 'tetrominoColors'

/// Główna funkcja aplikacji.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final game = TetrisGame();

  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Builder(builder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Górny Pasek UI (Wynik, Poziom, Hold, Next) ---
                SizedBox(
                  width: worldSize.x, // Dopasuj szerokość do planszy gry
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 'Hold' Box
                      Flexible(
                        flex: 1,
                        child: HoldPieceBox(listenable: game.heldTetrominoType),
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
                            NextPieceBox(listenable: game.nextTetrominoType),

                            // 3b. Przycisk Ustawień
                            const SizedBox(height: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white70,
                                size: 30,
                              ),
                              onPressed: () {
                                // Wywołaj okienko dialogowe z logiką pauzy
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
          );
        }),
      ),
    ),
  );
}

/// Funkcja pomocnicza wyświetlająca modalne okno dialogowe ustawień.
/// Zarządza pauzowaniem i wznawianiem gry.
void _showSettingsDialog(BuildContext context, TetrisGame game) {
  // Pauzuj grę PRZED otwarciem dialogu
  game.pauseGame();

  showDialog(
    context: context,
    // Nie pozwala zamknąć dialogu kliknięciem obok
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
          'Paused', // Zmieniono tytuł na "Pauza"
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: Container(
          width: double.maxFinite, // Dopasuj do szerokości okna
          child: SingleChildScrollView(
            // Aby można było przewijać
            child: ListBody(
              // Używamy ListBody zamiast Column
              children: <Widget>[
                // --- Sekcja Audio (ze zmianą) ---
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
                    // Użyj 'spaceAround', aby dać przyciskom więcej miejsca
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start, // Wyrównaj do góry
                    children: [
                      // --- 1. ZMIANA: Przycisk Muzyki (Icon + Text) ---
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isMusicEnabled,
                        builder: (context, isEnabled, child) {
                          // Używamy InkWell (dla kliknięcia) + Column (dla układu)
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
                      // --- 2. ZMIANA: Przycisk SFX (Icon + Text) ---
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
                      // --- 3. ZMIANA: Przycisk Haptyki (Icon + Text) ---
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

                // --- SEKCJA INSTRUKCJI (bez zmian) ---
                const Text(
                  'How to Play',
                  style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.white70,
                      fontSize: 14),
                ),
                const SizedBox(height: 15),
                _InstructionRow(
                  icon: Icons.touch_app_outlined,
                  action: 'Rotate',
                  description: 'Tap anywhere',
                ),
                _InstructionRow(
                  icon: Icons.arrow_right_alt,
                  action: 'Move',
                  description: 'Drag left or right',
                ),
                _InstructionRow(
                  icon: Icons.arrow_downward,
                  action: 'Soft Drop',
                  description: 'Drag down',
                ),
                _InstructionRow(
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
              Navigator.of(dialogContext).pop(); // Zamknij dialog
            },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  ).then((_) {
    // `.then` wykonuje się PO zamknięciu dialogu
    // Wznów grę
    game.resumeGame();
  });
}

// --- WIDŻET POMOCNICZY DLA INSTRUKCJI (bez zmian) ---
class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String action;
  final String description;

  const _InstructionRow({
    required this.icon,
    required this.action,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Widżety Hold i Next (BEZ ZMIAN) ---
class HoldPieceBox extends StatelessWidget {
  final ValueNotifier<String?> listenable;
  const HoldPieceBox({super.key, required this.listenable});

  @override
  Widget build(BuildContext context) {
    const int gridDimension = 4;
    const double boxSize = 80.0;
    const double spacing = 2.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(
          color: Colors.blue.shade900.withAlpha(128),
          width: 2.0,
        ),
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: listenable,
        builder: (context, type, child) {
          if (type == null || type.isEmpty)
            return Container();
          final color = tetrominoColors[type]!;
          final gridIndices = nextPieceGrid[type] ?? [];

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(spacing),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridDimension,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: gridDimension * gridDimension,
            itemBuilder: (context, index) {
              final bool isOccupied = gridIndices.contains(index);
              return Container(
                decoration: BoxDecoration(
                  color: isOccupied ? color : Colors.transparent,
                  borderRadius: isOccupied
                      ? const BorderRadius.all(Radius.circular(2.0))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NextPieceBox extends StatelessWidget {
  final ValueNotifier<String> listenable;
  const NextPieceBox({super.key, required this.listenable});

  @override
  Widget build(BuildContext context) {
    const int gridDimension = 4;
    const double boxSize = 80.0;
    const double spacing = 2.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(
          color: Colors.blue.shade900.withAlpha(128),
          width: 2.0,
        ),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: listenable,
        builder: (context, type, child) {
          if (type.isEmpty) return Container();
          final color = tetrominoColors[type]!;
          final gridIndices = nextPieceGrid[type] ?? [];

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(spacing),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridDimension,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: gridDimension * gridDimension,
            itemBuilder: (context, index) {
              final bool isOccupied = gridIndices.contains(index);
              return Container(
                decoration: BoxDecoration(
                  color: isOccupied ? color : Colors.transparent,
                  borderRadius: isOccupied
                      ? const BorderRadius.all(Radius.circular(2.0))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}