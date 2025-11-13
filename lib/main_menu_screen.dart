import 'package:flutter/material.dart';
import 'main.dart'; // Import dla routeObserver

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Tworzymy 5 animacji, po jednej dla każdego przycisku, z opóźnieniem
    _animations = List.generate(5, (index) {
      final startTime = 0.15 * index;
      // Upewniamy się, że endTime nie przekroczy 1.0
      final endTime = (startTime + 0.6).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subskrybuj obserwatora tras, aby wiedzieć, kiedy wracamy na ten ekran
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Pamiętaj o odsubskrybowaniu obserwatora
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  /// Wywoływane, gdy wracamy na ten ekran z innego.
  @override
  void didPopNext() {
    // Zresetuj i uruchom animację od nowa
    _controller.forward(from: 0.0);
  }

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
            _AnimatedMenuButton(
              animation: _animations[0],
              child: _MenuButton(
                text: 'Start Game',
                onPressed: () {
                  Navigator.pushNamed(context, '/game');
                },
                isPrimary: true,
              ),
            ),
            const SizedBox(height: 30),
            _AnimatedMenuButton(
              animation: _animations[1],
              child: _MenuButton(
                text: 'Highscores',
                onPressed: () {
                  Navigator.pushNamed(context, '/highscores');
                },
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[2],
              child: _MenuButton(
                text: 'Settings',
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[3],
              child: _MenuButton(
                text: 'How to Play',
                onPressed: () {
                  Navigator.pushNamed(context, '/howtoplay');
                },
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[4],
              child: _MenuButton(
                text: 'Themes',
                onPressed: () {
                  Navigator.pushNamed(context, '/themes');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget opakowujący przycisk, aby go animować.
class _AnimatedMenuButton extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedMenuButton({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5), // Zacznij 50% wysokości poniżej
          end: Offset.zero, // Zakończ w docelowym miejscu
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        ),
        child: child,
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