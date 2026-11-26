import 'package:flutter/material.dart';

/// Notifier para gerenciar a escala global de fonte do app (Acessibilidade RNF03)
/// Permite alternar entre os níveis: 1.0 (Normal), 1.15 (Médio), 1.3 (Grande) e 1.5 (Muito Grande)
class FontScaleNotifier extends ChangeNotifier {
  static const List<double> availableScales = [1.0, 1.15, 1.3, 1.5];

  double _currentScale = 1.0;

  double get scale => _currentScale;

  FontScaleNotifier() {
    _loadScale();
  }

  void _loadScale() {
    _currentScale = 1.0;
  }


  void setScale(double newScale) {
    if (availableScales.contains(newScale) && _currentScale != newScale) {
      _currentScale = newScale;
      notifyListeners();
    }
  }

  void cycleNextScale() {
    int currentIndex = availableScales.indexOf(_currentScale);
    if (currentIndex == -1) currentIndex = 0;
    int nextIndex = (currentIndex + 1) % availableScales.length;
    _currentScale = availableScales[nextIndex];
    notifyListeners();
  }

  String get currentScaleLabel {
    if (_currentScale == 1.0) return 'Normal (100%)';
    if (_currentScale == 1.15) return 'Média (115%)';
    if (_currentScale == 1.3) return 'Grande (130%)';
    return 'Muito Grande (150%)';
  }
}

/// Widget de cabeçalho "A+ Fonte" para permitir que o usuário alterne o tamanho
/// com alvo de toque >= 48x48dp
class FontScaleActionButton extends StatelessWidget {
  const FontScaleActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aumentar ou diminuir tamanho do texto',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white70),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A+',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.format_size, size: 18, color: Colors.white),
          ],
        ),
      ),
      onPressed: () {
        _showScaleDialog(context);
      },
    );
  }

  void _showScaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tamanho do Texto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: FontScaleNotifier.availableScales.map((scale) {
              return ListTile(
                title: Text(
                  _labelForScale(scale),
                  style: TextStyle(fontSize: 16 * scale),
                ),
                onTap: () {
                  // Notifier acessado via Inherited/Provider ou callback
                  Navigator.of(ctx).pop(scale);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  String _labelForScale(double scale) {
    if (scale == 1.0) return 'Padrão (100%)';
    if (scale == 1.15) return 'Médio (115%)';
    if (scale == 1.3) return 'Grande (130%)';
    return 'Extra Grande (150%)';
  }
}
