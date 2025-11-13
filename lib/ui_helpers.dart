import 'package:flutter/material.dart';
import 'tetromino_data.dart'; // Dla kolorów i siatki

// --- WIDŻET POMOCNICZY DLA INSTRUKCJI ---
// (Przeniesiony z main.dart i upubliczniony)
class InstructionRow extends StatelessWidget {
  final IconData icon;
  final String action;
  final String description;

  const InstructionRow({
    super.key,
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

// --- Widżety Hold i Next (Przeniesione z main.dart) ---

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