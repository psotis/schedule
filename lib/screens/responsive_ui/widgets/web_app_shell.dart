import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/logos/photos_gifs.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/screens/responsive_ui/widgets/app_navigation.dart';

enum AppShellLayout { desktop, tablet, mobile }

typedef AppShellPageBuilder = Widget Function(
  DrawerStatus status,
  bool canManage,
);

class WebAppShell extends StatelessWidget {
  final AppShellLayout layout;
  final AppShellPageBuilder pageBuilder;

  const WebAppShell({
    super.key,
    required this.layout,
    required this.pageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final drawer = context.watch<DrawerProvider>();
    final user = context.watch<AuthProvider>().state.user;
    final canManage = user?.storeRole == 'owner' || user?.storeRole == 'admin';
    final navigation = visibleNavigationItems(canManage);
    final current = navigation.any(
      (item) => item.status == drawer.state.drawerStatus,
    )
        ? navigationItemFor(drawer.state.drawerStatus)
        : navigation.first;

    switch (layout) {
      case AppShellLayout.desktop:
        return _desktop(context, navigation, current, canManage);
      case AppShellLayout.tablet:
        return _tablet(context, navigation, current, canManage);
      case AppShellLayout.mobile:
        return _mobile(context, navigation, current, canManage);
    }
  }

  Widget _desktop(
    BuildContext context,
    List<AppNavigationItem> navigation,
    AppNavigationItem current,
    bool canManage,
  ) {
    final compact = context.watch<UiPreferencesProvider>().value(
              'sidebar_layout',
              fallback:
                  layout == AppShellLayout.tablet ? 'compact' : 'expanded',
            ) ==
        'compact';
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          minimum: const EdgeInsets.all(14),
          child: Row(
            children: [
              _DesktopSidebar(
                navigation: navigation,
                current: current,
                compact: compact,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    AppPageHeader(
                        item: current,
                        compact: layout == AppShellLayout.tablet),
                    Expanded(
                      child: AppContentSurface(
                        child: KeyedSubtree(
                          key: ValueKey(current.status),
                          child: pageBuilder(current.status, canManage),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tablet(
    BuildContext context,
    List<AppNavigationItem> navigation,
    AppNavigationItem current,
    bool canManage,
  ) {
    return _desktop(context, navigation, current, canManage);
  }

  Widget _mobile(
    BuildContext context,
    List<AppNavigationItem> navigation,
    AppNavigationItem current,
    bool canManage,
  ) {
    final primary = navigation.take(3).toList();
    final primaryIndex = primary.indexWhere(
      (item) => item.status == current.status,
    );
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Column(
            children: [
              AppPageHeader(
                item: current,
                compact: true,
                trailing: IconButton(
                  tooltip: 'Περισσότερα',
                  color: Theme.of(context).colorScheme.onSurface,
                  onPressed: () => _showMore(context, navigation, current),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ),
              Expanded(
                child: AppContentSurface(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(current.status),
                    child: pageBuilder(current.status, canManage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 4),
              child: NavigationBar(
                height: 66,
                selectedIndex: primaryIndex < 0 ? 3 : primaryIndex,
                destinations: [
                  ...primary.map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Περισσότερα',
                  ),
                ],
                onDestinationSelected: (index) {
                  if (index < primary.length) {
                    _select(context, primary[index]);
                  } else {
                    _showMore(context, navigation, current);
                  }
                },
              ),
            ),
    );
  }

  Future<void> _showMore(
    BuildContext context,
    List<AppNavigationItem> navigation,
    AppNavigationItem current,
  ) {
    final user = context.read<AuthProvider>().state.user;
    final themeStatus = context.read<ThemeProvider>().state?.themeStatus;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Row(
              children: [
                _logo(48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.displayName ?? '').isEmpty
                            ? (user?.email ?? 'Rantevia')
                            : user!.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        user?.storeRole == 'staff'
                            ? 'Προσωπικό'
                            : 'Διαχείριση καταστήματος',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...navigation.skip(3).map(
                  (item) => ListTile(
                    selected: item.status == current.status,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      item.status == current.status
                          ? item.selectedIcon
                          : item.icon,
                    ),
                    title: Text(item.label),
                    subtitle: Text(item.description),
                    onTap: () {
                      _select(context, item);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
            const Divider(),
            ListTile(
              leading: Icon(
                themeStatus == ThemeStatus.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              title: Text(
                themeStatus == ThemeStatus.dark
                    ? 'Φωτεινό θέμα'
                    : 'Σκούρο θέμα',
              ),
              onTap: () {
                context.read<ThemeProvider>().changeTheme();
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Αποσύνδεση'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.read<AuthProvider>().signout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, AppNavigationItem item) {
    context.read<DrawerProvider>().changePage(item.status, item.label);
  }

  Widget _logo(double size) => ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          Media.logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
}

class _DesktopSidebar extends StatelessWidget {
  final List<AppNavigationItem> navigation;
  final AppNavigationItem current;

  final bool compact;

  const _DesktopSidebar({
    required this.navigation,
    required this.current,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().state.user;
    final themeStatus = context.watch<ThemeProvider>().state?.themeStatus;
    return Container(
      width: compact ? 80 : 236,
      decoration: BoxDecoration(
        color: dark ? const Color(0xF21B1E24) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x26001816), blurRadius: 28),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 18, 20, compact ? 14 : 18, 18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      Media.logo,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!compact) const SizedBox(width: 12),
                  if (!compact)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rantevia',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Business workspace',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: compact ? 'Ανάπτυξη μενού' : 'Σύμπτυξη μενού',
              onPressed: () async {
                final saved =
                    await context.read<UiPreferencesProvider>().setValue(
                          'sidebar_layout',
                          compact ? 'expanded' : 'compact',
                        );
                if (!saved && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Δεν αποθηκεύτηκε η εμφάνιση του μενού.')),
                  );
                }
              },
              icon: Icon(compact
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: navigation.length,
                separatorBuilder: (context, index) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final item = navigation[index];
                  final selected = item.status == current.status;
                  if (compact) {
                    return IconButton(
                      tooltip: item.label,
                      isSelected: selected,
                      style: IconButton.styleFrom(
                        backgroundColor: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        minimumSize: const Size(48, 50),
                      ),
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      onPressed: () =>
                          context.read<DrawerProvider>().changePage(
                                item.status,
                                item.label,
                              ),
                    );
                  }
                  return ListTile(
                    minTileHeight: 50,
                    selected: selected,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(selected ? item.selectedIcon : item.icon),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => context.read<DrawerProvider>().changePage(
                          item.status,
                          item.label,
                        ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (compact) ...[
                    IconButton(
                      tooltip: 'Αλλαγή θέματος',
                      onPressed: context.read<ThemeProvider>().changeTheme,
                      icon: Icon(themeStatus == ThemeStatus.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined),
                    ),
                    IconButton(
                      tooltip: 'Αποσύνδεση',
                      onPressed: context.read<AuthProvider>().signout,
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ] else ...[
                    ListTile(
                      minTileHeight: 44,
                      leading: Icon(
                        themeStatus == ThemeStatus.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      title: Text(
                        themeStatus == ThemeStatus.dark
                            ? 'Φωτεινό θέμα'
                            : 'Σκούρο θέμα',
                      ),
                      onTap: context.read<ThemeProvider>().changeTheme,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        child: Text(_initial(user?.displayName, user?.email)),
                      ),
                      title: Text(
                        (user?.displayName ?? '').isEmpty
                            ? (user?.email ?? 'Χρήστης')
                            : user!.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        user?.storeRole == 'staff' ? 'Προσωπικό' : 'Διαχείριση',
                      ),
                      trailing: IconButton(
                        tooltip: 'Αποσύνδεση',
                        onPressed: context.read<AuthProvider>().signout,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initial(String? name, String? email) {
    final value = (name ?? '').trim().isNotEmpty ? name!.trim() : email ?? 'Χ';
    return value.isEmpty ? 'Χ' : value.characters.first.toUpperCase();
  }
}
