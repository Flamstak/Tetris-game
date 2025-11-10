import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart'; 
import 'tetromino_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final game = TetrisGame();
  
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black, 
        // --- POPRAWKA: Używamy 'Builder' aby uzyskać context dla showDialog ---
        body: Builder(
          builder: (context) { 
            return Center( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  SizedBox(
                    width: worldSize.x,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // 1. 'Hold' Box (bez zmian)
                        Flexible(
                          flex: 1, 
                          child: HoldPieceBox(listenable: game.heldTetrominoType),
                        ),

                        const SizedBox(width: 10),

                        // --- 2. ZMODYFIKOWANA KOLUMNA (USUNIĘTO USTAWIEINA) ---
                        Flexible(
                          flex: 2, 
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 0, 0, 0.8),
                              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                              border: Border.all(
                                color: Colors.blue.shade900.withAlpha(128), 
                                width: 2.0
                              ),
                            ),
                            child: Column(
                              children: [
                                // 2a. WYNIK (bez zmian)
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
                                // 2b. POZIOM (bez zmian)
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
                                
                                // --- USUNIĘTO SEKCJĘ USTAWIEŃ STĄD ---
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // --- 3. ZMODYFIKOWANA PRAWA KOLUMNA (NEXT + USTAWIEINA) ---
                        Flexible(
                          flex: 1,
                          // Używamy Kolumny, aby umieścić przycisk POD 'NextBox'
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 3a. 'Next' Box
                              NextPieceBox(listenable: game.nextTetrominoType),
                              
                              // 3b. Nowy przycisk Ustawień
                              const SizedBox(height: 10),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white70,
                                  size: 30,
                                ),
                                onPressed: () {
                                  // Wywołaj okienko dialogowe
                                  _showSettingsDialog(context, game);
                                },
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10), 

                  // Widżet Gry (bez zmian)
                  SizedBox(
                    width: worldSize.x,
                    height: worldSize.y,
                    child: GameWidget(game: game),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    ),
  );
}

// --- NOWA FUNKCJA POKAZUJĄCA DIALOG ---
void _showSettingsDialog(BuildContext context, TetrisGame game) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      // Używamy ciemnego tła
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.blue.shade900.withAlpha(128), width: 2.0),
        ),
        title: const Text(
          'Ustawienia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PressStart2P', 
            color: Colors.white, 
            fontSize: 18,
          ),
        ),
        content: Row(
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
                    size: 40, // Większe ikony w okienku
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
                    size: 40, // Większe ikony w okienku
                  ),
                  onPressed: () => game.toggleSfx(),
                );
              },
            ),
          ],
        ),
        actions: [
          // Przycisk zamykania
          TextButton(
            child: const Text(
              'Zamknij',
              style: TextStyle(
                fontFamily: 'PressStart2P', 
                color: Colors.blueAccent, 
                fontSize: 12
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Zamknij dialog
            },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}


// --- WIDŻET: HOLD PIECE BOX (bez zmian) ---
class HoldPieceBox extends StatelessWidget {
  // ... (bez zmian)
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
          width: 2.0
        ),
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: listenable,
        builder: (context, type, child) {
          if (type == null || type.isEmpty) return Container(); 
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
                  borderRadius: isOccupied ? const BorderRadius.all(Radius.circular(2.0)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// --- WIDŻET: NEXT PIECE BOX (bez zmian) ---
class NextPieceBox extends StatelessWidget {
  // ... (bez zmian)
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
          width: 2.0
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
                  borderRadius: isOccupied ? const BorderRadius.all(Radius.circular(2.0)) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}