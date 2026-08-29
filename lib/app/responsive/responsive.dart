import 'package:flutter/widgets.dart';

/// Single source of truth for the desktop/mobile breakpoint. Architecture
/// §2 & §24: "Desktop and mobile layouts must be intentionally designed
/// for their use cases; do not simply shrink the desktop UI" — this is
/// used to pick an entirely different shell widget (see app/shell/
/// app_shell.dart), not to hide/show widgets inside one shared layout.
class Breakpoints {
  static const double desktop = 900;
  static const double wideDesktop = 1200;
}

class ResponsiveLayout {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.wideDesktop;
}
