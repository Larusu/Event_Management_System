import 'package:campus_event_app/shared/widgets/event_cards.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final events = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Header(
                header: 'Events \nList',
                views: const ['All', 'Day', 'Week', 'Month'],
                page: "events",
                filters: ['Sports', 'Music', 'Education', 'Games'],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Text(
                  "Featured Events",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 1.02),
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FeaturedEventCard(
                      title: 'Event Title',
                      imageUrl: 'https://picsum.photos/400/250?random=$index',
                      description: 'This is the event desciption and stuff.',
                      date: 'May 27, 2026',
                      startTime: '4:00 PM',
                      endTime: '6:30 PM',
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Text(
                  "Upcoming Events",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) => EventCard(
                  title: 'Event Title ${index + 1}',
                  participants: 23,
                  day: 'Friday',
                  date: 'May 8, 2026',
                  startTime: '12:30 PM',
                  endTime: '3:00 PM',
                  openSlots: 10,
                  imageUrl: 'https://picsum.photos/80/80?random=${index + 20}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
