import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../presentation/widgets/event_modal.dart';
import '../../providers/previous_registration_provider.dart';

class PreviousRegisteredEventsScreen extends StatelessWidget {
  const PreviousRegisteredEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PreviousRegisteredEventsProvider()..load(),
      child: const _PreviousRegisteredEventsView(),
    );
  }
}

class _PreviousRegisteredEventsView extends StatefulWidget {
  const _PreviousRegisteredEventsView();

  @override
  State<_PreviousRegisteredEventsView> createState() =>
      _PreviousRegisteredEventsViewState();
}

class _PreviousRegisteredEventsViewState
    extends State<_PreviousRegisteredEventsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<PreviousRegisteredEventsProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        provider.hasMore &&
        !provider.isLoadingMore) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreviousRegisteredEventsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Previous Registrations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(PreviousRegisteredEventsProvider provider) {
    switch (provider.status) {
      case PreviousRegisteredEventsStatus.idle:
      case PreviousRegisteredEventsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PreviousRegisteredEventsStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  provider.errorMessage ?? 'Something went wrong.',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case PreviousRegisteredEventsStatus.loaded:
        if (provider.events.isEmpty) {
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No previous registrations.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.load,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount:
                provider.events.length + (provider.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= provider.events.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final event = provider.events[index];
              return _PreviousRegistrationTile(
                event: event,
                onTap: () => EventModal.show(
                  context,
                  eventId: event.eventId,
                ),
              );
            },
          ),
        );
    }
  }
}

class _PreviousRegistrationTile extends StatelessWidget {
  const _PreviousRegistrationTile({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.displayDate}  •  '
                      '${event.displayStartTime} - ${event.displayEndTime}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
