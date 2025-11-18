import 'package:flutter/material.dart';

// Importy nowych ekranów
import 'main_menu_screen.dart';
import 'game_screen.dart';
import 'high_scores_screen.dart';
import 'settings_screen.dart';
import 'how_to_play_screen.dart'; 
import 'customize_screen.dart'; // <-- NOWY IMPORT

// --- DODANO ---
// Globalny obserwator tras, aby ekrany wiedziały, kiedy są widoczne
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Główna funkcja aplikacji.
void main() {
  // Upewnij się, że binding Fluttera jest zainicjowany
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uruchom główny widget aplikacji
  runApp(const TetrisApp());
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'PressStart2P', 
      ),
      home: const MainMenuScreen(),
      // Rejestrujemy obserwatora w MaterialApp
      navigatorObservers: [routeObserver],
      routes: {
        '/game': (context) => const GameScreen(),
        '/highscores': (context) => const HighScoresScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/howtoplay': (context) => const HowToPlayScreen(),
        '/customize': (context) => const CustomizeScreen(), // <-- NOWA TRASA
      },
    );
  }
}