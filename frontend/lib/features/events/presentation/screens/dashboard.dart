import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/event_banners.dart';
import '../../../../shared/widgets/event_cards.dart';
import '../../../../shared/widgets/header.dart';
import '../../../../shared/widgets/header_delegate.dart';
import '../widgets/event_modal.dart';
import '../../providers/event_dashboard_provider.dart';
import '../../providers/event_detail_provider.dart';
import '../../providers/event_list_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _featuredController = PageController(viewportFraction: 1.02);
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<EventDashboardProvider>();
      provider.loadNextRegistered();
      provider.loadFeatured();
      provider.loadRegistered();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _featuredController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (_autoScrollTimer != null) return;
    final initialPage = itemCount * 500;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_featuredController.hasClients) return;
      _featuredController.jumpToPage(initialPage);
    });
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_featuredController.hasClients) return;
      final current = _featuredController.page?.round() ?? 0;
      _featuredController.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().currentUser?.name ?? 'Account';

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: HeaderDelegate(
              height: 70 + MediaQuery.of(context).padding.top,
              child: Header(
                header: 'EMS',
                views: const [],
                page: 'dashboard',
                headerSubtitle: userName,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverToBoxAdapter(
              child: _buildNextRegisteredSection(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Featured Events",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFeaturedSection(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Upcoming Registered Events",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildRegisteredSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNextRegisteredSection(BuildContext context) {
    return Consumer<EventDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.nextRegisteredStatus == EventDetailStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.nextRegisteredStatus == EventDetailStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                provider.nextRegisteredErrorMessage ?? 'Could not load event.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final event = provider.nextRegisteredEvent;

        if (event == null) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: Text(
                  "No upcoming registered events yet.\nBrowse events to find something to join!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }

        return NextEventBanner(
          title: event.title,
          day: event.displayDay,
          date: event.displayDate,
          startTime: event.displayStartTime,
          endTime: event.displayEndTime,
          location: event.location ?? event.streamLink ?? '',
        );
      },
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    return Consumer<EventDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.featuredStatus == EventListStatus.loading) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.featuredStatus == EventListStatus.error) {
          return SizedBox(
            height: 250,
            child: Center(
              child: Text(
                provider.featuredErrorMessage ??
                    'Could not load featured events.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final featured = provider.featuredEvents;

        if (featured.isEmpty) {
          return SizedBox(
            height: 250,
            child: Center(
              child: Text(
                "No featured events right now.",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        _startAutoScroll(featured.length);

        return SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _featuredController,
            itemCount: featured.length * 1000,
            itemBuilder: (context, index) {
              final event = featured[index % featured.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FeaturedEventCard(
                  title: event.title,
                  imageUrl: event.coverImageUrl,
                  description: event.description,
                  date: event.displayDate,
                  startTime: event.displayStartTime,
                  endTime: event.displayEndTime,
                  onTap: () => EventModal.show(
                    context,
                    eventId: event.eventId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRegisteredSection(BuildContext context) {
    return Consumer<EventDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.registeredStatus == EventListStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.registeredStatus == EventListStatus.error) {
          return Center(
            child: Text(
              provider.registeredErrorMessage ??
                  'Could not load registered events.',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final registered = provider.registeredEvents;

        if (registered.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "You haven't registered for any events yet.",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            itemCount: registered.length,
            itemBuilder: (context, index) {
              final event = registered[index];
              return UpcomingEventBanner(
                title: event.title,
                day: event.displayDay,
                date: event.displayDate,
                startTime: event.displayStartTime,
                endTime: event.displayEndTime,
              );
            },
          ),
        );
      },
    );
  }
}
