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
        body: Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // --- ZAKTUALIZOWANY UKŁAD ---
              SizedBox(
                width: worldSize.x,
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

                    // --- 2. NOWA KOLUMNA NA WYNIK I POZIOM ---
                    Flexible(
                      flex: 2, // Dajemy jej więcej miejsca
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
                        // Używamy Kolumny
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
                            // Mały odstęp
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
                                    fontSize: 14, // Trochę mniejszy
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 3. 'Next' Box
                    Flexible(
                      flex: 1,
                      child: NextPieceBox(listenable: game.nextTetrominoType),
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
        ),
      ),
    ),
  );
}

// --- WIDŻET: HOLD PIECE BOX (bez zmian) ---
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