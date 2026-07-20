import 'package:campus_event_app/features/events/data/event_repository.dart';
import 'package:campus_event_app/features/events/models/event.dart';
import 'package:campus_event_app/features/events/models/event_list_response.dart';
import 'package:campus_event_app/features/events/providers/previous_registration_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes only registrations whose date and end time have passed',
      () async {
    final repository = _FakePreviousRegisteredEventsRepository(
      previous: [_event('yesterday', '2026-07-19', '23:00')],
      upcoming: [
        _event('ended-today', '2026-07-20', '14:00'),
        _event('ending-now', '2026-07-20', '15:00'),
        _event('later-today', '2026-07-20', '16:00'),
        _event('tomorrow', '2026-07-21', '10:00'),
      ],
    );
    final provider = PreviousRegisteredEventsProvider(
      repository: repository,
      now: () => DateTime(2026, 7, 20, 15),
    );

    await provider.load();

    expect(
      provider.events.map((event) => event.eventId),
      ['ending-now', 'ended-today', 'yesterday'],
    );
    expect(provider.status, PreviousRegisteredEventsStatus.loaded);
  });
}

Event _event(String id, String date, String endTime) => Event(
      eventId: id,
      title: id,
      description: '',
      coverImageUrl: '',
      date: date,
      startTime: '09:00',
      endTime: endTime,
      eventMode: 'offline',
      hostName: '',
      contactEmails: const [],
      tags: const [],
      isOpenToGuests: false,
      registeredCount: 0,
      slotsRemaining: 0,
      isRegistered: true,
    );

class _FakePreviousRegisteredEventsRepository
    implements PreviousRegisteredEventsRepository {
  _FakePreviousRegisteredEventsRepository({
    required this.previous,
    required this.upcoming,
  });

  final List<Event> previous;
  final List<Event> upcoming;

  @override
  Future<EventListResponse> getPreviousRegisteredEvents({
    String? cursor,
  }) async {
    return EventListResponse(events: previous);
  }

  @override
  Future<EventListResponse> getUpcomingRegisteredEvents({
    String? cursor,
  }) async {
    return EventListResponse(events: upcoming);
  }
}
