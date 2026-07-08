import "package:flutter/material.dart";

class CalendarEvent extends StatefulWidget {
  final String title;
  final String date;
  final String startTime;
  final String endTime;

  const CalendarEvent({
    super.key,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<CalendarEvent> createState() => _CalendarEventState();
}

class _CalendarEventState extends State<CalendarEvent> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title),
          Text("${widget.startTime} - ${widget.endTime}"),
        ]));
  }
}
