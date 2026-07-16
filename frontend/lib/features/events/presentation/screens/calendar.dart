import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import "../../../../shared/widgets/header.dart";
import '../widgets/calendar_events.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          header: DateFormat('MMMM yyyy').format(DateTime.now()),
          views: ['Month', 'Day', 'Week'],
          page: 'calendar',
        ),
        const Expanded(child: Center(child: Text('Calendar Page'))),
        CalendarEvent(
          date: '11/01/04',
          endTime: '11:00 pm',
          startTime: '9:00 pm',
          title: 'Hello World Po',
        ),
      ],
    );
  }
}
