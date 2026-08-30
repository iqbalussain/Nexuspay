import 'package:flutter/material.dart';

import '../../app/theme/nexus_theme.dart';
import '../../app/theme/nexus_widgets.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return NexusScreen(
      eyebrow: 'Coming Soon',
      title: title,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined,
                size: 40, color: NexusColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: NexusTypography.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'This module is coming in a later phase.',
              style: NexusTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
