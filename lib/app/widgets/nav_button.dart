import 'package:flutter/material.dart';

class NavButton {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
    this.color,
  });
}

class NavButtonTile extends StatefulWidget {
  const NavButtonTile({super.key, required this.button});

  final NavButton button;

  @override
  State<NavButtonTile> createState() => _NavButtonTileState();
}

class _NavButtonTileState extends State<NavButtonTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btn = widget.button;
    final baseColor = btn.enabled
        ? (btn.color ?? Theme.of(context).colorScheme.primary)
        : Colors.grey.shade400;

    final pressedColor = btn.enabled
        ? baseColor.withValues(alpha: 0.75)
        : Colors.grey.shade400;

    final iconBg = _pressed ? pressedColor : baseColor;

    return Opacity(
      opacity: btn.enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: btn.enabled ? btn.onTap : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: baseColor.withValues(alpha: 0.25),
          highlightColor: Colors.transparent,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    boxShadow: _pressed
                        ? []
                        : [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(btn.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: TextStyle(
                    color: btn.enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                    fontWeight: _pressed ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(btn.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
