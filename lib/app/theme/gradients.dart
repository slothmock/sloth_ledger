import 'package:flutter/material.dart';

LinearGradient homeHeaderGradient(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final top = cs.primary.withValues(alpha: isDark ? 0.22 : 0.14);
  final bottom = cs.surface;

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
    stops: const [0.0, 0.85],
  );
}
