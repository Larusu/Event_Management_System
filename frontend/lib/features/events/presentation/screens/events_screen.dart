import 'dart:async';

import 'package:campus_event_app/core/constants/app_branches.dart';
import 'package:campus_event_app/features/events/providers/event_dashboard_provider.dart';
import 'package:campus_event_app/features/events/providers/event_list_provider.dart';
import 'package:campus_event_app/features/events/presentation/widgets/event_modal.dart';
import 'package:campus_event_app/shared/widgets/event_cards.dart';
import 'package:campus_event_app/shared/widgets/header.dart';
import 'package:campus_event_app/shared/widgets/tab_focus_refresher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _featuredController = PageController(viewportFraction: 1.02);
  Timer? _debounce;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final listProvider = context.read<EventListProvider>();
      final dashProvider = context.read<EventDashboardProvider>();
      if (listProvider.status == EventListStatus.idle) {
        listProvider.load();
      }
      listProvider.loadTags();
      if (dashProvider.featuredStatus == EventListStatus.idle) {
        dashProvider.loadFeatured();
      }
      dashProvider.addListener(() {
        if (mounted && dashProvider.featuredEvents.isNotEmpty) {
          _startAutoScroll(dashProvider.featuredEvents.length);
        }
      });
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _featuredController.dispose();
    _debounce?.cancel();
    _autoScrollTimer?.cancel();
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

  void _onScroll() {
    final provider = context.read<EventListProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoadingMore) {
      provider.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<EventListProvider>().load(query: value, reset: true);
    });
  }

  void _onFiltersChanged(List<String> tags) {
    context.read<EventListProvider>().load(tags: tags, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return TabFocusRefresher(
      branch: AppBranches.events,
      onRefresh: () => context.read<EventListProvider>().refreshIfStale(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Header(
                header: 'Events \nList',
                views: const [],
                page: "events",
                filters: context.watch<EventListProvider>().tags,
                showSearch: true,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onFiltersChanged: _onFiltersChanged,
              ),
              Expanded(
                child: _EventListBody(
                  scrollController: _scrollController,
                  searchController: _searchController,
                  featuredController: _featuredController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventListBody extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController searchController;
  final PageController featuredController;

  const _EventListBody({
    required this.scrollController,
    required this.searchController,
    required this.featuredController,
  });

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<EventListProvider>();
    final dashProvider = context.watch<EventDashboardProvider>();

    final isLoading = listProvider.status == EventListStatus.loading &&
        listProvider.events.isEmpty;
    final hasError = listProvider.status == EventListStatus.error &&
        listProvider.events.isEmpty;
    final featured = dashProvider.featuredEvents;
    final events = listProvider.events;

    if (isLoading && featured.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              listProvider.errorMessage ?? 'Something went wrong.',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => listProvider.load(
                query: searchController.text,
                reset: true,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty && featured.isEmpty) {
      return Center(
        child: Text(
          'No events found.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await listProvider.load(
          query: searchController.text,
          reset: true,
        );
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (featured.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Featured Events",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: featuredController,
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
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Upcoming Events",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= events.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final event = events[index];
                return EventCard(
                  title: event.title,
                  participants: event.registeredCount,
                  day: event.displayDay,
                  date: event.displayDate,
                  startTime: event.displayStartTime,
                  endTime: event.displayEndTime,
                  openSlots: event.slotsRemaining,
                  imageUrl: event.coverImageUrl,
                  onTap: () => EventModal.show(
                    context,
                    eventId: event.eventId,
                  ),
                );
              },
              childCount: events.length + (listProvider.isLoadingMore ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}
