import 'dart:async';
import '../../styling/themes/legacy_widget_bridge.dart';
import '../responsive_ui/appointments/appointment_editor.dart';
import '../responsive_ui/widgets/web_app_shell.dart';
import 'package:material_ui/material_ui.dart';
import '../../repositories/store_repository.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'widgets/calendar_layout_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/search%20user/search_user_provider.dart';
import 'package:scheldule/screens/calendar/widgets/customer_side.dart';
import 'package:scheldule/screens/calendar/widgets/customer_side_mobile.dart';
import 'package:scheldule/styling/fonts/textstyle.dart';
import 'package:scheldule/utils/colors.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:scheldule/models/appointment_model.dart' as app;

import '../../constants/device_sizes.dart';
import '../../repositories/api_client.dart';
import '../../repositories/appointment_repository.dart';

class SyncFusionCalendar extends StatefulWidget {
  const SyncFusionCalendar({super.key});

  @override
  State<SyncFusionCalendar> createState() => _SyncFusionCalendarState();
}

class _SyncFusionCalendarState extends State<SyncFusionCalendar> {
  CalendarController _controller = CalendarController();
  CalendarLayout? _renderedLayout;
  Offset? _doubleTapPosition;
  bool _creatingAppointment = false;

  Future<void> _createAppointmentAtTap() async {
    final position = _doubleTapPosition;
    if (position == null || _creatingAppointment) return;
    final details = _controller.getCalendarDetailsAtOffset?.call(position);
    if (details?.targetElement != CalendarElement.calendarCell ||
        details?.date == null) {
      return;
    }
    _creatingAppointment = true;
    try {
      await showAppointmentEditor(context, null, initialStart: details!.date);
    } finally {
      _creatingAppointment = false;
    }
  }

  DateTime _displayDate = DateTime.now();
  DateTime? _selectedDate;
  List<AppointMent> appointment = [];
  final _appointmentsSnapshot =
      ValueNotifier<AsyncSnapshot<List<app.AppointMent>>>(
    const AsyncSnapshot.waiting(),
  );
  final _todaySnapshot = ValueNotifier<AsyncSnapshot<List<app.AppointMent>>>(
    const AsyncSnapshot.waiting(),
  );
  StreamSubscription<List<app.AppointMent>>? _appointmentsSubscription;
  StreamSubscription<List<app.AppointMent>>? _todaySubscription;
  List<int> _workingDays = List.of(StoreRepository.defaultWorkingDays);
  StreamSubscription<void>? _storeChanges;
  StreamSubscription<int>? _storeSessionChanges;
  int _storeRequest = 0;

  Future<void> _loadWorkingDays(StoreRepository repository) async {
    final request = ++_storeRequest;
    final revision = repository.apiClient.sessionRevision;
    try {
      final days = await repository.getWorkingDays();
      if (mounted &&
          request == _storeRequest &&
          revision == repository.apiClient.sessionRevision) {
        setState(() => _workingDays = days);
      }
    } catch (_) {
      // Keep the current layout if the store settings request is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.displayDate = DateTime.now();
    final repository = context.read<AppointmentRepository>();
    final store = StoreRepository(apiClient: repository.apiClient);
    _loadWorkingDays(store);
    _storeChanges = store.changes.listen((_) => _loadWorkingDays(store));
    _storeSessionChanges = repository.apiClient.sessionChanges.listen((_) {
      setState(
          () => _workingDays = List.of(StoreRepository.defaultWorkingDays));
      _loadWorkingDays(store);
    });
    // Subscribe once for this calendar's lifetime. Responsive layouts can
    // replace their builders without listening to a single-subscription stream again.
    _appointmentsSubscription = repository.streamAppointment().listen(
          (data) => _appointmentsSnapshot.value =
              AsyncSnapshot.withData(ConnectionState.active, data),
          onError: (Object error, StackTrace stack) =>
              _appointmentsSnapshot.value =
                  AsyncSnapshot.withError(ConnectionState.active, error, stack),
        );
    _todaySubscription = repository.streamTodayAppointment().listen(
          (data) => _todaySnapshot.value =
              AsyncSnapshot.withData(ConnectionState.active, data),
          onError: (Object error, StackTrace stack) => _todaySnapshot.value =
              AsyncSnapshot.withError(ConnectionState.active, error, stack),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().initEmployees();
    });
  }

