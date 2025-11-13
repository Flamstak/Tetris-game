import 'package:flutter/material.dart';
import 'settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Stan dla tego ekranu
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  bool _isHapticsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  /// Wczytuje wszystkie ustawienia przy starcie ekranu
  Future<void> _loadAllSettings() async {
    final music = await SettingsManager.loadMusicSetting();
    final sfx = await SettingsManager.loadSfxSetting();
    final haptics = await SettingsManager.loadHapticsSetting();
    if (mounted) {
      setState(() {
        _isMusicEnabled = music;
        _isSfxEnabled = sfx;
        _isHapticsEnabled = haptics;
        _isLoading = false;
      });
    }
  }

  // --- Metody przełączające ---

  void _toggleMusic() {
    setState(() {
      _isMusicEnabled = !_isMusicEnabled;
    });
    // Zapisz zmianę (bez 'await', niech to się dzieje w tle)
    SettingsManager.saveMusicSetting(_isMusicEnabled);
  }
  
  void _toggleSfx() {
     setState(() {
      _isSfxEnabled = !_isSfxEnabled;
    });
    SettingsManager.saveSfxSetting(_isSfxEnabled);
  }

  void _toggleHaptics() {
     setState(() {
      _isHapticsEnabled = !_isHapticsEnabled;
    });
    SettingsManager.saveHapticsSetting(_isHapticsEnabled);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audio & Haptics',
                    style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.white70,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Używamy SwitchListTile dla prostoty na tym ekranie
                  _SettingsSwitchTile(
                    title: 'Music',
                    icon: _isMusicEnabled ? Icons.music_note : Icons.music_off,
                    value: _isMusicEnabled,
                    onChanged: (value) => _toggleMusic(),
                  ),
                  _SettingsSwitchTile(
                    title: 'SFX',
                    icon: _isSfxEnabled ? Icons.volume_up : Icons.volume_off,
                    value: _isSfxEnabled,
                    onChanged: (value) => _toggleSfx(),
                  ),
                  _SettingsSwitchTile(
                    title: 'Haptics',
                    icon: _isHapticsEnabled ? Icons.vibration : Icons.phone_android,
                    value: _isHapticsEnabled,
                    onChanged: (value) => _toggleHaptics(),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Stylizowany SwitchListTile
class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
            fontFamily: 'PressStart2P', color: Colors.white, fontSize: 14),
      ),
      secondary: Icon(icon, color: Colors.white, size: 30),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blueAccent,
      inactiveTrackColor: Colors.grey.shade800,
    );
  }
}