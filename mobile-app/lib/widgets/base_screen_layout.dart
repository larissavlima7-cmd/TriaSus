import 'package:flutter/material.dart';
import '../../core/font_scale.dart';

/// Layout base padrão para telas do cidadão com AppBar institucional,
/// título claro e botão "A+ Fonte" para acessibilidade (RNF03).
class BaseScreenLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBackButton;

  const BaseScreenLayout({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBackButton,
        actions: const [
          FontScaleActionButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
