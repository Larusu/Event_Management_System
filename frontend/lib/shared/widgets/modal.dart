import 'package:flutter/material.dart';

class ModalContainer {
  // Side modal; call to view
  static void show({
    required BuildContext context,
    required Widget child,
    double initialSize = 0.5,
    double minSize = 0.15,
    double maxSize = 0.9,
    List<double>? snapSizes,
  }) {
    final DraggableScrollableController sheetController =
        DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DraggableContent(
          controller: sheetController,
          initialSize: initialSize,
          minSize: minSize,
          maxSize: maxSize,
          snapSizes: snapSizes,
          child: child,
        );
      },
    );
  }

  // Pop-up modal or Dialog; call to view
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
              color: Colors.white,
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

  // Static on screen modal; already viewing
  static Widget persistent({
    required Widget child,
    DraggableScrollableController? controller,
    double initialSize = 0.15,
    double minSize = 0.1,
    double maxSize = 0.8,
    List<double>? snapSizes,
  }) {
    return _DraggableContent(
      controller: controller,
      initialSize: initialSize,
      minSize: minSize,
      maxSize: maxSize,
      snapSizes: snapSizes,
      child: child,
    );
  }
}

class _DraggableContent extends StatelessWidget {
  final Widget child;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final List<double>? snapSizes;
  final DraggableScrollableController? controller;

  const _DraggableContent({
    required this.child,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    this.snapSizes,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: snapSizes ?? [minSize, initialSize, maxSize],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Column(
            children: [
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (controller != null && controller!.isAttached) {
                    final currentSize = controller!.size;
                    // Get screen height to convert pixels to size ratio
                    final screenHeight = MediaQuery.of(context).size.height;
                    final delta = -details.primaryDelta! / screenHeight;
                    controller!
                        .jumpTo((currentSize + delta).clamp(minSize, maxSize));
                  }
                },
                child: Container(
                  width: double.infinity, // Make it wide to catch drags
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: Colors.transparent, // Ensure it's hit-testable
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
