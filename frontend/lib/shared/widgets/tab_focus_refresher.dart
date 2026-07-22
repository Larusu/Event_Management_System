import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'tab_focus.dart';

/// Wraps a tab screen and calls [onRefresh] whenever that tab becomes the
/// focused branch (a tab switch) or the app resumes while it is focused.
///
/// The tab screens live in an [StatefulShellRoute.indexedStack] and stay alive
/// across tab switches, so they cannot detect focus on their own. This listens
/// to the app-level [TabFocusNotifier] (driven by MainShell) and fires
/// [onRefresh] only when [branch] is the active one. Pair it with a provider
/// method that is itself guarded (staleness + in-flight) so rapid focus changes
/// stay cheap.
class TabFocusRefresher extends StatefulWidget {
  final int branch;
  final Future<void> Function() onRefresh;
  final Widget child;

  const TabFocusRefresher({
    super.key,
    required this.branch,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<TabFocusRefresher> createState() => _TabFocusRefresherState();
}

class _TabFocusRefresherState extends State<TabFocusRefresher> {
  TabFocusNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<TabFocusNotifier>();
    if (!identical(notifier, _notifier)) {
      _notifier?.removeListener(_onFocusChanged);
      _notifier = notifier..addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    // The notifier only fires on an actual tab change or an app resume; in both
    // cases we refresh when this branch is the active one. The staleness guard
    // inside onRefresh keeps back-to-back focus changes from doing real work.
    if (_notifier?.active == widget.branch) {
      widget.onRefresh();
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
