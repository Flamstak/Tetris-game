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
              
              // --- Układ: Hold, Score, Next ---
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

                    // 2. Score Box
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.8),
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          border: Border.all(
                            color: Colors.blue.shade900.withAlpha(128), 
                            width: 2.0
                          ),
                        ),
                        child: ValueListenableBuilder<int>(
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

              // --- WIDŻET GRY (bez zmian) ---
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

// --- WIDŻET: HOLD PIECE BOX ---
class HoldPieceBox extends StatelessWidget {
  final ValueNotifier<String?> listenable;
  
  // --- POPRAWKA LINTERA: Użycie 'super.key' ---
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


// --- WIDŻET: NEXT PIECE BOX ---
class NextPieceBox extends StatelessWidget {
  final ValueNotifier<String> listenable;
  
  // --- POPRAWKA LINTERA: Użycie 'super.key' ---
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