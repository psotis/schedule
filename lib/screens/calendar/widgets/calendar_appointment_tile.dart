import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class CalendarAppointmentTile extends StatelessWidget {
  const CalendarAppointmentTile({
    super.key,
    required this.customer,
    required this.start,
    required this.end,
    required this.background,
  });

  final String customer;
  final DateTime start;
  final DateTime end;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final time =
        '${DateFormat('HH:mm').format(start)} – '
        '${DateFormat('HH:mm').format(end)}';
    final accent = Color.lerp(
      background,
      dark ? Colors.white : Colors.black,
      dark ? 0.35 : 0.2,
    )!;
    return Tooltip(
      message: '$customer\n$time',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 120;
          final fontSize = narrow ? 11.0 : 12.0;
          final padding = constraints.maxHeight < 30 ? 1.0 : 3.0;
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - padding * 2 - 2,
          );
          // Reserve secondary information only after giving the name room to wrap.
          final showTime = !narrow && availableHeight >= 65;
          final nameHeight = math.max(
            0.0,
            availableHeight - (showTime ? 16 : 0),
          );
          final lineHeight =
              fontSize * 1.15 * MediaQuery.textScalerOf(context).scale(1);
          final lines = math.max(1, (nameHeight / lineHeight).floor());
          return Semantics(
            label: '$customer, $time',
            child: Container(
              margin: const EdgeInsets.all(1),
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 3 : 6,
                vertical: padding,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  background.withAlpha(dark ? 50 : 35),
                  colors.surface,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: accent, width: 2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      customer.trim(),
                      softWrap: true,
                      maxLines: lines,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: fontSize,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showTime) ...[
                    const SizedBox(height: 2),
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
