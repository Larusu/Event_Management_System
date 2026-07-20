import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/calendar_provider.dart';

/// The Month view: a 7-column square grid for the focused month. Days with at
/// least one event get a dot; today is highlighted; tapping a day drills into
/// the Day view.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({super.key});

  static const List<String> _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const Color _eventDotColor = Color(0xFF4C7F9F);

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarProvider>();
    final focused = calendar.focusedDate;

    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
    // Blank leading cells so day 1 lands under its weekday (Sunday-start).
    final leadingBlanks = DateTime(focused.year, focused.month, 1).weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();

              final day = index - leadingBlanks + 1;
              final date = DateTime(focused.year, focused.month, day);
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final hasEvents = calendar.eventsOn(date).isNotEmpty;

              return _DayCell(
                date: date,
                isToday: isToday,
                hasEvents: hasEvents,
                onTap: () => calendar.openDay(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool hasEvents;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.hasEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? primary : Colors.transparent,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasEvents
                  ? CalendarMonthGrid._eventDotColor
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
