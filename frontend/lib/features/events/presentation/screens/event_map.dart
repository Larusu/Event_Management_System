import "package:flutter/material.dart";

import "../../../../shared/widgets/modal.dart";
import "../../data/campus_map_data.dart";
import "../widgets/floor_map_view.dart";

void viewEventMap(
  BuildContext context, {
  required String title,
  required String date,
  required String startTime,
  required String endTime,
  required String location,
  required String description,
  required int participants,
  required int slots,
  required bool guestsAllowed,
  String day = "",
  List<Map<String, String>> hosts = const [],
  List<Map<String, String>> speakers = const [],
}) {
  ModalContainer.show(
    context: context,
    child: _ViewEventMap ( 
      title: title,
      day: day,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      description: description,
      participants: participants,
      guestsAllowed: guestsAllowed,
      hosts: hosts,
      speakers: speakers,
      slots: slots,
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
    final room = resolveRoomFromLocation(widget.location);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        room != null 
          ? FloorMapView(room: room)
          : MapUnavailable(location: widget.location),
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
