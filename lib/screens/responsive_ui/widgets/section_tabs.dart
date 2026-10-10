import 'package:flutter/material.dart';

class SectionTabItem {
  final String label;
  final IconData icon;

  const SectionTabItem(this.label, this.icon);
}

class SectionTabs extends StatelessWidget {
  final TabController controller;
  final List<SectionTabItem> tabs;
  final List<Widget> children;

  const SectionTabs({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: tabs
                .map(
                  (tab) => Tab(
                    height: 48,
                    icon: Icon(tab.icon, size: 19),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                    text: tab.label,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: TabBarView(controller: controller, children: children),
        ),
      ],
    );
  }
}
