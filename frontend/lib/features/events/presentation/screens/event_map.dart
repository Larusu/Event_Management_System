import "dart:ui" show ImageFilter;

import "package:flutter/material.dart";

import "../../data/campus_map_data.dart";
import "../widgets/floor_map_view.dart";

/// Opens a centered, blurred-backdrop map pop-out for [location].
///
/// Wayfinding-only: a floor plan sized to ~45% of the screen with the floor
/// level shown top-left. Dismiss by tapping outside or the X button. Event
/// details live only in the event modal, so this isn't a duplicate of it.
void viewEventMap(BuildContext context, {required String location}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, __) => _MapDialog(location: location),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6 * animation.value,
          sigmaY: 6 * animation.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _MapDialog extends StatelessWidget {
  final String location;

  const _MapDialog({required this.location});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final room = resolveRoomFromLocation(location);
    final floor = room != null ? floorForRoom(room) : null;
    final size = MediaQuery.of(context).size;
    final dialogHeight = size.height * 0.65;

    return Center(
      child: SizedBox(
        height: dialogHeight,
        width: size.width * 0.85,
        child: Material(
          color: const Color(0xFFEEF2F4),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: room != null
                    ? FloorMapView(room: room, height: dialogHeight)
                    : MapUnavailable(location: location, height: dialogHeight),
              ),

              // Floor level (top-left).
              Positioned(
                top: 10,
                left: 10,
                right: 54,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      floor?.displayName ?? "Floor Plan",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Close (top-right).
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 20, color: primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
