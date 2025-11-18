import 'package:flutter/material.dart';
import 'main.dart'; // Import dla routeObserver
import 'settings_manager.dart';
import 'package:flame_audio/flame_audio.dart'; // <-- NOWY IMPORT
import 'themes.dart';
import 'vfx.dart'; // Potrzebne do odświeżenia po powrocie

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin, RouteAware { // <-- ZMIENIONO: Dodano SingleTickerProviderStateMixin
  late AnimationController _controller; // <-- NOWOŚĆ: Kontroler animacji
  late List<Animation<double>> _animations; // <-- NOWOŚĆ: Lista animacji dla przycisków
  late bool _isSfxEnabled; // <-- NOWOŚĆ: Stan dla efektów dźwiękowych
  late GameTheme _currentTheme;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitAnimations();
  }

  Future<void> _loadSettingsAndInitAnimations() async {
    final themeId = await SettingsManager.loadThemeSetting();
    final sfxEnabled = await SettingsManager.loadSfxSetting();
    if (!mounted) return;

    setState(() {
      _currentTheme = getThemeById(themeId);
      _isSfxEnabled = sfxEnabled;
      _isLoading = false;
    });

    // --- NOWOŚĆ: Inicjalizacja animacji po wczytaniu motywu ---
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // Całkowity czas trwania sekwencji
      vsync: this,
    );

    // Tworzymy 5 animacji (po jednej dla każdego przycisku) z opóźnieniem (staggered)
    _animations = List.generate(5, (index) {
      final startTime = 0.15 * index; // Każdy kolejny przycisk startuje z opóźnieniem
      final endTime = (startTime + 0.6).clamp(0.0, 1.0); // Czas trwania animacji jednego przycisku
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut), // Użyj Interval
        ),
      );
    });

    // Uruchom animację
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
    _controller.dispose(); // <-- NOWOŚĆ: Zwolnij zasoby kontrolera
    super.dispose();
  }

  /// Wywoływane, gdy wracamy na ten ekran z innego.
  @override
  void didPopNext() {
    // Wczytaj ustawienia ponownie, na wypadek gdyby zostały zmienione
    _loadSettingsAndInitAnimations();
    // Zresetuj i uruchom animację od nowa
    if (mounted && !_isLoading) {
      _controller.forward(from: 0.0);
    }
  }

  /// --- NOWOŚĆ: Obsługa naciśnięcia przycisku z dźwiękiem ---
  void _handleButtonPress(String routeName) {
    // Odtwórz dźwięk, jeśli SFX są włączone
    if (_isSfxEnabled) {
      FlameAudio.play('rotate.wav');
    }
    // Przejdź do wybranego ekranu
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _currentTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tytuł Gry (można dodać ładniejszą grafikę)
            Text(
              'TetrixRush',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 36,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: _currentTheme.accentColor,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Przyciski Menu
            // --- ZMIENIONO: Każdy przycisk jest teraz opakowany w _AnimatedMenuButton ---
            _AnimatedMenuButton(
              animation: _animations[0],
              child: _MenuButton(
                theme: _currentTheme,
                text: 'Start Game',
                onPressed: () => _handleButtonPress('/game'),
                isPrimary: true,
              ),
            ),
            const SizedBox(height: 30),
            _AnimatedMenuButton(
              animation: _animations[1],
              child: _MenuButton(
                theme: _currentTheme,
                text: 'Highscores',
                onPressed: () => _handleButtonPress('/highscores'),
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[2],
              child: _MenuButton(
                theme: _currentTheme,
                text: 'Settings',
                onPressed: () => _handleButtonPress('/settings'),
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[3],
              child: _MenuButton(
                theme: _currentTheme,
                text: 'How to Play',
                onPressed: () => _handleButtonPress('/howtoplay'),
              ),
            ),
            const SizedBox(height: 20),
            _AnimatedMenuButton(
              animation: _animations[4],
              child: _MenuButton(
                theme: _currentTheme,
                text: 'Skins & Effects',
                onPressed: () => _handleButtonPress('/customize'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- NOWOŚĆ: Widget opakowujący przycisk, aby go animować. ---
class _AnimatedMenuButton extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedMenuButton({required this.animation, required this.child});

  @override
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5), // Zacznij 50% wysokości przycisku poniżej
          end: Offset.zero,           // Zakończ w docelowym miejscu
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut, // Krzywa animacji dla płynnego "wjazdu"
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
  final GameTheme theme;

  static const double _buttonWidth = 300.0;

  const _MenuButton({
    required this.text,
    required this.onPressed,
    required this.theme,
    this.isPrimary = false, // <-- DODANO: Domyślna wartość to false
  });

  @override
  Widget build(BuildContext context) {
    // --- ZMIANY TUTAJ ---
    // Definiujemy kolory w oparciu o flagę isPrimary
    final Color backgroundColor = isPrimary ? theme.accentColor : theme.primaryColor;
    final Color borderColor = isPrimary ? theme.accentColor.withAlpha(200) : theme.primaryColor.withAlpha(150);
    final Color shadowColor = isPrimary ? theme.accentColor.withAlpha(150) : Colors.black;

    return SizedBox(
      width: _buttonWidth, // Ustawiamy stałą szerokość
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // <-- ZMIENIONE: Użycie zmiennej
          padding: const EdgeInsets.symmetric(vertical: 20),
          // Dodajemy cień, aby przycisk się wyróżniał
          elevation: isPrimary ? 8.0 : 4.0,
          shadowColor: shadowColor,
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