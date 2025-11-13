import 'package:flutter/material.dart';
import 'settings_manager.dart';
import 'themes.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late String _selectedThemeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final themeId = await SettingsManager.loadThemeSetting();
    if (mounted) {
      setState(() {
        _selectedThemeId = themeId;
        _isLoading = false;
      });
    }
  }

  void _selectTheme(String themeId) {
    // Tutaj w przyszłości można dodać logikę sprawdzania, czy motyw jest odblokowany
    final theme = getThemeById(themeId);
    if (theme.isPremium) {
      // Na razie tylko pokazujemy informację
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is a premium theme! (Feature coming soon)'),
          backgroundColor: Colors.blueAccent,
        ),
      );
      return;
    }

    setState(() {
      _selectedThemeId = themeId;
    });
    SettingsManager.saveThemeSetting(themeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Themes',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availableThemes.length,
              itemBuilder: (context, index) {
                final theme = availableThemes[index];
                final isSelected = theme.id == _selectedThemeId;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    onTap: () => _selectTheme(theme.id),
                    title: Text(
                      theme.name,
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: isSelected ? Colors.blueAccent : Colors.white,
                      ),
                    ),
                    subtitle: _ThemeColorPreview(colors: theme.tetrominoColors.values.toList()),
                    trailing: theme.isPremium
                        ? const Icon(Icons.lock, color: Colors.amber)
                        : isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                            : null,
                  ),
                );
              },
            ),
    );
  }
}

/// Mały widget pokazujący podgląd kolorów motywu.
class _ThemeColorPreview extends StatelessWidget {
  final List<Color> colors;
  const _ThemeColorPreview({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: colors.map((color) {
          return Expanded(
            child: Container(
              height: 10,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}