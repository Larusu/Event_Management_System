import "package:flutter/material.dart";

import "../../../../shared/widgets/modal.dart";

void createNewEvent(BuildContext context) {
  ModalContainer.show(context: context, child: const _CreateEventModal());
}

class _CreateEventModal extends StatefulWidget {
  const _CreateEventModal();

  @override
  State<_CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<_CreateEventModal> {
  @override
  Widget build(BuildContext context) {
    return (Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("New Event",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
            const SizedBox(height: 15.0),

            // TODO: Make editable or uploadable image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15.0),
            TextField(
              decoration: const InputDecoration(
                labelText: "Event Title",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
              ),
            ),
            const SizedBox(height: 10.0),
            TextField(
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "All Day",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch.adaptive(
                  value: false,
                  onChanged: (value) {
                    // TODO: Add function
                  },
                )
              ],
            ),
            const SizedBox(height: 10.0),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Start Date",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Select Time",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "End Date",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Select Time",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            TextField(
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(
              height: 1,
            ),
            const SizedBox(height: 15.0),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: save event
                },
                child: const Text("Add Event"),
              ),
            ])
          ],
        )));
  }
}
