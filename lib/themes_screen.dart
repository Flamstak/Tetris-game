import 'package:flutter/material.dart';
import 'settings_manager.dart';
import 'themes.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late String _savedThemeId; // Zapisany motyw
  late String _previewThemeId; // Aktualnie podglądany motyw
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
        _savedThemeId = themeId;
        _previewThemeId = themeId; // Na starcie podglądany = zapisany
        _isLoading = false;
      });
    }
  }

  void _selectTheme(String themeId) {
    final theme = getThemeById(themeId);
    if (theme.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is a premium theme! (Feature coming soon)'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _previewThemeId = themeId; // Zmień tylko podglądany motyw
    });
  }

  void _applyTheme() {
    SettingsManager.saveThemeSetting(_previewThemeId);
    setState(() {
      _savedThemeId = _previewThemeId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${getThemeById(_previewThemeId).name} theme applied!'),
        backgroundColor: getThemeById(_previewThemeId).accentColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jeśli ekran się ładuje, pokaż domyślny wygląd
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.grey[900]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final previewTheme = getThemeById(_previewThemeId);

    return Scaffold(
      backgroundColor: previewTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Themes',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: previewTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availableThemes.length,
              itemBuilder: (context, index) {
                final theme = availableThemes[index];
                final isPreviewing = theme.id == _previewThemeId;

                return Card(
                  color: previewTheme.primaryColor.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    onTap: () => _selectTheme(theme.id),
                    title: Text(
                      theme.name,
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: isPreviewing ? previewTheme.accentColor : Colors.white,
                      ),
                    ),
                    subtitle: _ThemeColorPreview(colors: theme.tetrominoColors.values.toList()),
                    trailing: theme.isPremium
                        ? const Icon(Icons.lock, color: Colors.amber)
                        : isPreviewing
                            ? Icon(Icons.check_circle, color: previewTheme.accentColor)
                            : null,
                  ),
                );
              },
            ),
          ),
          // Przycisk "Zastosuj"
          if (_previewThemeId != _savedThemeId)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _applyTheme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewTheme.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: Colors.black),
                ),
              ),
            ),
        ],
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