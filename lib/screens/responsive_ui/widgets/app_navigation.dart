import 'package:flutter/material.dart';
import 'package:scheldule/providers/drawer_nav/drawer_state.dart';

class AppNavigationItem {
  final DrawerStatus status;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final bool managerOnly;

  const AppNavigationItem({
    required this.status,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    this.managerOnly = false,
  });
}

const appNavigationItems = <AppNavigationItem>[
  AppNavigationItem(
    status: DrawerStatus.calendar,
    label: 'Ημερολόγιο',
    description: 'Η καθημερινή εικόνα του καταστήματος',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
  ),
  AppNavigationItem(
    status: DrawerStatus.appointments,
    label: 'Ραντεβού',
    description: 'Δημιουργία και ιστορικό ραντεβού',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note_rounded,
  ),
  AppNavigationItem(
    status: DrawerStatus.customer,
    label: 'Πελάτες',
    description: 'Καρτέλες και ιστορικό πελατών',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
  ),
  AppNavigationItem(
    status: DrawerStatus.employee,
    label: 'Ομάδα',
    description: 'Εργαζόμενοι και αρμοδιότητες',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    managerOnly: true,
  ),
  AppNavigationItem(
    status: DrawerStatus.incexp,
    label: 'Οικονομικά',
    description: 'Έσοδα, έξοδα και οικονομική εικόνα',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    managerOnly: true,
  ),
  AppNavigationItem(
    status: DrawerStatus.settings,
    label: 'Ρυθμίσεις',
    description: 'Υπηρεσίες, χώροι και λειτουργία',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    managerOnly: true,
  ),
];

List<AppNavigationItem> visibleNavigationItems(bool canManage) =>
    appNavigationItems.where((item) => canManage || !item.managerOnly).toList();

AppNavigationItem navigationItemFor(DrawerStatus status) =>
    appNavigationItems.firstWhere((item) => item.status == status);

class AppPageHeader extends StatelessWidget {
  final AppNavigationItem item;
  final Widget? trailing;
  final bool compact;

  const AppPageHeader({
    super.key,
    required this.item,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: compact ? 64 : 76,
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.selectedIcon, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 18 : null,
                      ),
                ),
                if (!compact)
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppContentSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const AppContentSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF151B1A) : const Color(0xFFF7FAF9),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withAlpha(dark ? 18 : 70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24001816),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}
