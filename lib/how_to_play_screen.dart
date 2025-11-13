import 'package:flutter/material.dart';
import 'ui_helpers.dart'; // Importujemy InstructionRow
import 'settings_manager.dart';
import 'themes.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
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
          'How to Play',
          style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: _currentTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            InstructionRow(
              icon: Icons.touch_app_outlined,
              action: 'Rotate',
              description: 'Tap anywhere',
            ),
            InstructionRow(
              icon: Icons.arrow_right_alt,
              action: 'Move',
              description: 'Drag left or right',
            ),
            InstructionRow(
              icon: Icons.arrow_downward,
              action: 'Soft Drop',
              description: 'Drag down',
            ),
            InstructionRow(
              icon: Icons.back_hand_outlined,
              action: 'Hold',
              description: 'Press and hold',
            ),
          ],
        ),
      ),
    );
  }
}