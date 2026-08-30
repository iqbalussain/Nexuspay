import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/nexus_theme.dart';

class NexusPayApp extends ConsumerWidget {
  const NexusPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'NexusPay',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.dark,       // dark-first; no light theme until branding confirmed
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
