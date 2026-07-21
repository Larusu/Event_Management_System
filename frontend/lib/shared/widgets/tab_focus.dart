import 'package:flutter/foundation.dart';

/// Broadcasts which bottom-nav branch is currently focused, plus a tick that
/// fires whenever the app returns from the background.
///
/// Tab screens live in a [StatefulShellRoute.indexedStack] and stay alive when
/// switching tabs, so they never re-run `initState` on focus. [MainShell]
/// drives this notifier (calling [setActive] on tab change and [markResumed]
/// on app resume); each tab screen listens and refreshes its own data when it
/// becomes the active branch.
class TabFocusNotifier extends ChangeNotifier {
  int? _active;
  int _resumeTick = 0;

  /// The branch index currently shown, or null before the first tab settles.
  int? get active => _active;

  /// Increments each time the app is resumed from the background. Screens can
  /// compare against a stored value to detect a resume while they are active.
  int get resumeTick => _resumeTick;

  /// Marks [branch] as the focused tab. No-op (and no notification) if it is
  /// already the active branch, so re-tapping the current tab does nothing.
  void setActive(int branch) {
    if (_active == branch) return;
    _active = branch;
    notifyListeners();
  }

  /// Signals that the app came back to the foreground.
  void markResumed() {
    _resumeTick++;
    notifyListeners();
  }
}