  void calendarPicker(CalendarTapDetails details) async {
    if (details.targetElement == CalendarElement.appointment) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () async {
                            context
                                .read<AppointmentProvider>()
                                .deleteAppointments(
                                    details.appointments![0].id.toString());
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                        Text('Διαγραφή'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Future<void> showEditDialog(AppointMent appointment) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            height: 300,
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ασθενης: ${appointment.eventName}',
                    style: TextStyles().seeAppointment,
                  ),
                  Text(
                    'Ραντεβού: ${appointment.from.toString()}',
                    style: TextStyles().seeAppointment,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteAppointment({
    required DateTime selectedDay1,
    required DateTime endOfDay,
  }) async {
    context.read<AppointmentProvider>().getAppointMents(selectedDay1, endOfDay);
  }

  Future<void> _rescheduleAppointment(
    AppointmentDragEndDetails details,
    List<app.AppointMent> appointments,
  ) async {
    final calendarAppointment = details.appointment;
    final droppingTime = details.droppingTime;
    if (calendarAppointment is! AppointMent || droppingTime == null) return;

    app.AppointMent? appointmentToMove;
    for (final appointment in appointments) {
      if (appointment.id == calendarAppointment.id) {
        appointmentToMove = appointment;
        break;
      }
    }
    if (appointmentToMove == null || appointmentToMove.date == null) return;

    final previousStart = appointmentToMove.date!.toDate();
    if (previousStart.isAtSameMomentAs(droppingTime)) return;

    try {
      await context.read<AppointmentRepository>().rescheduleAppointment(
            appointment: appointmentToMove,
            start: droppingTime,
          );
      if (!mounted) return;
      snackBarDialog(
        context,
        color: Colors.green,
        message:
            'Το ραντεβού μεταφέρθηκε στις ${DateFormat('dd-MM-yyyy HH:mm').format(droppingTime)}',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {});
      snackBarDialog(
        context,
        color: Colors.red,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {});
      snackBarDialog(
        context,
        color: Colors.red,
        message: 'Δεν ήταν δυνατή η μεταφορά του ραντεβού',
      );
    }
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _todaySubscription?.cancel();
    _appointmentsSnapshot.dispose();
    _todaySnapshot.dispose();
    _storeChanges?.cancel();
    _storeSessionChanges?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DeviceSizes.mobileSize) {
          return _mobile();
        } else {
          // Keep the former one-third width with the full sidebar open.
          // Collapsing navigation then gives its entire saved width to the calendar.
          final hasSidebar =
              context.findAncestorWidgetOfExactType<WebAppShell>() != null;
          final baseWidth = hasSidebar
              ? MediaQuery.sizeOf(context).width - 280
              : constraints.maxWidth;
          return _desktop(
              (baseWidth / 3).clamp(220.0, constraints.maxWidth / 2));
        }
      },
    );
  }

