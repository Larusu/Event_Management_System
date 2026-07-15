import "package:flutter/material.dart";

import "../../../../shared/widgets/modal.dart";

void viewEventMap(BuildContext context) {
  ModalContainer.show(
    context: context,
    child: const _ViewEventMap(
      title: "Map Event",
      day: "Saturday",
      date: "May 16, 2026",
      startTime: "1:30 PM",
      endTime: "4:00 PM",
      location: "7th Floor, Gymnasium, Interweave Building",
      description:
          "Very long description of the event. Thank you. Lorem ipsum. Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday Happy birthday",
      participants: 14,
      guestsAllowed: true,
      hosts: [
        {"name": "Sean Audric Salvador", "email": "sean.salvador@ciit.edu.ph"},
        {"name": "Sean Audric Salvador", "email": "sean.salvador@ciit.edu.ph"},
        {"name": "Sean Audric Salvador", "email": "sean.salvador@ciit.edu.ph"},
      ],
      speakers: [
        {"name": "Jhervis Arevalo", "email": "jhervis.arevalo@ciit.edu.ph"},
        {"name": "Jhervis Arevalo", "email": "jhervis.arevalo@ciit.edu.ph"},
      ],
      slots: 5,
    ),
  );
}

class _ViewEventMap extends StatefulWidget {
  final String title;
  final String date;
  final String day;
  final String startTime;
  final String endTime;
  final String location;
  final List<Map<String, String>> hosts;
  final List<Map<String, String>> speakers;
  final String description;
  final int participants;
  final int slots;
  final bool guestsAllowed;

  const _ViewEventMap({
    required this.title,
    required this.date,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.description,
    required this.participants,
    required this.slots,
    required this.guestsAllowed,
    this.hosts = const [],
    this.speakers = const [],
  });

  @override
  State<_ViewEventMap> createState() => _ViewEventMapState();
}

class _ViewEventMapState extends State<_ViewEventMap> {
  String _names(List<Map<String, String>> people) {
    return people.map((person) => person["name"] ?? "").join(", ");
  }

  String _emails(List<Map<String, String>> people) {
    return people.map((person) => person["email"] ?? "").join("\n");
  }

  @override
  Widget build(BuildContext context) {
    final openToGuests = widget.guestsAllowed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO: Change to map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            "https://upload.wikimedia.org/wikipedia/commons/a/a3/Whitebulldog.jpg",
            width: double.infinity,
            height: 275,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${widget.day}, ${widget.date}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "${widget.startTime} - ${widget.endTime}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.location,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(
                            text: "Hosted by: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: _names(widget.hosts)),
                          const TextSpan(
                            text: "\nGuest Speaker: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: _names(widget.speakers)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  Column(
                    children: [
                      Text(
                        openToGuests ? "Open to guests!" : "Students only!",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003B4A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text("Registered"),
                              const SizedBox(
                                width: 8.0,
                              ),
                              Icon(Icons.check),
                            ],
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 1.0,
              ),
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(
                            text: "Contact Details:\n",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text:
                                _emails([...widget.hosts, ...widget.speakers]),
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003B4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "${widget.participants} registered\nparticipants",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${widget.slots} slots left!",
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "For more inquiries, contact sao@ciit.edu.ph.",
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
