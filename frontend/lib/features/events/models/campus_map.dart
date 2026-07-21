import 'dart:ui';

/// A single floor's schematic map.
///
/// Holds the SVG artwork plus the rooms on that floor and the fixed arrival
/// point (elevator/stair lobby) that every route starts from. All coordinates
/// are in the SVG's own coordinate space, i.e. they must match the asset's
/// `viewBox` (currently `0 0 1000 1400` for every floor).
class FloorMap {
  /// Stable id, e.g. `"gym_deck"`. Also used to link rooms to their floor.
  final String id;

  /// Human-readable name shown in the UI, e.g. `"7th Floor - Gymnasium"`.
  final String displayName;

  /// Asset path of the floor's SVG, e.g. `"assets/maps/gym_deck.svg"`.
  final String svgAsset;

  /// Intrinsic size of the map, matching the SVG `viewBox` (width x height).
  final Size mapSize;

  /// Where a visitor arrives on this floor (the elevator/stair lobby).
  /// Every room's [MapRoom.routePath] begins here.
  final Offset startPoint;

  /// The destination rooms defined on this floor.
  final List<MapRoom> rooms;

  const FloorMap({
    required this.id,
    required this.displayName,
    required this.svgAsset,
    required this.mapSize,
    required this.startPoint,
    required this.rooms,
  });
}

/// A destination room on a floor.
///
/// Carries a precomputed, static walking route (a polyline in map coordinates)
/// from the floor's [FloorMap.startPoint] to the room. There is no live
/// positioning; the route is authored once per room.
class MapRoom {
  /// Stable id, e.g. `"gym_sports_area"`.
  final String id;

  /// Display name, e.g. `"Gymnasium (Sports Area)"`.
  final String name;

  /// Id of the [FloorMap] this room belongs to.
  final String floorId;

  /// Pin position, in map coordinates (SVG viewBox space).
  final Offset marker;

  /// The route polyline, in map coordinates: the floor's start point first,
  /// then any waypoints, ending at (or near) [marker].
  final List<Offset> routePath;

  const MapRoom({
    required this.id,
    required this.name,
    required this.floorId,
    required this.marker,
    required this.routePath,
  });
}
