import 'package:flutter/material.dart';
import 'dart:math';
import 'tetromino_data.dart';

/// Typ funkcji, która definiuje, jak rysowana jest animacja czyszczenia linii.
/// Otrzymuje `canvas`, `progress` animacji (0.0-1.0), współrzędną `x` kafelka i pozycję `yPos` na płótnie,
/// jego `color`, `tileSize` oraz `borderPaint` do ewentualnego użycia.
/// Zwraca `true`, jeśli kafelek powinien być narysowany, `false` jeśli ma być pominięty.
typedef LineClearAnimationFn = bool Function(
  Canvas canvas,
  double progress,
  int x,
  double yPos,
  Color color,
  double tileSize,
  Paint borderPaint,
);

/// Reprezentuje pakiet efektów wizualnych (VFX), które można oddzielnie konfigurować.
class VfxPack {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final LineClearAnimationFn lineClearAnimation;

  const VfxPack({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
    required this.lineClearAnimation,
  });
}

// --- Definicje Konkretnych Animacji ---

/// Animacja: Kafelek błyska na biało, a następnie stopniowo zanika.
bool _classicLineClearAnimation(
  Canvas canvas,
  double progress,
  int x,
  double yPos,
  Color color,
  double tileSize,
  Paint borderPaint,
) {
  final rect = Rect.fromLTWH(x.toDouble() * tileSize, yPos, tileSize, tileSize);

  // Faza 1: Jasny błysk (pierwsze 20% czasu)
  if (progress < 0.2) {
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, borderPaint);
    return false; // Zatrzymujemy dalsze rysowanie tego kafelka
  }

  // Faza 2: Zanikanie (pozostałe 80% czasu)
  final fadeProgress = (progress - 0.2) / 0.8;
  final opacity = 1.0 - fadeProgress;

  // ZAKTUALIZOWANO: Użycie `withAlpha` zamiast przestarzałego `withOpacity`
  final newColor = color.withAlpha((color.a * opacity).round());
  final newBorderColor = borderPaint.color.withAlpha((borderPaint.color.a * opacity).round());
  canvas.drawRect(rect, Paint()..color = newColor);
  canvas.drawRect(rect, borderPaint..color = newBorderColor);
  return false; // Zatrzymujemy dalsze rysowanie
}

/// Animacja: Błysk, a następnie wymazywanie od środka planszy na zewnątrz.
bool _wipeLineClearAnimation(
  Canvas canvas,
  double progress,
  int x,
  double yPos,
  Color color,
  double tileSize,
  Paint borderPaint,
) {
  // Faza 1: Błysk (identyczna jak w klasycznej)
  if (progress < 0.2) {
    final rect = Rect.fromLTWH(x.toDouble() * tileSize, yPos, tileSize, tileSize);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, borderPaint);
    return false;
  }

  // Faza 2: Wymazywanie
  final wipeProgress = (progress - 0.2) / 0.8;
  final centerColumn = (columns - 1) / 2.0;
  final distanceFromCenter = (x - centerColumn).abs();
  final wipeThreshold = wipeProgress * (centerColumn + 1);

  // Jeśli odległość kafelka od środka jest mniejsza niż próg, nie rysuj go.
  if (distanceFromCenter < wipeThreshold) {
    return false;
  }

  // W przeciwnym razie, narysuj go normalnie.
  return true; // Zwróć true, aby LandedTilesComponent narysował kafelek.
}

/// Animacja: Błysk, a następnie kafelek kurczy się, obracając się, i znika.
bool _disintegrateLineClearAnimation(
  Canvas canvas,
  double progress,
  int x,
  double yPos,
  Color color,
  double tileSize,
  Paint borderPaint,
) {
  // Faza 1: Błysk (identyczna jak w pozostałych)
  if (progress < 0.2) {
    final rect = Rect.fromLTWH(x.toDouble() * tileSize, yPos, tileSize, tileSize);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, borderPaint);
    return false;
  }

  // Faza 2: Kurczenie się i obrót
  final effectProgress = (progress - 0.2) / 0.8; // 0.0 -> 1.0
  final scale = 1.0 - effectProgress; // 1.0 -> 0.0

  if (scale <= 0) {
    return false; // Już zniknął, nie rysuj nic.
  }

  final newSize = tileSize * scale;
  final offset = (tileSize - newSize) / 2;

  final rect = Rect.fromLTWH(
    x.toDouble() * tileSize + offset,
    yPos + offset,
    newSize,
    newSize,
  );

  // Zapisz stan canvas, aby obrót dotyczył tylko tego kafelka
  canvas.save();
  canvas.translate(x.toDouble() * tileSize + tileSize / 2, yPos + tileSize / 2);
  canvas.rotate(effectProgress * pi); // Obrót w miarę postępu
  canvas.translate(-(x.toDouble() * tileSize + tileSize / 2), -(yPos + tileSize / 2));

  canvas.drawRect(rect, Paint()..color = color);
  canvas.restore(); // Przywróć stan canvas

  return false; // Sami narysowaliśmy, więc nie rysuj normalnie.
}

// --- Dostępne Pakiety Efektów ---

final List<VfxPack> availableVfxPacks = [
  VfxPack(
    id: 'classic_fade',
    name: 'Classic Fade',
    description: 'A simple and clean fade-out effect.',
    lineClearAnimation: _classicLineClearAnimation,
  ),
  VfxPack(
    id: 'center_wipe',
    name: 'Center Wipe',
    description: 'An energetic wipe from the center.',
    lineClearAnimation: _wipeLineClearAnimation,
  ),
  VfxPack(
    id: 'disintegrate',
    name: 'Disintegrate',
    description: 'Tiles crumble into nothing.',
    isPremium: true, // Przykład efektu premium
    lineClearAnimation: _disintegrateLineClearAnimation,
  ),
];

/// Pobiera pakiet VFX po jego ID. Domyślnie zwraca pierwszy dostępny pakiet.
VfxPack getVfxPackById(String id) {
  return availableVfxPacks.firstWhere((pack) => pack.id == id,
      orElse: () => availableVfxPacks.first);
}