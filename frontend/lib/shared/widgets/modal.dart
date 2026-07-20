import 'package:flutter/material.dart';

class ModalContainer {
  /// Draggable bottom sheet with Flutter's default Material 3 drag handle.
  static void show({
    required BuildContext context,
    required Widget child,
    double initialSize = 0.88,
    double minSize = 0.15,
    double maxSize = 0.9,
    List<double>? snapSizes,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          snap: true,
          snapSizes: snapSizes ?? [minSize, initialSize, maxSize],
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: child,
            );
          },
        );
      },
    );
  }

  /// Pop-up modal or Dialog; call to view
  static void popup({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(blurRadius: 15, color: Colors.black26),
              ],
            ),
            child: SingleChildScrollView(child: child),
          ),
        );
      },
    );
  }
}
