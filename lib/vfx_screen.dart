import 'package:flutter/material.dart';
import 'settings_manager.dart';
import 'themes.dart';
import 'vfx.dart';

class VfxScreen extends StatefulWidget {
  const VfxScreen({super.key});

  @override
  State<VfxScreen> createState() => _VfxScreenState();
}

class _VfxScreenState extends State<VfxScreen> {
  late String _currentThemeId;
  late String _currentVfxId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final themeId = await SettingsManager.loadThemeSetting();
    final vfxId = await SettingsManager.loadVfxSetting();
    if (mounted) {
      setState(() {
        _currentThemeId = themeId;
        _currentVfxId = vfxId;
        _isLoading = false;
      });
    }
  }

  void _selectVfx(VfxPack vfxPack) {
    setState(() {
      _currentVfxId = vfxPack.id;
    });
    SettingsManager.saveVfxSetting(vfxPack.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vfxPack.name} effect applied!'),
        duration: const Duration(seconds: 2),
      ),
    );
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

    final theme = getThemeById(_currentThemeId);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Visual Effects',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: availableVfxPacks.length,
        itemBuilder: (context, index) {
          final itemVfx = availableVfxPacks[index];
          final isSelected = itemVfx.id == _currentVfxId;

          return Card(
            color: theme.primaryColor.withAlpha((255 * 0.5).round()),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              onTap: () => _selectVfx(itemVfx),
              title: Text(
                itemVfx.name,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: isSelected ? theme.accentColor : Colors.white,
                ),
              ),
              subtitle: Text(
                itemVfx.description,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              trailing: _buildTrailingIcon(itemVfx, isSelected, theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailingIcon(VfxPack vfx, bool isSelected, GameTheme theme) {
    if (vfx.isPremium) {
      return const Icon(Icons.lock, color: Colors.amber);
    }
    if (isSelected) {
      return Icon(Icons.check_circle, color: theme.accentColor);
    }
    return const Icon(Icons.chevron_right, color: Colors.white54);
  }
}