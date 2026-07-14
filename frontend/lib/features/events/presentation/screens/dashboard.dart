import "package:flutter/material.dart";

import "../../../../shared/widgets/event_banners.dart";
import "../../../../shared/widgets/event_cards.dart";
import "../../../../shared/widgets/navbar.dart";

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> upcomingEvents = [
      {
        "title": "Paws-to-Pause",
        "day": "Friday",
        "date": "July 10, 2026",
        "startTime": "4:00 PM",
        "endTime": "6:30 PM"
      },
      {
        "title": "1st Day of Finals",
        "day": "Monday",
        "date": "July 20, 2026",
        "startTime": "8:30 PM",
        "endTime": "9:00 PM"
      },
      {
        "title": "End of Classes",
        "day": "Saturday",
        "date": "July 25, 2026",
        "startTime": "6:30 PM",
        "endTime": "9:00 PM"
      },
    ];

    final List<Map<String, String>> featuredEvents = [
      {
        "title": "Event Title 1",
        "imageUrl":
            "https://miro.medium.com/v2/resize:fit:1100/format:webp/1*uNCVd_VqFOcdxhsL71cT5Q.jpeg",
        "description":
            "Sample event description. Lorem ipsum chuchuness. So what if sobrang haba naman ng description? Isa pang line kailangan HAHAHHA. Ayoko na T-T",
        "date": "July 9, 2026",
        "startTime": "8:00 AM",
        "endTime": "10:00 AM",
      },
      {
        "title": "Event Title 2",
        "imageUrl":
            "https://miro.medium.com/v2/resize:fit:1100/format:webp/1*uNCVd_VqFOcdxhsL71cT5Q.jpeg",
        "description": "Eto na yung araw na sukong-suko na ko.",
        "date": "July 20, 2026",
        "startTime": "8:00 AM",
        "endTime": "9:00 PM",
      },
      {
        "title": "Event Title 3",
        "imageUrl":
            "https://miro.medium.com/v2/resize:fit:1100/format:webp/1*uNCVd_VqFOcdxhsL71cT5Q.jpeg",
        "description": "Makakalaya na tayo. :3",
        "date": "July 25, 2026",
        "startTime": "6:30 PM",
        "endTime": "9:00 PM",
      },
    ];

    return Scaffold(
        appBar: AppBar(title: const Text("EMS")),
        bottomNavigationBar: NavBar(
          selectedPageIndex: _selectedPageIndex,
          onPageSelected: (index) {
            setState(() {
              _selectedPageIndex = index;
            });
          },
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
          child: Center(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                NextEventBanner(
                    title: "Event Title 1",
                    day: "Thursday",
                    date: "July 9, 2026",
                    startTime: "8:00 AM",
                    endTime: "10:00 AM",
                    location: "7th Floor, Gymnasium, Interweave Building"),
                const SizedBox(height: 15),
                const Text(
                  "Featured Events",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredEvents.length,
                        itemBuilder: (context, index) {
                          final feature = featuredEvents[index];
                          return FeaturedEventCard(
                              title: feature["title"]!,
                              imageUrl: feature["imageUrl"]!,
                              description: feature["description"]!,
                              date: feature["date"]!,
                              startTime: feature["startTime"]!,
                              endTime: feature["endTime"]!);
                        })),
                const SizedBox(height: 15),
                const Text(
                  "Upcoming Registered Events",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                    child: ListView.builder(
                        itemCount: upcomingEvents.length,
                        itemBuilder: (context, index) {
                          final event = upcomingEvents[index];
                          return UpcomingEventBanner(
                              title: event["title"]!,
                              day: event["day"]!,
                              date: event["date"]!,
                              startTime: event["startTime"]!,
                              endTime: event["endTime"]!);
                        }))
              ])),
        ));
  }
}
