import 'package:campus_event_app/core/models/event.dart';
import 'package:flutter/material.dart';

class EventCard extends StatefulWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool showSlots = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              event.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${event.dateTime.toLocal()}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => showSlots = !showSlots),
                  child: Text(showSlots
                      ? '${event.slotsLeft} slot${event.slotsLeft == 1 ? '' : 's'} left'
                      : 'Check availability'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
