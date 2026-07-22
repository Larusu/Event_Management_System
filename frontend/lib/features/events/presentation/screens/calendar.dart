import "package:flutter/material.dart";
import 'package:provider/provider.dart';

import "../../../../core/constants/app_branches.dart";
import "../../../../shared/widgets/header.dart";
import "../../../../shared/widgets/tab_focus_refresher.dart";
import "../../providers/calendar_provider.dart";
import "../widgets/calendar_month_grid.dart";
import "../widgets/calendar_time_grid.dart";

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    // The provider is scoped to this screen; the Header (view + date nav) and
    // the calendar body both read from it. The title is derived from the
    // provider's focused date inside the Header, so `header` is unused here.
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider()..load(),
      child: Builder(
        builder: (context) => TabFocusRefresher(
          branch: AppBranches.calendar,
          onRefresh: () => context.read<CalendarProvider>().refreshIfStale(),
          child: const Column(
            children: [
              Header(
                header: 'Calendar',
                views: ['Month', 'Day', 'Week'],
                page: 'calendar',
              ),
              Expanded(child: _CalendarBody()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switches between the calendar views and renders the load / error states.
class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();

    if (calendar.status == CalendarStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (calendar.status == CalendarStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            calendar.errorMessage ?? 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Day and Week share the time-grid; Month is a separate square grid.
    if (calendar.viewMode == CalendarViewMode.month) {
      return const CalendarMonthGrid();
    }
    return const CalendarTimeGrid();
  }
}
