import 'package:flutter/material.dart';
import 'ui_helpers.dart'; // Importujemy InstructionRow

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'How to Play',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            InstructionRow(
              icon: Icons.touch_app_outlined,
              action: 'Rotate',
              description: 'Tap anywhere',
            ),
            InstructionRow(
              icon: Icons.arrow_right_alt,
              action: 'Move',
              description: 'Drag left or right',
            ),
            InstructionRow(
              icon: Icons.arrow_downward,
              action: 'Soft Drop',
              description: 'Drag down',
            ),
            InstructionRow(
              icon: Icons.back_hand_outlined,
              action: 'Hold',
              description: 'Press and hold',
            ),
          ],
        ),
      ),
    );
  }
}