  Widget _buildCalendar(
    List<app.AppointMent> appointments,
    Map<String, Color> employeeColors, {
    bool compact = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final preferences = context.watch<UiPreferencesProvider>();
    final layout = CalendarLayout.fromKey(
      preferences.value('calendar_layout',
          fallback: compact ? 'day' : 'workWeek'),
      compact: compact,
    );
    if (_renderedLayout != layout) {
      final previousController = _controller;
      _controller = CalendarController()
        ..displayDate = _selectedDate ?? _displayDate
        ..selectedDate = _selectedDate
        ..view = layout.view;
      _renderedLayout = layout;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => previousController.dispose());
    }
    final grouped = layout == CalendarLayout.resources;
    final customMonth = layout == CalendarLayout.heatmap ||
        layout == CalendarLayout.dailySummary;
    final employees = context.watch<EmployeeProvider>().employees;
    final source = MeetingDataSource.fromAppointments(
      appointments,
      employeeColors,
      employees: employees,
      groupByEmployee: grouped,
    );
    final summaries = <DateTime, _DailyCalendarSummary>{};
    for (final appointment in appointments) {
      if (appointment.status == 'cancelled' || appointment.date == null) {
        continue;
      }
      final date = DateUtils.dateOnly(appointment.date!.toDate());
      final current = summaries[date] ?? const _DailyCalendarSummary(0, 0);
      summaries[date] = _DailyCalendarSummary(current.count + 1,
          current.minutes + appointment.effectiveDurationMinutes);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withAlpha(150)),
      ),
      child: Column(
        children: [
          CalendarLayoutPicker(
            selected: layout,
            error: preferences.error,
            onChanged: (selected) => _saveCalendarLayout(selected),
          ),
          Divider(height: 1, color: colors.outlineVariant.withAlpha(120)),
          Expanded(
              child: GestureDetector(
                  onDoubleTapDown: (details) =>
                      _doubleTapPosition = details.localPosition,
                  onDoubleTap: _createAppointmentAtTap,
                  child: LegacyWidgetBridge(
                      child: SfCalendar(
                    key: ValueKey(layout),
                    allowDragAndDrop: true,
                    controller: _controller,
                    showNavigationArrow: true,
                    showDatePickerButton: true,
                    allowViewNavigation: !customMonth && !grouped,
                    view: layout.view,
                    initialSelectedDate: _selectedDate ?? DateTime.now(),
                    onViewChanged: (details) {
                      if (details.visibleDates.isNotEmpty) {
                        _displayDate = details
                            .visibleDates[details.visibleDates.length ~/ 2];
                      }
                      final actual = _controller.view;
                      if (actual != null && actual != layout.view && mounted) {
                        final next = CalendarLayout.values
                            .firstWhere((item) => item.view == actual);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _renderedLayout == layout) {
                            _saveCalendarLayout(next);
                          }
                        });
                      }
                    },
                    firstDayOfWeek: DateTime.monday,
                    backgroundColor: colors.surface,
                    cellBorderColor: colors.outlineVariant.withAlpha(65),
                    todayHighlightColor: colors.primary,
                    todayTextStyle: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectionDecoration: BoxDecoration(
                      color: colors.primary.withAlpha(12),
                      border: Border.all(
                          color: colors.primary.withAlpha(160), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    headerHeight: compact ? 54 : 62,
                    viewHeaderHeight: compact ? 56 : 64,
                    headerDateFormat: compact ? 'EEEE, d MMMM' : 'MMMM y',
                    headerStyle: CalendarHeaderStyle(
                      textAlign: TextAlign.left,
                      backgroundColor: colors.surface,
                      textStyle: TextStyle(
                        color: colors.onSurface,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    viewHeaderStyle: ViewHeaderStyle(
                      backgroundColor: colors.surface,
                      dayTextStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      dateTextStyle: TextStyle(
                        color: colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    timeSlotViewSettings: TimeSlotViewSettings(
                      timeInterval: Duration(minutes: compact ? 30 : 60),
                      timeIntervalHeight: compact ? 60 : 64,
                      startHour: 7,
                      endHour: 23,
                      timeFormat: 'HH:mm',
                      timeTextStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      nonWorkingDays: [
                        for (var day = 1; day <= 7; day++)
                          if (!_workingDays.contains(day)) day,
                      ],
                    ),
                    minDate: DateTime(2022, 1, 1, 10),
                    maxDate: DateTime(2100, 1, 1, 10),
                    appointmentBuilder: _buildAppointment,
                    onTap: (details) {
                      if (details.date != null) {
                        setState(() => _selectedDate = details.date);
                      }
                      calendarPicker(details);
                    },
                    onDragEnd: (details) {
                      if (grouped &&
                          details.sourceResource?.id !=
                              details.targetResource?.id) {
                        setState(() {});
                        snackBarDialog(context,
                            color: Colors.red,
                            message:
                                'Αλλάξτε εργαζόμενο από την επεξεργασία του ραντεβού.');
                        return;
                      }
                      _rescheduleAppointment(details, appointments);
                    },
                    resourceViewSettings: ResourceViewSettings(
                      showAvatar: false,
                      size: compact ? 100 : 150,
                      displayNameTextStyle: TextStyle(
                          color: colors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    scheduleViewSettings: ScheduleViewSettings(
                      appointmentItemHeight: 66,
                      hideEmptyScheduleWeek: true,
                      monthHeaderSettings: MonthHeaderSettings(
                        height: 60,
                        backgroundColor: colors.surfaceContainerLow,
                        monthTextStyle: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                    monthViewSettings: MonthViewSettings(
                      showAgenda: true,
                      agendaItemHeight: 58,
                      agendaViewHeight: compact ? 165 : 200,
                      appointmentDisplayMode: customMonth
                          ? MonthAppointmentDisplayMode.none
                          : MonthAppointmentDisplayMode.indicator,
                      monthCellStyle: MonthCellStyle(
                        textStyle: TextStyle(color: colors.onSurface),
                        trailingDatesTextStyle:
                            TextStyle(color: colors.onSurfaceVariant),
                        leadingDatesTextStyle:
                            TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                    monthCellBuilder: customMonth
                        ? (context, details) => _buildMonthSummary(
                            context, details, layout, summaries)
                        : null,
                    dataSource: source,
                  )))),
        ],
      ),
    );
  }

  Future<void> _saveCalendarLayout(CalendarLayout layout) async {
    final preferences = context.read<UiPreferencesProvider>();
    final saved = await preferences.setValue('calendar_layout', layout.key);
    if (!saved && mounted && preferences.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(preferences.error!)));
    }
  }

  Widget _buildMonthSummary(BuildContext context, MonthCellDetails details,
      CalendarLayout layout, Map<DateTime, _DailyCalendarSummary> summaries) {
    final colors = Theme.of(context).colorScheme;
    final day = details.date;
    final daily =
        summaries[DateUtils.dateOnly(day)] ?? const _DailyCalendarSummary(0, 0);
    final maxCount = details.visibleDates.fold<int>(1, (largest, date) {
      final count = summaries[DateUtils.dateOnly(date)]?.count ?? 0;
      return count > largest ? count : largest;
    });
    final selected = _selectedDate ?? DateTime.now();
    final isSelected = DateUtils.isSameDay(day, selected);
    final today = DateUtils.isSameDay(day, DateTime.now());
    final heatmap = layout == CalendarLayout.heatmap;
    final trailing = details.visibleDates.isNotEmpty &&
        day.month !=
            details.visibleDates[details.visibleDates.length ~/ 2].month;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 70;
      final short = constraints.maxHeight < 42;
      return Container(
        margin: const EdgeInsets.all(2),
        padding: EdgeInsets.all(narrow ? 3 : 6),
        decoration: BoxDecoration(
          color: heatmap && daily.count > 0
              ? Color.alphaBlend(
                  colors.primary.withAlpha((25 + 100 * daily.count / maxCount)
                      .round()
                      .clamp(0, 140)),
                  colors.surface)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withAlpha(90),
              width: isSelected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
              child: Text('${day.day}',
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: today ? FontWeight.w800 : FontWeight.w500,
                      color: today
                          ? colors.primary
                          : trailing
                              ? colors.onSurfaceVariant
                              : colors.onSurface))),
          if (!short) ...[
            const SizedBox(height: 2),
            Text(narrow ? '${daily.count}' : '${daily.count} ραντ.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: narrow ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface)),
            if (!heatmap && constraints.maxHeight >= 58)
              Flexible(
                  child: Text(
                      narrow ? '${daily.minutes}′' : '${daily.minutes} λεπτά',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10, color: colors.onSurfaceVariant))),
          ],
        ]),
      );
    });
  }

  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final appointment = details.appointments.first as AppointMent;
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color.lerp(
      appointment.background,
      dark ? Colors.white : Colors.black,
      dark ? 0.35 : 0.2,
    )!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showTime =
            constraints.maxHeight >= 46 && constraints.maxWidth >= 100;
        final inset = constraints.maxHeight >= 30 ? 5.0 : 1.0;
        return Semantics(
          label: '${appointment.eventName}, '
              '${DateFormat('HH:mm').format(appointment.from)} – '
              '${DateFormat('HH:mm').format(appointment.to)}',
          child: Container(
            margin: const EdgeInsets.all(1),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                appointment.background.withAlpha(dark ? 50 : 35),
                colors.surface,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withAlpha(25)),
            ),
            child: Row(
              children: [
                Container(width: 2, color: accent.withAlpha(140)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth >= 70 ? 7 : 2,
                      vertical: inset,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (constraints.maxHeight >= 70) ...[
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: accent, shape: BoxShape.circle)),
                          const SizedBox(height: 4),
                        ],
                        Flexible(
                          child: Text(
                            appointment.serviceLabel.isEmpty
                                ? appointment.eventName
                                : appointment.serviceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (constraints.maxHeight >= 95 &&
                            appointment.serviceLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(appointment.eventName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10)),
                        ],
                        if (showTime) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('HH:mm').format(appointment.from)} – '
                            '${DateFormat('HH:mm').format(appointment.to)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row _desktop(double todayPanelWidth) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _appointmentsSnapshot,
            builder: (context, snapshot, child) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
              }
              final appointments = (snapshot.data ?? <app.AppointMent>[])
                  .where((appointment) => appointment.date != null)
                  .toList();

