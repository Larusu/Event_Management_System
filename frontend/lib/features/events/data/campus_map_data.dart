import 'dart:ui';

import '../models/campus_map.dart';

/// Shared coordinate spcce for every floor, matching the SVG 'viewBox'
const Size _kMapSize = Size(1000, 1400);

/// All floors of the Interweave building, with their rooms and static routes.
/// Coordinates are in the SVG viewBox space (see [_kMapSize]); a route always
/// starts at the floor's elevator/stair lobby and ends at the room's pin.
final List<FloorMap> campusMapRegistry = [
  const FloorMap(
    id: 'ground_floor',
    displayName: 'Ground Floor',
    svgAsset: 'assets/maps/ground_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(710, 680), // elevator lobby
    rooms: [
      MapRoom(
        id: 'gf_lobby',
        name: 'GF Lobby',
        floorId: 'ground_floor',
        marker: Offset(520, 865),
        routePath: [
          Offset(710, 680),
          Offset(650, 690),
          Offset(600, 820),
          Offset(520, 865),
        ],
      ),
      MapRoom(
        id: 'gf_reception',
        name: 'GF Reception',
        floorId: 'ground_floor',
        marker: Offset(450, 690),
        routePath: [Offset(710, 680), Offset(600, 690), Offset(450, 690)],
      ),
      MapRoom(
        id: 'gf_outdoor_lounge',
        name: 'Outdoor Lounge',
        floorId: 'ground_floor',
        marker: Offset(817, 1080),
        routePath: [
          Offset(710, 680),
          Offset(710, 780),
          Offset(760, 980),
          Offset(817, 1080),
        ],
      ),
      MapRoom(
        id: 'gf_parking',
        name: 'Parking Area',
        floorId: 'ground_floor',
        marker: Offset(320, 250),
        routePath: [
          Offset(710, 680),
          Offset(650, 680),
          Offset(450, 560),
          Offset(320, 320),
          Offset(320, 262),
        ],
      ),
    ],
  ),

  const FloorMap(
    id: 'second_floor',
    displayName: '2nd Floor',
    svgAsset: 'assets/maps/second_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(710, 640), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l2_lounge_cafe',
        name: 'Student Lounge (Cafe)',
        floorId: 'second_floor',
        marker: Offset(432, 262),
        routePath: [
          Offset(710, 640),
          Offset(645, 640),
          Offset(645, 400),
          Offset(645, 270),
          Offset(432, 265),
        ],
      ),
      MapRoom(
        id: 'l2_lounge_library',
        name: 'Student Lounge (Library)',
        floorId: 'second_floor',
        marker: Offset(410, 460),
        routePath: [
          Offset(710, 640),
          Offset(620, 560),
          Offset(500, 470),
          Offset(410, 460),
        ],
      ),
      MapRoom(
        id: 'l2_reception',
        name: 'Main Reception Lobby',
        floorId: 'second_floor',
        marker: Offset(360, 710),
        routePath: [
          Offset(710, 640),
          Offset(560, 665),
          Offset(470, 710),
          Offset(360, 710),
        ],
      ),
      MapRoom(
        id: 'l2_library_formal',
        name: 'Library (Formal Study)',
        floorId: 'second_floor',
        marker: Offset(260, 1055),
        routePath: [
          Offset(710, 640),
          Offset(645, 700),
          Offset(500, 900),
          Offset(320, 1000),
          Offset(260, 1055),
        ],
      ),
      MapRoom(
        id: 'l2_library_casual',
        name: 'Library (Casual Study)',
        floorId: 'second_floor',
        marker: Offset(615, 1065),
        routePath: [
          Offset(710, 640),
          Offset(660, 760),
          Offset(650, 920),
          Offset(615, 1000),
          Offset(615, 1065),
        ],
      ),
      MapRoom(
        id: 'l2_library_pair',
        name: 'Library (Pair Study)',
        floorId: 'second_floor',
        marker: Offset(145, 810),
        routePath: [
          Offset(710, 640),
          Offset(560, 665),
          Offset(300, 760),
          Offset(160, 810),
          Offset(145, 810),
        ],
      ),
      MapRoom(
        id: 'l2_clinic',
        name: 'Clinic',
        floorId: 'second_floor',
        marker: Offset(835, 495),
        routePath: [
          Offset(710, 640),
          Offset(730, 560),
          Offset(800, 510),
          Offset(835, 495),
        ],
      ),
      MapRoom(
        id: 'l2_dental',
        name: 'Dental Office',
        floorId: 'second_floor',
        marker: Offset(855, 367),
        routePath: [
          Offset(710, 640),
          Offset(720, 500),
          Offset(820, 400),
          Offset(855, 370),
        ],
      ),
      MapRoom(
        id: 'l2_student_orgs',
        name: "Student Organizations' Area",
        floorId: 'second_floor',
        marker: Offset(835, 242),
        routePath: [
          Offset(710, 640),
          Offset(710, 420),
          Offset(790, 260),
          Offset(835, 245),
        ],
      ),
    ],
  ),

  const FloorMap(
    id: 'gym_deck',
    displayName: '7th Floor - Gymnasium',
    svgAsset: 'assets/maps/gym_deck.svg',
    mapSize: _kMapSize,
    startPoint: Offset(732, 627), // elevator lobby
    rooms: [
      MapRoom(
        id: 'gym_sports_area',
        name: 'Gymnasium (Sports Area)',
        floorId: 'gym_deck',
        marker: Offset(350, 970),
        routePath: [
          Offset(732, 627),
          Offset(660, 627),
          Offset(645, 720),
          Offset(645, 900),
          Offset(430, 945),
          Offset(350, 970),
        ],
      ),
      MapRoom(
        id: 'gym_cafeteria',
        name: 'Cafeteria',
        floorId: 'gym_deck',
        marker: Offset(350, 425),
        routePath: [
          Offset(732, 627),
          Offset(660, 627),
          Offset(645, 540),
          Offset(645, 430),
          Offset(430, 425),
          Offset(350, 425),
        ],
      ),
      MapRoom(
        id: 'gym_employee_lounge',
        name: 'Employee Lounge',
        floorId: 'gym_deck',
        marker: Offset(515, 140),
        routePath: [
          Offset(732, 627),
          Offset(660, 610),
          Offset(645, 400),
          Offset(645, 200),
          Offset(515, 180),
        ],
      ),
    ],
  ),

  const FloorMap(
    id: 'bleachers',
    displayName: 'Bleachers',
    svgAsset: 'assets/maps/bleachers.svg',
    mapSize: _kMapSize,
    startPoint: Offset(800, 820), // stairs (no elevator on this level)
    rooms: [
      MapRoom(
        id: 'bl_bleachers_top',
        name: 'Bleachers Area (Upper)',
        floorId: 'bleachers',
        marker: Offset(812, 370),
        routePath: [
          Offset(800, 820),
          Offset(800, 600),
          Offset(812, 420),
          Offset(812, 370),
        ],
      ),
      MapRoom(
        id: 'bl_bleachers_bottom',
        name: 'Bleachers Area (Lower)',
        floorId: 'bleachers',
        marker: Offset(812, 1110),
        routePath: [
          Offset(800, 820),
          Offset(800, 940),
          Offset(812, 1050),
          Offset(812, 1110),
        ],
      ),
      MapRoom(
        id: 'bl_machine_room',
        name: 'Machine Room',
        floorId: 'bleachers',
        marker: Offset(835, 640),
        routePath: [Offset(800, 820), Offset(820, 720), Offset(835, 650)],
      ),
    ],
  ),
];

