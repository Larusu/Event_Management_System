import "package:flutter/material.dart";

import "../../../../shared/widgets/modal.dart";
import "../../data/campus_map_data.dart";
import "../widgets/floor_map_view.dart";

/// Opens a map-focused modal for [location].
///
/// This is a pure wayfinding view: a large interactive floor plan with the
/// floor level shown at the top-left. Event details deliberately live only in
/// the event modal so this screen isn't a duplicate of it.
void viewEventMap(BuildContext context, {required String location}) {
  ModalContainer.show(
    context: context,
    initialSize: 0.9,
    minSize: 0.45,
    maxSize: 0.95,
    child: _ViewEventMap(location: location),
  );
}

class _ViewEventMap extends StatelessWidget {
  final String location;

  const _ViewEventMap({required this.location});

  @override
  Widget build(BuildContext context) {
    final room = resolveRoomFromLocation(location);
    final floor = room != null ? floorForRoom(room) : null;
    final mapHeight = MediaQuery.of(context).size.height * 0.72;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor level (top-left).
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
          child: Text(
            floor?.displayName ?? "Floor Plan",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ),
        room != null
            ? FloorMapView(room: room, height: mapHeight)
            : MapUnavailable(location: location, height: mapHeight),
      ],
    );
  }
}
