import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../providers/ui_preferences/ui_preferences_provider.dart';

class ListGridToggle extends StatelessWidget {
  final String preferenceKey;
  const ListGridToggle({super.key, required this.preferenceKey});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesProvider>();
    final selected = preferences.value(preferenceKey, fallback: 'list');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: 'list',
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('Λίστα')),
              ButtonSegment(
                  value: 'grid',
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Πλέγμα')),
            ],
            selected: {selected},
            onSelectionChanged: (values) async {
              final saved =
                  await preferences.setValue(preferenceKey, values.first);
              if (!saved && context.mounted && preferences.error != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(preferences.error!)));
              }
            },
          ),
          if (preferences.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(preferences.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
