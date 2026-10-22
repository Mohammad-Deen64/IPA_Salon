import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SalonNavDestination {
  const SalonNavDestination({required this.icon, required this.label, this.badge});

  final IconData icon;
  final String label;
  final int? badge;
}

/// Expanding pill tab bar. The active item morphs from a circle into a gradient pill and reveals its label.
class SalonBottomNav extends StatelessWidget {
  const SalonBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<SalonNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.navBar,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.foreground.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < destinations.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  _PillTab(
                    destination: destinations[index],
                    selected: currentIndex == index,
                    inactiveColor: palette.foreground,
                    circleColor: palette.foreground.withValues(alpha: 0.08),
                    onTap: () => onSelected(index),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.destination,
    required this.selected,
    required this.inactiveColor,
    required this.circleColor,
    required this.onTap,
  });

  final SalonNavDestination destination;
  final bool selected;
  final Color inactiveColor;
  final Color circleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey(destination.label),
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: SalonBottomNav._duration,
          curve: Curves.easeOut,
          height: 44,
          padding: EdgeInsets.only(left: selected ? 14 : 11, right: selected ? 16 : 11),
          decoration: BoxDecoration(
            color: selected ? null : circleColor,
            gradient: selected ? AppColors.gradient : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(destination.icon, size: 22, color: selected ? Colors.white : inactiveColor),
                  if (destination.badge != null)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                        child: Text('${destination.badge}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              ),
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.centerLeft,
                  widthFactor: selected ? 1 : 0,
                  duration: SalonBottomNav._duration,
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: SalonBottomNav._duration,
                    curve: Curves.easeOut,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 72),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
