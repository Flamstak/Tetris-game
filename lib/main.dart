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
          side: BorderSide(color: Colors.blue.shade900.withAlpha(128), width: 2.0),
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
          child: SingleChildScrollView( // Aby można było przewijać
            child: ListBody( // Używamy ListBody zamiast Column
              children: <Widget>[
                // --- Sekcja Audio (bez zmian) ---
                const Text(
                  'Audio',
                  style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.white70,
                      fontSize: 14),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Przycisk Muzyki
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isMusicEnabled,
                        builder: (context, isEnabled, child) {
                          return IconButton(
                            icon: Icon(
                              isEnabled ? Icons.music_note : Icons.music_off,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () => game.toggleMusic(),
                          );
                        },
                      ),
                      // Przycisk SFX
                      ValueListenableBuilder<bool>(
                        valueListenable: game.isSfxEnabled,
                        builder: (context, isEnabled, child) {
                          return IconButton(
                            icon: Icon(
                              isEnabled ? Icons.volume_up : Icons.volume_off,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () => game.toggleSfx(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // --- SEKCJA INSTRUKCJI ---
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
                // --- POPRAWKA TUTAJ ---
                _InstructionRow(
                  icon: Icons.back_hand_outlined, // Zamiast 'touch_and_hold_outlined'
                  action: 'Hold',
                  description: 'Press and hold',
                ),
                // ---------------------
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

// --- NOWY WIDŻET POMOCNICZY DLA INSTRUKCJI ---
// (Umieść go na dole pliku main.dart)
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

// --- Widżety UI dla Pasków Bocznych (BEZ ZMIAN) ---

/// Widżet Fluttera wyświetlający przechowany klocek ('Hold').
class HoldPieceBox extends StatelessWidget {
  final ValueNotifier<String?> listenable;
  const HoldPieceBox({super.key, required this.listenable});

  @override
  Widget build(BuildContext context) {
    const int gridDimension = 4; // Siatka 4x4
    const double boxSize = 80.0; // Rozmiar pudełka
    const double spacing = 2.0; // Odstęp między kafelkami

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
          if (type == null || type.isEmpty) return Container(); // Puste, jeśli nic nie jest trzymane
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

/// Widżet Fluttera wyświetlający następny klocek ('Next').
class NextPieceBox extends StatelessWidget {
  final ValueNotifier<String> listenable;
  const NextPieceBox({super.key, required this.listenable});

  @override
  Widget build(BuildContext context) {
    const int gridDimension = 4; // Siatka 4x4
    const double boxSize = 80.0; // Rozmiar pudełka
    const double spacing = 2.0; // Odstęp między kafelkami

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
          if (type.isEmpty) return Container(); // Puste na starcie
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