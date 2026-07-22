/// Fixed branch indices of the bottom-nav [StatefulShellRoute.indexedStack].
///
/// The router always declares all five branches in this order; the Created
/// Events branch only surfaces a navbar tab for organizers and up. These
/// constants are shared between [MainShell] (which drives focus) and the tab
/// screens (which react to it) so both agree on which index is which.
class AppBranches {
  const AppBranches._();

  static const int calendar = 0;
  static const int createdEvents = 1;
  static const int dashboard = 2;
  static const int events = 3;
  static const int settings = 4;
}
