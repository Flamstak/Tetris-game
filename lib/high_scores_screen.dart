import 'package:flutter/material.dart';
import 'settings_manager.dart'; // Importujemy nasz manager
import 'themes.dart';

class HighScoresScreen extends StatefulWidget {
  const HighScoresScreen({super.key});

  @override
  State<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> {
  late GameTheme _currentTheme;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeId = await SettingsManager.loadThemeSetting();
    if (mounted) {
      setState(() {
        _currentTheme = getThemeById(themeId);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.grey[900]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _currentTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'High Scores',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: _currentTheme.primaryColor,
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