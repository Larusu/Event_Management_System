import "package:flutter/material.dart";
import 'package:intl/intl.dart';

import "../../../../shared/widgets/header.dart";

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
      ],
    );
  }
}
