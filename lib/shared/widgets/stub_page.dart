import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Branded placeholder used while a feature agent is implementing the real
/// screen. Each stub file is a 1:1 class the feature agent replaces.
class StubPage extends StatelessWidget {
  final String title;
  final String? description;

  const StubPage({super.key, required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(title)),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: '$title — coming soon',
        message: description,
      ),
    );
  }
}
