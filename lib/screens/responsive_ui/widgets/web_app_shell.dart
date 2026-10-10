import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/logos/photos_gifs.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
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
    final canManage =
        user?.storeRole == 'owner' || user?.storeRole == 'manager';
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
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          minimum: const EdgeInsets.all(14),
          child: Row(
            children: [
              _DesktopSidebar(navigation: navigation, current: current),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    AppPageHeader(item: current),
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
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          minimum: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(245),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  selectedIndex: navigation.indexOf(current),
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  groupAlignment: -.65,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _logo(52),
                  ),
                  destinations: navigation
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                  onDestinationSelected: (index) =>
                      _select(context, navigation[index]),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IconButton(
                          tooltip: 'Αποσύνδεση',
                          onPressed: context.read<AuthProvider>().signout,
                          icon: const Icon(Icons.logout_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    AppPageHeader(item: current, compact: true),
                    Expanded(
                      child: AppContentSurface(
                        borderRadius: BorderRadius.circular(22),
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
                            ? (user?.email ?? 'My Schedule')
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
          Media.logoGif,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
}

class _DesktopSidebar extends StatelessWidget {
  final List<AppNavigationItem> navigation;
  final AppNavigationItem current;

  const _DesktopSidebar({required this.navigation, required this.current});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().state.user;
    final themeStatus = context.watch<ThemeProvider>().state?.themeStatus;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: dark ? const Color(0xF21A211F) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x26001816), blurRadius: 28),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    Media.logoGif,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Schedule',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        'Business workspace',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: navigation.length,
              separatorBuilder: (context, index) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final item = navigation[index];
                final selected = item.status == current.status;
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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String? name, String? email) {
    final value = (name ?? '').trim().isNotEmpty ? name!.trim() : email ?? 'Χ';
    return value.isEmpty ? 'Χ' : value.characters.first.toUpperCase();
  }
}
