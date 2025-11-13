import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tytuł Gry (można dodać ładniejszą grafikę)
            const Text(
              'TetrixRush',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 36,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.blueAccent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Przyciski Menu
            _MenuButton(
              text: 'Start Game',
              onPressed: () {
                Navigator.pushNamed(context, '/game');
              },
              isPrimary: true,
            ),
            const SizedBox(height: 30),
            _MenuButton(
              text: 'Highscores',
              onPressed: () {
                Navigator.pushNamed(context, '/highscores');
              },
            ),
            const SizedBox(height: 20),
            _MenuButton(
              text: 'Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 20),
            _MenuButton(
              text: 'How to Play',
              onPressed: () {
                Navigator.pushNamed(context, '/howtoplay');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Prywatny, stylizowany widget przycisku dla menu
class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary; // <-- DODANO: Nowa właściwość

  static const double _buttonWidth = 300.0;

  const _MenuButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = false, // <-- DODANO: Domyślna wartość to false
  });

  @override
  Widget build(BuildContext context) {
    // --- ZMIANY TUTAJ ---
    // Definiujemy kolory w oparciu o flagę isPrimary
    final Color backgroundColor = isPrimary
        ? Colors.blueAccent.shade400 // Jaśniejszy, bardziej aktywny kolor
        : Colors.blue.shade900.withAlpha(200); // Oryginalny kolor

    final Color borderColor = isPrimary
        ? Colors.blueAccent.shade100.withAlpha(200) // Jaśniejsza ramka
        : Colors.blue.shade900.withAlpha(128); // Oryginalna ramka

    return SizedBox(
      width: _buttonWidth, // Ustawiamy stałą szerokość
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // <-- ZMIENIONE: Użycie zmiennej
          padding: const EdgeInsets.symmetric(vertical: 20),
          // Dodajemy cień, aby przycisk się wyróżniał
          elevation: isPrimary ? 8.0 : 2.0,
          shadowColor: isPrimary ? Colors.blueAccent.withAlpha(150) : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: borderColor, // <-- ZMIENIONE: Użycie zmiennej
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            color: Colors.white,
            fontSize: 16,
          ),)
      ),
    );
  }
}