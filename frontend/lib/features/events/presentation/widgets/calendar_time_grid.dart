import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/calendar_provider.dart';
import 'calendar_events.dart';
import 'event_modal.dart';

/// The Day / Week time-grid body (Figma "Calendar Element", node 56:249).
///
/// A vertical timeline: hours run top-to-bottom, days run left-to-right, and
/// each event is a block whose vertical position and height come from its
/// start/end time. Reads everything from [CalendarProvider]; the Month view is
/// handled by a separate widget.
class CalendarTimeGrid extends StatelessWidget {
  const CalendarTimeGrid({super.key});

  static const int _startHour = 8; // 8:00 AM
  static const int _endHour = 18; // 6:00 PM
  static const double _hourHeight = 74; // px per hour (from the Figma spacing)
  static const double _allDayHeight = 40; // top "All Day" band
  static const double _gutterWidth = 66; // left time-label column
  static const double _eventInset = 2; // gap around each block
  static const double _minEventHeight = 22; // keep short events tappable

  static const Color _lineColor = Color(0x22000000);

  int get _hourCount => _endHour - _startHour;
  double get _totalHeight => _allDayHeight + _hourCount * _hourHeight;

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();
    final days = _visibleDays(calendar);

    return SingleChildScrollView(
      child: SizedBox(
        height: _totalHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnsWidth = constraints.maxWidth - _gutterWidth;
            final columnWidth =
                days.isEmpty ? columnsWidth : columnsWidth / days.length;

            return Stack(
              children: [
                ..._hourLines(),
                ..._columnDividers(days.length, columnWidth),
                ..._timeLabels(),
                _allDayLabel(),
                ..._eventBlocks(context, calendar, days, columnWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The day columns to render: one for Day view, the Sun-Sat span for Week.
  List<DateTime> _visibleDays(CalendarProvider calendar) {
    final f = calendar.focusedDate;
    final focused = DateTime(f.year, f.month, f.day);
    if (calendar.viewMode == CalendarViewMode.week) {
      final start = focused.subtract(Duration(days: focused.weekday % 7));
      return List.generate(7, (i) => start.add(Duration(days: i)));
    }
    return [focused];
  }

  List<Widget> _hourLines() => [
        for (int i = 0; i <= _hourCount; i++)
          Positioned(
            top: _allDayHeight + i * _hourHeight,
            left: 0,
            right: 0,
            child: Container(height: 1, color: _lineColor),
          ),
      ];

  List<Widget> _columnDividers(int count, double columnWidth) => [
        for (int i = 0; i <= count; i++)
          Positioned(
            top: 0,
            bottom: 0,
            left: _gutterWidth + i * columnWidth,
            child: Container(width: 1, color: _lineColor),
          ),
      ];

  List<Widget> _timeLabels() => [
        for (int h = _startHour; h <= _endHour; h++)
          Positioned(
            top: _allDayHeight + (h - _startHour) * _hourHeight - 8,
            left: 0,
            width: _gutterWidth - 6,
            child: Text(
              _formatHour(h),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
      ];

  Widget _allDayLabel() => const Positioned(
        top: 0,
        left: 0,
        width: _gutterWidth,
        height: _allDayHeight,
        child: Center(
          child: Text(
            'All Day',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );

  List<Widget> _eventBlocks(
    BuildContext context,
    CalendarProvider calendar,
    List<DateTime> days,
    double columnWidth,
  ) {
    final blocks = <Widget>[];
    for (var d = 0; d < days.length; d++) {
      for (final event in calendar.eventsOn(days[d])) {
        final startMin = _minutesOf(event.startTime);
        final endMin = _minutesOf(event.endTime);
        if (startMin == null || endMin == null) continue;

        // Map minutes-of-day onto the grid; clamp so out-of-window events
        // (before 8 AM / after 6 PM) still show at the edge instead of
        // overflowing.
        final rawTop = _yForMinutes(startMin);
        final rawBottom = _yForMinutes(endMin);
        final top = rawTop.clamp(_allDayHeight, _totalHeight).toDouble();
        final bottom = rawBottom.clamp(_allDayHeight, _totalHeight).toDouble();
        final height =
            (bottom - top).clamp(_minEventHeight, _totalHeight).toDouble();

        blocks.add(
          Positioned(
            top: top,
            height: height,
            left: _gutterWidth + d * columnWidth + _eventInset,
            width: columnWidth - 2 * _eventInset,
            child: CalendarEvent(
              title: event.title,
              startTime: event.startTime,
              endTime: event.endTime,
              onTap: () => EventModal.show(context, eventId: event.eventId),
            ),
          ),
        );
      }
    }
    return blocks;
  }

  double _yForMinutes(int minutes) =>
      _allDayHeight + (minutes - _startHour * 60) / 60 * _hourHeight;

  static int? _minutesOf(String hhmm) {
    try {
      final parts = hhmm.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return null;
    }
  }

  static String _formatHour(int hour) =>
      DateFormat('h:mm a').format(DateTime(0, 1, 1, hour));
}
