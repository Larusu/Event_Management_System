import "package:flutter/material.dart";
import 'package:intl/intl.dart';

/// A single event block as drawn inside the calendar time-grid (Figma nodes
/// 56:257 / 56:261). It is a pure visual: the time-grid positions and sizes it
/// via a [Positioned], so this widget just fills the space it is given.
class CalendarEvent extends StatelessWidget {
  final String title;
  final String startTime; // "HH:mm" (24h)
  final String endTime; // "HH:mm" (24h)
  final VoidCallback? onTap;

  const CalendarEvent({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.onTap,
  });

  static const Color _blockColor = Color(0xFF4C7F9F); // Figma --sec

  String _formatTime(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final t = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return hhmm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: _blockColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatTime(startTime)} - ${_formatTime(endTime)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w300,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
