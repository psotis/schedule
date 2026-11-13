import 'package:material_ui/material_ui.dart';

/// Keeps themes and localizations available to dependencies that still use
/// flutter/material.dart, including Syncfusion Calendar and flutter_colorpicker.
/// Remove this adapter once those dependencies migrate to material_ui.
class LegacyWidgetBridge extends StatelessWidget {
  final Widget child;

  const LegacyWidgetBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Flutter recommends this temporary bridge while dependencies migrate.
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(child: child);
  }
}
