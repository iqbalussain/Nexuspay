import 'package:flutter/material.dart';

/// A clearly-labelled stand-in for a module not yet built. The route
/// already points at the correct path (see app/router/app_router.dart),
/// so building the real screen later means replacing this widget only —
/// no router or navigation changes needed.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '$title — coming in a later phase',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