              final employeeProvider = context.watch<EmployeeProvider>();

              final Map<String, Color> employeeColorMap = {
                for (final emp in employeeProvider.employees)
                  '${emp.name} ${emp.surname}':
                      hexToColors(emp.color) ?? Colors.blueAccent,
              };
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildCalendar(appointments, employeeColorMap),
              );
            },
          ),
        ),
        SizedBox(
          key: const ValueKey('calendar-today-panel'),
          width: todayPanelWidth,
          child: ValueListenableBuilder(
            valueListenable: _todaySnapshot,
            builder: (context, snapshot, child) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
              }
              final appointments = snapshot.data ?? <app.AppointMent>[];
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: colors.outlineVariant.withAlpha(150)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.today_outlined,
                            size: 20, color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Σημερινά ραντεβού',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('${appointments.length}',
                            style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (appointments.isEmpty)
                      Expanded(
                          child: Center(
                              child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 36, color: colors.primary),
                          const SizedBox(height: 12),
                          Text('Δεν υπάρχουν σημερινά ραντεβού',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant)),
                        ],
                      )))
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: snapshot.data?.length,
                          itemBuilder: (context, index) {
                            var appoint = snapshot.data?[index];

                            return GestureDetector(
                              onTap: () async {
                                final List<app.AppointMent> customer =
                                    await context
                                        .read<SearchUserProvider>()
                                        .searchUsers();
                                if (!context.mounted) return;

                                final finalCustomer = customer.firstWhere(
                                  (cus) => cus.id == appoint.clientId,
                                  orElse: () => app.AppointMent.initial(),
                                );

                                await _showSideDialog(
                                    context, finalCustomer, appoint);
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                clipBehavior: Clip.antiAlias,
                                color: colors.surfaceContainerLow,
                                child: Dismissible(
                                  key: Key(appoint!.id),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                              'Διαγραφή ραντεβού με ${appoint.name} ${appoint.surname}?'),
                                          actions: [
                                            SendButton(
                                                backgroundColor: Colors.green,
                                                icon: Icons.thumb_up_outlined,
                                                onPressed: () {
                                                  context
                                                      .read<
                                                          AppointmentProvider>()
                                                      .deleteAppointments(
                                                          appoint.id
                                                              .toString());
                                                  snackBarDialog(context,
                                                      color: Colors.red,
                                                      message:
                                                          'Το ραντεβού με πελάτη ${appoint.name} ${appoint.surname} διαγράφθηκε');
                                                  Navigator.pop(context, true);
                                                },
                                                text: 'Ναι'),
                                            SendButton(
                                                backgroundColor: Colors.red,
                                                icon: Icons.delete,
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                text: 'Όχι')
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  direction: DismissDirection.startToEnd,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child:
                                        Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: _todayAppointmentDetails(appoint),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _todayAppointmentDetails(app.AppointMent appointment) {
    final colors = Theme.of(context).colorScheme;
    final date = appointment.date?.toDate();
    final services = appointment.serviceItems
        .map((line) => line.serviceName)
        .where((name) => name.trim().isNotEmpty)
        .join(' · ');
    final employee = (appointment.employee ?? '').trim();
    final position = (appointment.position ?? '').trim();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.schedule_rounded, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(date == null ? '—' : DateFormat('HH:mm').format(date),
              style: TextStyle(
                  color: colors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(
              child: Text('${appointment.effectiveDurationMinutes} λεπτά',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant))),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: colors.onSurfaceVariant),
        ]),
        const SizedBox(height: 12),
        Text('${appointment.name} ${appointment.surname}'.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface, fontWeight: FontWeight.w700)),
        if (services.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(services,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant)),
        ],
        if (employee.isNotEmpty || position.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (employee.isNotEmpty)
            Row(children: [
              Icon(Icons.person_outline_rounded,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(employee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant))),
            ]),
          if (position.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.place_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(position,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant))),
            ]),
          ],
        ],
      ]),
    );
  }

  Future<Object?> _showSideDialog(
      BuildContext context, app.AppointMent customer, app.AppointMent appoint) {
    return showGeneralDialog(
        context: context,
        barrierColor: Colors.black.withAlpha(90),
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(24)),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              width: MediaQuery.sizeOf(context).width.clamp(0, 560),
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomerSide(
                  customer: customer,
                  appointMent: appoint,
                ),
              ),
            ),
          );
        });
  }

  SingleChildScrollView _mobile() {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.today_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Το πρόγραμμά σου σήμερα',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        _friendlyDate(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: _appointmentsSnapshot,
              builder: (context, snapshot, child) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
                }
                final appointments = (snapshot.data ?? <app.AppointMent>[])
                    .where((appointment) => appointment.date != null)
                    .toList();

                final employeeProvider = context.watch<EmployeeProvider>();

                final Map<String, Color> employeeColorMap = {
                  for (final emp in employeeProvider.employees)
                    '${emp.name} ${emp.surname}':
                        hexToColors(emp.color) ?? Colors.blueAccent,
                };
                return SizedBox(
                  height: CalendarLayout.fromKey(context
                                  .watch<UiPreferencesProvider>()
                                  .value('calendar_layout', fallback: 'day'))
                              .view ==
                          CalendarView.month
                      ? 780
                      : 650,
                  child: _buildCalendar(
                    appointments,
                    employeeColorMap,
                    compact: true,
                  ),
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: _todaySnapshot,
              builder: (context, snapshot, child) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
                }
                final appointments = snapshot.data ?? <app.AppointMent>[];
                if (appointments.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: colors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Δεν υπάρχουν άλλα σημερινά ραντεβού',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    child: Column(
                      spacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withAlpha(120),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TodayMetric(
                                  label: 'Ραντεβού',
                                  value: appointments.length.toString(),
                                  icon: Icons.event_note_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...List.generate(appointments.length, (index) {
                          var appoint = appointments[index];
                          return InkWell(
                            onTap: () async {
                              final List<app.AppointMent> customer =
                                  await context
                                      .read<SearchUserProvider>()
                                      .searchUsers();
                              if (!context.mounted) return;

                              final finalCustomer = customer.firstWhere(
                                (cus) => cus.id == appoint.clientId,
                                orElse: () => app.AppointMent.initial(),
                              );
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerSideMobile(
                                      customer: finalCustomer,
                                      appointMent: appoint,
                                    ),
                                  ));
                            },
                            child: Dismissible(
                              key: Key(appoint.id),
                              confirmDismiss: (direction) {
                                return showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Διαγραφή ραντεβού με ${appoint.name} ${appoint.surname}?'),
                                      actions: [
                                        SendButton(
                                            backgroundColor: Colors.green,
                                            icon: Icons.thumb_up_outlined,
                                            onPressed: () async {
                                              await context
                                                  .read<AppointmentProvider>()
                                                  .deleteAppointments(
                                                      appoint.id.toString());
                                              if (!context.mounted) return;
                                              snackBarDialog(context,
                                                  color: Colors.red,
                                                  message:
                                                      'Το ραντεβού με πελάτη ${appoint.name} ${appoint.surname} διαγράφθηκε');
                                              Navigator.pop(context, true);
                                            },
                                            text: 'Ναι'),
                                        SendButton(
                                            backgroundColor: Colors.red,
                                            icon: Icons.delete,
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            text: 'Όχι')
                                      ],
                                    );
                                  },
                                );
                              },
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: colors.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colors.onErrorContainer,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Text(
                                        appoint.date == null
                                            ? '--:--'
                                            : DateFormat('HH:mm').format(
                                                appoint.date!.toDate(),
                                              ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.onPrimaryContainer,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${appoint.name} ${appoint.surname}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              appoint.employee ?? '',
                                              appoint.position ?? '',
                                            ]
                                                .where(
                                                  (value) =>
                                                      value.trim().isNotEmpty,
                                                )
                                                .join(' • '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  String _friendlyDate(DateTime date) {
    const weekdays = [
      'Δευτέρα',
      'Τρίτη',
      'Τετάρτη',
      'Πέμπτη',
      'Παρασκευή',
      'Σάββατο',
      'Κυριακή',
    ];
    const months = [
      'Ιανουαρίου',
      'Φεβρουαρίου',
      'Μαρτίου',
      'Απριλίου',
      'Μαΐου',
      'Ιουνίου',
      'Ιουλίου',
      'Αυγούστου',
      'Σεπτεμβρίου',
      'Οκτωβρίου',
      'Νοεμβρίου',
      'Δεκεμβρίου',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _DailyCalendarSummary {
  final int count;
  final int minutes;
  const _DailyCalendarSummary(this.count, this.minutes);
}

class _TodayMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TodayMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21, color: colors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MeetingDataSource extends CalendarDataSource<AppointMent> {
  MeetingDataSource(List<AppointMent> source) {
    appointments = source;
  }

  factory MeetingDataSource.fromAppointments(
    List<app.AppointMent> source,
    Map<String, Color> employeeColors, {
    List<Employee> employees = const [],
    bool groupByEmployee = false,
  }) {
    final resourceMap = <String, CalendarResource>{
      for (final employee in employees)
        employee.id: CalendarResource(
          id: employee.id,
          displayName: '${employee.name} ${employee.surname}'.trim(),
          color: hexToColors(employee.color) ?? Colors.blueAccent,
        ),
    };
    final events = source.where((item) => item.date != null).map((item) {
      final start = item.date!.toDate();
      final resourceIds = <Object>{};
      if (groupByEmployee) {
        final names = <String, String>{
          if (item.employeeId.isNotEmpty) item.employeeId: item.employee ?? '',
          for (final line in item.serviceItems)
            if (line.employeeId.isNotEmpty) line.employeeId: line.employeeName,
        };
        for (final entry in names.entries) {
          resourceMap.putIfAbsent(
              entry.key,
              () => CalendarResource(
                    id: entry.key,
                    displayName: entry.value.trim().isEmpty
                        ? 'Εργαζόμενος'
                        : entry.value,
                    color: employeeColors[entry.value] ?? Colors.blueAccent,
                  ));
          resourceIds.add(entry.key);
        }
        if (resourceIds.isEmpty) resourceIds.add('unassigned');
      }
      return AppointMent(
        '${item.name} ${item.surname}', item.id, start,
        start.add(Duration(minutes: item.effectiveDurationMinutes)),
        employeeColors[item.employee] ?? const Color(0xFF84AD94),
        item.surname, item.phone, item.email, item.address, item.paid,
        '', // Client fields must never be interpreted as recurrence rules.
        resourceIds: resourceIds.toList(),
        serviceLabel: item.serviceItems
            .map((line) => line.serviceName)
            .where((name) => name.isNotEmpty)
            .join(' · '),
      );
    }).toList();
    final dataSource = MeetingDataSource(events);
    if (groupByEmployee) {
      resourceMap['unassigned'] = CalendarResource(
        id: 'unassigned',
        displayName: 'Χωρίς ανάθεση',
        color: Colors.blueGrey,
      );
      dataSource.resources = resourceMap.values.toList();
    }
    return dataSource;
  }

  @override
  List<Object> getResourceIds(int index) => appointments![index].resourceIds;

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  String getId(int index) {
    return appointments![index].id;
  }

  // String getDescription(int index) {
  //   return appointments![index].description;
  // }

  @override
  String getRecurrenceRule(int index) {
    return appointments![index].recurrenceRule;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  AppointMent convertAppointmentToObject(
    AppointMent customData,
    Appointment appointment,
  ) {
    return AppointMent(
      appointment.subject,
      customData.id,
      appointment.startTime,
      appointment.endTime,
      appointment.color,
      customData.surname,
      customData.phone,
      customData.email,
      customData.address,
      customData.paid,
      appointment.recurrenceRule ?? '',
      resourceIds: customData.resourceIds,
      serviceLabel: customData.serviceLabel,
    );
  }
}

class AppointMent extends CalendarDataSource {
  AppointMent(
    this.eventName,
    this.id,
    this.from,
    this.to,
    this.background,
    this.surname,
    this.phone,
    this.email,
    this.address,
    this.paid,
    // this.description,
    this.recurrenceRule, {
    this.resourceIds = const [],
    this.serviceLabel = '',
  });

  String eventName;
  String id;
  DateTime from;
  DateTime to;
  Color background;
  String surname;
  String phone;
  String email;
  String address;
  int? paid;
  // String description;
  String recurrenceRule;
  final List<Object> resourceIds;
  final String serviceLabel;

  // bool isAllDay;
}
