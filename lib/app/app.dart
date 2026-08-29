import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Deliberately thin: theme and routing are the only two
/// things it owns directly, per architecture §7 ("use a feature-first
/// Clean Architecture / MVVM-style structure") — everything else lives in
/// features/ and is reached only through the router.
class NexusPayApp extends ConsumerWidget {
  const NexusPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'NexusPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
