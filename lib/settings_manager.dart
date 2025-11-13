import 'package:shared_preferences/shared_preferences.dart';

/// Klucze do SharedPreferences
const String _highScoresKey = 'highScores';
const String _musicKey = 'isMusicEnabled';
const String _sfxKey = 'isSfxEnabled';
const String _hapticsKey = 'isHapticsEnabled';
const String _themeKey = 'selectedThemeId'; // <-- NOWY KLUCZ

/// Klasa zarządzająca trwałą pamięcią (SharedPreferences) dla całej aplikacji.
class SettingsManager {

  // --- Najlepsze Wyniki (High Scores) ---

  /// Wczytuje listę najlepszych wyników.
  static Future<List<int>> loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = prefs.getStringList(_highScoresKey) ?? [];
    return scoreStrings.map((s) => int.parse(s)).toList();
  }

  /// Dodaje nowy wynik, sortuje listę i zapisuje ją z powrotem.
  /// Zwraca zaktualizowaną listę najlepszych wyników.
  static Future<List<int>> saveNewHighScore(int newScore) async {
    List<int> highScores = await loadHighScores();
    highScores.add(newScore);
    highScores.sort((a, b) => b.compareTo(a)); // Sortuj malejąco
    highScores = highScores.take(5).toList(); // Zachowaj tylko top 5

    final prefs = await SharedPreferences.getInstance();
    final scoreStrings = highScores.map((s) => s.toString()).toList();
    await prefs.setStringList(_highScoresKey, scoreStrings);
    
    return highScores;
  }

  // --- Ustawienia (Muzyka, SFX, Haptyka) ---

  /// Wczytuje pojedyncze ustawienie boolean (np. muzykę).
  static Future<bool> loadSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true; // Domyślnie włączone
  }

  /// Zapisuje pojedyncze ustawienie boolean.
  static Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Metody pomocnicze dla konkretnych ustawień
  static Future<bool> loadMusicSetting() => loadSetting(_musicKey);
  static Future<bool> loadSfxSetting() => loadSetting(_sfxKey);
  static Future<bool> loadHapticsSetting() => loadSetting(_hapticsKey);
  
  static Future<void> saveMusicSetting(bool value) => saveSetting(_musicKey, value);
  static Future<void> saveSfxSetting(bool value) => saveSetting(_sfxKey, value);
  static Future<void> saveHapticsSetting(bool value) => saveSetting(_hapticsKey, value);

  // --- Motywy ---

  /// Wczytuje ID wybranego motywu.
  static Future<String> loadThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'classic'; // Domyślnie 'classic'
  }

  /// Zapisuje ID wybranego motywu.
  static Future<void> saveThemeSetting(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
  }
}