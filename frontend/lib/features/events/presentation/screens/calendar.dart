import "package:flutter/material.dart";
import 'package:intl/intl.dart';

import "../../../../shared/widgets/navbar.dart";
import "../../../../shared/widgets/header.dart";

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(220),
        child: Header(
          header: DateFormat('MMMM yyyy').format(DateTime.now()),
          views: ['Month', 'Day', 'Week'],
          page: 'calendar',
        ),
      ),
      bottomNavigationBar: NavBar(
        selectedPageIndex: _selectedPageIndex,
        onPageSelected: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
      ),
      body: const Center(child: Text('Calendar Page')),
    );
  }
}
