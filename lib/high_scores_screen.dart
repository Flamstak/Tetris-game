import 'package:flutter/material.dart';
import 'settings_manager.dart'; // Importujemy nasz manager

class HighScoresScreen extends StatelessWidget {
  const HighScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'High Scores',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: FutureBuilder<List<int>>(
          // Używamy managera do wczytania wyników
          future: SettingsManager.loadHighScores(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return const Text(
                'Błąd wczytywania wyników',
                style: TextStyle(fontFamily: 'PressStart2P', color: Colors.red),
              );
            }

            final highScores = snapshot.data ?? [];

            if (highScores.isEmpty) {
              return const Text(
                'Brak zapisanych wyników',
                style: TextStyle(
                    fontFamily: 'PressStart2P', color: Colors.white70),
              );
            }

            // Budujemy tekst listy wyników
            String text = 'HIGH SCORES:\n\n';
            for (int i = 0; i < highScores.length; i++) {
              text += '${i + 1}. ${highScores[i]}\n\n';
            }

            return Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            );
          },
        ),
      ),
    );
  }
}