import 'package:flutter/material.dart';

class NextEventBanner extends StatefulWidget {
  final String title;
  final String day;
  final String date;
  final String startTime;
  final String endTime;
  final String location;

  const NextEventBanner({
    super.key,
    required this.title,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  @override
  State<NextEventBanner> createState() => _NextEventBannerState();
}

class _NextEventBannerState extends State<NextEventBanner> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.startTime} - ${widget.endTime}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.day}, ${widget.date}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.location,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingEventBanner extends StatefulWidget {
  final String title;
  final String day;
  final String date;
  final String startTime;
  final String endTime;

  const UpcomingEventBanner({
    super.key,
    required this.title,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<UpcomingEventBanner> createState() => _UpcomingEventBannerState();
}

class _UpcomingEventBannerState extends State<UpcomingEventBanner> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.day}, ${widget.date}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.startTime} - ${widget.endTime}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
