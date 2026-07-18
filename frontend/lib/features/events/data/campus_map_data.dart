import 'dart:ui';

import '../models/campus_map.dart';

/// Shared coordinate space for every floor.
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
    startPoint: Offset(751, 630), // elevator lobby
    rooms: [
      MapRoom(
        id: 'gf_lobby',
        name: 'GF Lobby',
        floorId: 'ground_floor',
        marker: Offset(634, 821),
        routePath: [Offset(751, 630), Offset(634, 630), Offset(634, 821)],
      ),
      MapRoom(
        id: 'gf_reception',
        name: 'GF Reception',
        floorId: 'ground_floor',
        marker: Offset(517, 821),
        routePath: [Offset(751, 630), Offset(517, 630), Offset(517, 821)],
      ),
      MapRoom(
        id: 'gf_outdoor_lounge',
        name: 'Outdoor Lounge',
        floorId: 'ground_floor',
        marker: Offset(839, 1040),
        routePath: [Offset(751, 630), Offset(839, 630), Offset(839, 1040)],
      ),
      MapRoom(
        id: 'gf_parking',
        name: 'Parking Area',
        floorId: 'ground_floor',
        marker: Offset(385, 574),
        routePath: [Offset(751, 630), Offset(385, 630), Offset(385, 574)],
      ),
    ],
  ),

  const FloorMap(
    id: 'second_floor',
    displayName: '2nd Floor',
    svgAsset: 'assets/maps/second_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(745, 625), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l2_lounge_cafe',
        name: 'Student Lounge (Cafe)',
        floorId: 'second_floor',
        marker: Offset(476, 292),
        routePath: [Offset(745, 625), Offset(476, 625), Offset(476, 292)],
      ),
      MapRoom(
        id: 'l2_lounge_library',
        name: 'Student Lounge (Library)',
        floorId: 'second_floor',
        marker: Offset(476, 547),
        routePath: [Offset(745, 625), Offset(476, 625), Offset(476, 547)],
      ),
      MapRoom(
        id: 'l2_reception',
        name: 'Main Reception Lobby',
        floorId: 'second_floor',
        marker: Offset(408, 807),
        routePath: [Offset(745, 625), Offset(408, 625), Offset(408, 807)],
      ),
      MapRoom(
        id: 'l2_library_right',
        name: 'Library (Right Wing)',
        floorId: 'second_floor',
        marker: Offset(282, 1109),
        routePath: [Offset(745, 625), Offset(282, 625), Offset(282, 1109)],
      ),
      MapRoom(
        id: 'l2_library_left',
        name: 'Library (Left Wing)',
        floorId: 'second_floor',
        marker: Offset(720, 1109),
        routePath: [Offset(745, 625), Offset(720, 625), Offset(720, 1109)],
      ),
      MapRoom(
        id: 'l2_library_pair',
        name: 'Library (Pair Study)',
        floorId: 'second_floor',
        marker: Offset(145, 807),
        routePath: [Offset(745, 625), Offset(145, 625), Offset(145, 807)],
      ),
      MapRoom(
        id: 'l2_clinic',
        name: 'Clinic',
        floorId: 'second_floor',
        marker: Offset(815, 435),
        routePath: [Offset(745, 625), Offset(815, 625), Offset(815, 435)],
      ),
      MapRoom(
        id: 'l2_dental',
        name: 'Dental Office',
        floorId: 'second_floor',
        marker: Offset(785, 357),
        routePath: [Offset(745, 625), Offset(785, 625), Offset(785, 357)],
      ),
      MapRoom(
        id: 'l2_student_orgs',
        name: "Student Organizations' Area",
        floorId: 'second_floor',
        marker: Offset(815, 245),
        routePath: [Offset(745, 625), Offset(815, 625), Offset(815, 245)],
      ),
    ],
  ),

  const FloorMap(
    id: 'third_floor',
    displayName: '3rd Floor',
    svgAsset: 'assets/maps/third_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(764, 685), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l3_it_dept',
        name: 'IT Department',
        floorId: 'third_floor',
        marker: Offset(168, 312),
        routePath: [Offset(764, 685), Offset(168, 685), Offset(168, 312)],
      ),
      MapRoom(
        id: 'l3_room302',
        name: 'Room 302',
        floorId: 'third_floor',
        marker: Offset(458, 517),
        routePath: [Offset(764, 685), Offset(458, 685), Offset(458, 517)],
      ),
      MapRoom(
        id: 'l3_registrar_finance',
        name: "Registrar's / Finance Office",
        floorId: 'third_floor',
        marker: Offset(831, 445),
        routePath: [Offset(764, 685), Offset(831, 685), Offset(831, 445)],
      ),
      MapRoom(
        id: 'l3_room301',
        name: 'Room 301 (Studio Room)',
        floorId: 'third_floor',
        marker: Offset(168, 654),
        routePath: [Offset(764, 685), Offset(168, 685), Offset(168, 654)],
      ),
      MapRoom(
        id: 'l3_main_reception',
        name: 'Main Reception Lobby',
        floorId: 'third_floor',
        marker: Offset(423, 820),
        routePath: [Offset(764, 685), Offset(423, 685), Offset(423, 820)],
      ),
      MapRoom(
        id: 'l3_gaming_lounge',
        name: 'Gaming Lounge',
        floorId: 'third_floor',
        marker: Offset(600, 885),
        routePath: [Offset(764, 685), Offset(600, 685), Offset(600, 885)],
      ),
      MapRoom(
        id: 'l3_hr_dept',
        name: 'HR Department',
        floorId: 'third_floor',
        marker: Offset(246, 1193),
        routePath: [Offset(764, 685), Offset(246, 685), Offset(246, 1193)],
      ),
      MapRoom(
        id: 'l3_admissions',
        name: 'BDD / Admissions Office',
        floorId: 'third_floor',
        marker: Offset(853, 1152),
        routePath: [Offset(764, 685), Offset(853, 685), Offset(853, 1152)],
      ),
    ],
  ),

  const FloorMap(
    id: 'fourth_floor',
    displayName: '4th Floor',
    svgAsset: 'assets/maps/fourth_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(764, 685), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l4_faculty',
        name: 'Faculty',
        floorId: 'fourth_floor',
        marker: Offset(608, 456),
        routePath: [Offset(764, 685), Offset(608, 685), Offset(608, 456)],
      ),
      MapRoom(
        id: 'l4_board_room1',
        name: 'Board Room 1',
        floorId: 'fourth_floor',
        marker: Offset(168, 342),
        routePath: [Offset(764, 685), Offset(168, 685), Offset(168, 342)],
      ),
      MapRoom(
        id: 'l4_board_room2',
        name: 'Board Room 2',
        floorId: 'fourth_floor',
        marker: Offset(163, 607),
        routePath: [Offset(764, 685), Offset(163, 685), Offset(163, 607)],
      ),
      MapRoom(
        id: 'l4_meeting_room5',
        name: 'Meeting Room 5',
        floorId: 'fourth_floor',
        marker: Offset(831, 492),
        routePath: [Offset(764, 685), Offset(831, 685), Offset(831, 492)],
      ),
      MapRoom(
        id: 'l4_guidance',
        name: 'Guidance Office',
        floorId: 'fourth_floor',
        marker: Offset(379, 834),
        routePath: [Offset(764, 685), Offset(379, 685), Offset(379, 834)],
      ),
      MapRoom(
        id: 'l4_room401',
        name: 'Room 401',
        floorId: 'fourth_floor',
        marker: Offset(719, 1152),
        routePath: [Offset(764, 685), Offset(719, 685), Offset(719, 1152)],
      ),
      MapRoom(
        id: 'l4_room402',
        name: 'Room 402',
        floorId: 'fourth_floor',
        marker: Offset(277, 1152),
        routePath: [Offset(764, 685), Offset(277, 685), Offset(277, 1152)],
      ),
      MapRoom(
        id: 'l4_room403',
        name: 'Room 403',
        floorId: 'fourth_floor',
        marker: Offset(163, 856),
        routePath: [Offset(764, 685), Offset(163, 685), Offset(163, 856)],
      ),
    ],
  ),

  const FloorMap(
    id: 'fifth_floor',
    displayName: '5th Floor',
    svgAsset: 'assets/maps/fifth_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(779, 645), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l5_room501',
        name: 'Room 501',
        floorId: 'fifth_floor',
        marker: Offset(742, 1133),
        routePath: [Offset(779, 645), Offset(742, 645), Offset(742, 1133)],
      ),
      MapRoom(
        id: 'l5_room502',
        name: 'Room 502',
        floorId: 'fifth_floor',
        marker: Offset(264, 1139),
        routePath: [Offset(779, 645), Offset(264, 645), Offset(264, 1139)],
      ),
      MapRoom(
        id: 'l5_room503',
        name: 'Room 503',
        floorId: 'fifth_floor',
        marker: Offset(264, 832),
        routePath: [Offset(779, 645), Offset(264, 645), Offset(264, 832)],
      ),
      MapRoom(
        id: 'l5_room504',
        name: 'Room 504',
        floorId: 'fifth_floor',
        marker: Offset(276, 574),
        routePath: [Offset(779, 645), Offset(276, 645), Offset(276, 574)],
      ),
      MapRoom(
        id: 'l5_room505',
        name: 'Room 505',
        floorId: 'fifth_floor',
        marker: Offset(277, 368),
        routePath: [Offset(779, 645), Offset(277, 645), Offset(277, 368)],
      ),
      MapRoom(
        id: 'l5_room506',
        name: 'Room 506',
        floorId: 'fifth_floor',
        marker: Offset(766, 414),
        routePath: [Offset(779, 645), Offset(766, 645), Offset(766, 414)],
      ),
    ],
  ),

  const FloorMap(
    id: 'sixth_floor',
    displayName: '6th Floor',
    svgAsset: 'assets/maps/sixth_floor.svg',
    mapSize: _kMapSize,
    startPoint: Offset(779, 645), // elevator lobby
    rooms: [
      MapRoom(
        id: 'l6_room601',
        name: 'Room 601',
        floorId: 'sixth_floor',
        marker: Offset(742, 1133),
        routePath: [Offset(779, 645), Offset(742, 645), Offset(742, 1133)],
      ),
      MapRoom(
        id: 'l6_room602',
        name: 'Room 602',
        floorId: 'sixth_floor',
        marker: Offset(264, 1139),
        routePath: [Offset(779, 645), Offset(264, 645), Offset(264, 1139)],
      ),
      MapRoom(
        id: 'l6_room603',
        name: 'Room 603',
        floorId: 'sixth_floor',
        marker: Offset(264, 832),
        routePath: [Offset(779, 645), Offset(264, 645), Offset(264, 832)],
      ),
      MapRoom(
        id: 'l6_room604',
        name: 'Room 604',
        floorId: 'sixth_floor',
        marker: Offset(276, 574),
        routePath: [Offset(779, 645), Offset(276, 645), Offset(276, 574)],
      ),
      MapRoom(
        id: 'l6_room605',
        name: 'Room 605',
        floorId: 'sixth_floor',
        marker: Offset(277, 368),
        routePath: [Offset(779, 645), Offset(277, 645), Offset(277, 368)],
      ),
      MapRoom(
        id: 'l6_room606',
        name: 'Room 606',
        floorId: 'sixth_floor',
        marker: Offset(766, 414),
        routePath: [Offset(779, 645), Offset(766, 645), Offset(766, 414)],
      ),
      MapRoom(
        id: 'l6_prayer_room',
        name: 'Prayer Room',
        floorId: 'sixth_floor',
        marker: Offset(138, 218),
        routePath: [Offset(779, 645), Offset(138, 645), Offset(138, 218)],
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
/// "gym" or "reception" don't shadow exact ones. Matching is case-insensitive
/// substring.
MapRoom? resolveRoomFromLocation(String location) {
  final query = location.toLowerCase();
  const rules = <String, String>{
    // 7th floor (gymnasium + bleachers)
    'gymnasium': 'gym_sports_area',
    'sports area': 'gym_sports_area',
    'cafeteria': 'gym_cafeteria',
    'employee lounge': 'gym_employee_lounge',
    'machine room': 'bl_machine_room',
    'bleacher': 'bl_bleachers_top',
    // 2nd floor
    'lounge (cafe)': 'l2_lounge_cafe',
    'lounge (library)': 'l2_lounge_library',
    'pair study': 'l2_library_pair',
    'left wing': 'l2_library_left',
    'right wing': 'l2_library_right',
    'formal study': 'l2_library_left',
    'casual study': 'l2_library_right',
    'clinic': 'l2_clinic',
    'dental': 'l2_dental',
    'student organization': 'l2_student_orgs',
    'main reception': 'l2_reception',
    'cafe': 'l2_lounge_cafe',
    // ground floor
    'outdoor lounge': 'gf_outdoor_lounge',
    'gf lobby': 'gf_lobby',
    'parking': 'gf_parking',
    // 3rd floor
    'it department': 'l3_it_dept',
    'registrar': 'l3_registrar_finance',
    'finance': 'l3_registrar_finance',
    'gaming lounge': 'l3_gaming_lounge',
    'studio room': 'l3_room301',
    'room 301': 'l3_room301',
    'room 302': 'l3_room302',
    'hr department': 'l3_hr_dept',
    'admissions': 'l3_admissions',
    'bdd': 'l3_admissions',
    // 4th floor
    'board room 1': 'l4_board_room1',
    'board room 2': 'l4_board_room2',
    'board room': 'l4_board_room1',
    'faculty': 'l4_faculty',
    'meeting room 5': 'l4_meeting_room5',
    'meeting room': 'l4_meeting_room5',
    'guidance': 'l4_guidance',
    'room 401': 'l4_room401',
    'room 402': 'l4_room402',
    'room 403': 'l4_room403',
    // 5th floor
    'room 501': 'l5_room501',
    'room 502': 'l5_room502',
    'room 503': 'l5_room503',
    'room 504': 'l5_room504',
    'room 505': 'l5_room505',
    'room 506': 'l5_room506',
    // 6th floor
    'prayer room': 'l6_prayer_room',
    'room 601': 'l6_room601',
    'room 602': 'l6_room602',
    'room 603': 'l6_room603',
    'room 604': 'l6_room604',
    'room 605': 'l6_room605',
    'room 606': 'l6_room606',
    // generic fallbacks (checked last)
    'reception': 'gf_reception',
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