/// Returns the floor with [id], or null if unknown
FloorMap? floorById(String id) {
  for(final floor in campusMapRegistry) {
    if (floor.id == id) return floor;
  }
  return null;
}

/// Returns the [FloorMap] that a [room] belongs to (for its SVG + start point)
FloorMap? floorForRoom(MapRoom room) => floorById(room.floorId);

MapRoom? _roomById(String id) {
  for (final floor in campusMapRegistry) {
    for (final room in floor.rooms) {
      if (room.id == id) return room;
    }
  }
  return null;
}

/// Maps a free-text event location (e.g. "7th Floor, Gymnasium, Interweave
/// Building") to a known [MapRoom], or null when nothing matches.
///
/// Rules are checked in order, most specific first, so broader keywords like
/// "gym" don't shadow exact ones. Matching is case-insensitive substring.
MapRoom? resolveRoomFromLocation(String location) {
  final query = location.toLowerCase();
  const rules = <String, String>{
    'gymnasium': 'gym_sports_area',
    'sports area': 'gym_sports_area',
    'cafeteria': 'gym_cafeteria',
    'employee lounge': 'gym_employee_lounge',
    'lounge (cafe)': 'l2_lounge_cafe',
    'lounge (library)': 'l2_lounge_library',
    'main reception': 'l2_reception',
    'formal study': 'l2_library_formal',
    'casual study': 'l2_library_casual',
    'pair study': 'l2_library_pair',
    'clinic': 'l2_clinic',
    'dental': 'l2_dental',
    'student organization': 'l2_student_orgs',
    'outdoor lounge': 'gf_outdoor_lounge',
    'gf lobby': 'gf_lobby',
    'reception': 'gf_reception',
    'parking': 'gf_parking',
    'machine room': 'bl_machine_room',
    'bleacher': 'bl_bleachers_top',
    'gym': 'gym_sports_area',
  };
  for (final entry in rules.entries) {
    if (query.contains(entry.key)) {
      final room = _roomById(entry.value);
      if (room != null) return room;
    }
  }
  return null;
}
