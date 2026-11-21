import 'package:material_ui/material_ui.dart';

class SectionTabItem {
  final String label;
  final IconData icon;

  const SectionTabItem(this.label, this.icon);
}

class SectionTabs extends StatelessWidget {
  final TabController controller;
  final List<SectionTabItem> tabs;
  final List<Widget> children;
  final bool scrollableContent;

  const SectionTabs({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
    this.scrollableContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final header = Container(
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
        );
    if (scrollableContent) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SingleChildScrollView(
          primary: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(children: [
            header,
            const SizedBox(height: 4),
            for (var index = 0; index < children.length; index++)
              Offstage(offstage: controller.index != index, child: children[index]),
          ]),
        ),
      );
    }
    return Column(
      children: [
        header,
        const SizedBox(height: 4),
        Expanded(
          child: TabBarView(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        ),
      ],
    );
  }
}
