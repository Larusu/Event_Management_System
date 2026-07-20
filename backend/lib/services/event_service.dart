import 'dart:async';
import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/models/event.dart';
import 'package:backend/services/firestore_client.dart';
import 'package:backend/utils/response_helper.dart';

import 'package:http/http.dart' as http;

/// Service for fetching events from Firestore.
///
/// Handles querying the events collection with filtering, search, and
/// cursor-based pagination.
class EventService {
  /// Number of documents fetched from Firestore per batch while scanning.
  static const int _batchSize = 100;

  static Future<http.Client> _firestoreClient() => FirestoreClient.instance();

  static String _firestoreProjectId() => FirestoreClient.projectId();

  /// Fetches a page of events with optional filtering and pagination.
  ///
  /// Firestore is queried in batches ordered by `date` ascending (then document
  /// ID as a tiebreaker) - a chronological feed. This uses only single-field
  /// indexes: there are no where-filters (`status == "approved"`,
  /// `is_deleted == false`, `tags`, and `search` are applied client-side).
  /// Because filtering happens after fetching, we keep pulling batches until
  /// the page is full or the collection is exhausted - this prevents a page
  /// from ending early (and silently dropping matching events) just because a
  /// batch happened to be mostly filtered out.
  ///
  /// Note: documents without a `date` field are excluded by Firestore's
  /// order-by, which is the intended behavior for a dated event feed.
  ///
  /// - `tags`: comma-separated, URL-decoded, matched case-sensitively (ANY)
  /// - `search`: case-insensitive substring match on title
  /// - `cursor`: base64-encoded JSON `{date, eventId}` for pagination
  /// - `limit`: max number of results returned (default 20)
  ///
  /// Returns an [EventPage] with the matched events and the cursor payload to
  /// resume from on the next page (null when there are no more results).
  static Future<EventPage> fetchEvents({
    String? tags,
    String? search,
    String? cursor,
    int limit = 20,
  }) async {
    final startAfter = _decodeCursor(cursor);

    final matched = <Event>[];
    // Where the next Firestore batch resumes. Starts at the incoming cursor and
    // advances by the LAST document scanned each batch, so we keep moving
    // forward even through documents that get filtered out.
    var batchStartAfter = startAfter;
    // The sort position (date + id) of the last event we actually added to the
    // page. This - not the last doc scanned - is what the next client page must
    // resume after.
    Map<String, String>? lastMatched;
    var exhausted = false;

    while (matched.length < limit && !exhausted) {
      final batch = await _fetchBatch(startAfter: batchStartAfter);

      // Firestore returned fewer docs than requested -> no more docs exist.
      if (batch.docCount < _batchSize) {
        exhausted = true;
      }
      if (batch.lastDoc != null) {
        batchStartAfter = batch.lastDoc;
      }

      for (final event in batch.events) {
        if (_passesFilters(event, tags: tags, search: search)) {
          matched.add(event);
          lastMatched = {'date': event.date, 'eventId': event.eventId};
          if (matched.length == limit) {
            break;
          }
        }
      }
    }

    // A full page means there may be more results, so hand back a cursor.
    // Stopping because the collection ran out means this is the last page.
    final nextCursor = matched.length == limit ? lastMatched : null;
    return EventPage(events: matched, nextCursor: nextCursor);
  }

  /// Fetches the soonest [limit] upcoming approved events (Featured).
  ///
  /// Filters `status == approved`, `is_deleted == false`, and `date >= today`
  /// (YYYY-MM-DD, UTC calendar date). Sorted by date ascending — this is the
  /// entire "featured" rule; no popularity weighting.
  ///
  /// [limit] must already be validated by the route (default 3, max 10).
  static Future<List<Event>> fetchFeatured({int limit = 3}) async {
    final today = _todayUtcDateString();
    final matched = <Event>[];
    Map<String, String>? batchStartAfter;
    var exhausted = false;

    while (matched.length < limit && !exhausted) {
      final batch = await _fetchBatch(startAfter: batchStartAfter);

      if (batch.docCount < _batchSize) {
        exhausted = true;
      }
      if (batch.lastDoc != null) {
        batchStartAfter = batch.lastDoc;
      }

      for (final event in batch.events) {
        if (!_passesFeaturedFilters(event, today: today)) {
          continue;
        }
        matched.add(event);
        if (matched.length == limit) {
          break;
        }
      }
    }

    return matched;
  }

  /// Returns all unique tags from approved, non-deleted events.
  ///
  /// Uses the same batch-scanning approach as [fetchEvents] but only
  /// collects tags, stopping early once the collection is exhausted.
  static Future<List<String>> fetchTags() async {
    var batchStartAfter = <String, String>{};
    var exhausted = false;
    final allTags = <String>{};

    while (!exhausted) {
      final batch = await _fetchBatch(
        startAfter: batchStartAfter.isNotEmpty ? batchStartAfter : null,
      );

      if (batch.docCount < _batchSize) {
        exhausted = true;
      }
      if (batch.lastDoc != null) {
        batchStartAfter = batch.lastDoc!;
      }

      for (final event in batch.events) {
        if (_passesFilters(event)) {
          allTags.addAll(event.tags);
        }
      }
    }

    final sorted = allTags.toList()..sort();
    return sorted;
  }

  /// UTC calendar date as `YYYY-MM-DD` — used for featured `date >= today`.
  static String _todayUtcDateString() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Featured filter: approved, not deleted, and on/after [today].
  static bool _passesFeaturedFilters(Event event, {required String today}) {
    if (!_passesFilters(event)) {
      return false;
    }
    // ISO date strings compare lexicographically in chronological order.
    return event.date.compareTo(today) >= 0;
  }

  /// Decodes and validates the incoming opaque [cursor].
  ///
  /// Returns null when no cursor is supplied, or the `{date, eventId}` payload.
  /// Throws [EventException] with [EventErrorCode.invalidQueryParam] when the
  /// cursor is malformed or missing required fields.
  static Map<String, String>? _decodeCursor(String? cursor) {
    if (cursor == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(cursor)));
      if (decoded is! Map<String, dynamic> ||
          decoded['eventId'] is! String ||
          (decoded['eventId'] as String).isEmpty ||
          decoded['date'] is! String) {
        throw EventException(
          EventErrorCode.invalidQueryParam,
          'Invalid cursor',
        );
      }
      return {
        'date': decoded['date'] as String,
        'eventId': decoded['eventId'] as String,
      };
    } catch (e) {
      if (e is EventException) rethrow;
      throw EventException(EventErrorCode.invalidQueryParam, 'Invalid cursor');
    }
  }

  /// Fetches a single batch of events from Firestore ordered by date then id.
  ///
  /// Returns the parsed events plus the raw document count and the sort
  /// position of the last document seen. Exhaustion is detected from the raw
  /// document count (not the parsed count) so filtered/unparseable docs can't
  /// be mistaken for the end of the collection, and the scan cursor advances by
  /// the last document seen so a bad document can never stall pagination.
  static Future<_EventBatch> _fetchBatch({
    Map<String, String>? startAfter,
    int batchSize = _batchSize,
  }) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final structuredQuery = _buildQuery(
      projectId: projectId,
      startAfter: startAfter,
      limit: batchSize,
    );

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents:runQuery',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'structuredQuery': structuredQuery}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore query failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final events = <Event>[];
    var docCount = 0;
    Map<String, String>? lastDoc;

    for (final entry in decoded) {
      // runQuery rows may be bare readTime entries with no document key.
      final row = entry as Map<String, dynamic>?;
      final document = row?['document'] as Map<String, dynamic>?;
      if (document == null) {
        continue;
      }

      docCount++;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      final resourceName = document['name'] as String? ?? '';
      final eventId = resourceName.split('/').last;
      // Read date directly so the scan cursor is correct even if the full parse
      // fails. Every returned doc has a date (order-by excludes docs without).
      final dateField = fields['date'] as Map<String, dynamic>?;
      final date = dateField?['stringValue'] as String? ?? '';
      lastDoc = {'date': date, 'eventId': eventId};

      try {
        final event = _parseEventFromFields(fields, eventId);
        if (event != null) {
          events.add(event);
        }
      } catch (_) {
        // Skip a malformed document - don't let one bad doc crash the query.
        continue;
      }
    }

    return _EventBatch(events: events, lastDoc: lastDoc, docCount: docCount);
  }

  static Map<String, dynamic> _buildQuery({
    required String projectId,
    Map<String, String>? startAfter,
    int limit = 20,
  }) {
    // Chronological order (date, then document id as a stable tiebreaker).
    // Both are covered by single-field indexes, so no composite index needed.
    final query = <String, dynamic>{
      'from': [
        {'collectionId': 'events'},
      ],
      'orderBy': [
        {
          'field': {'fieldPath': 'date'},
          'direction': 'ASCENDING',
        },
        {
          'field': {'fieldPath': '__name__'},
          'direction': 'ASCENDING',
        },
      ],
      'limit': limit,
    };

    if (startAfter != null) {
      query['startAt'] = buildStartAtCursor(
        projectId: projectId,
        date: startAfter['date'] ?? '',
        eventId: startAfter['eventId'] ?? '',
      );
    }

    return query;
  }

  /// Builds the Firestore `startAt` Cursor object used to resume pagination
  /// strictly after the event identified by [date] and [eventId].
  ///
  /// The value order must match the query's order-by (date, then `__name__`).
  /// Exposed so the cursor structure can be unit-tested without a live
  /// Firestore.
  static Map<String, dynamic> buildStartAtCursor({
    required String projectId,
    required String date,
    required String eventId,
  }) {
    final docPath =
        'projects/$projectId/databases/(default)'
        '/documents/events/$eventId';
    return {
      'values': [
        {'stringValue': date},
        {'referenceValue': docPath},
      ],
      // Exclusive: resume strictly after this document.
      'before': false,
    };
  }

  /// Client-side filter predicate for a single event.
  ///
  /// Applied per event during the batch scan (fields here would otherwise need
  /// Firestore composite indexes).
  static bool _passesFilters(
    Event event, {
    String? tags,
    String? search,
  }) {
    if (event.status != 'approved') {
      return false;
    }
    if (event.isDeleted) {
      return false;
    }

    // Tags: match if ANY requested tag is present (case-sensitive).
    if (tags != null && tags.isNotEmpty) {
      final eventTags = event.tags.toSet();
      final filterTags = tags.split(',').map((t) => t.trim()).toSet();
      if (!eventTags.any(filterTags.contains)) {
        return false;
      }
    }

    // Search: case-insensitive substring match on title.
    if (search != null && search.isNotEmpty) {
      if (!event.title.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  static Event? _parseEventFromFields(
    Map<String, dynamic> fields,
    String eventId,
  ) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
    int? intField(String key) {
      final value =
          (fields[key] as Map<String, dynamic>?)?['integerValue'] as String?;
      if (value == null) return null;
      return int.tryParse(value);
    }

    bool boolField(String key) {
      final field = fields[key];
      if (field is Map<String, dynamic>) {
        final boolValue = field['booleanValue'];
        if (boolValue is bool) return boolValue;
      }
      return false;
    }

    List<String>? arrayField(String key) {
      final arr = fields[key] as Map<String, dynamic>?;
      if (arr == null) {
        return null;
      }
      final values = arr['arrayValue'] as Map<String, dynamic>?;
      if (values == null) {
        return null;
      }
      final fieldValues = values['values'] as List<dynamic>?;
      if (fieldValues == null) {
        return null;
      }
      return fieldValues.whereType<Map<String, dynamic>>().map((map) {
        return (map['stringValue'] as String?) ?? '';
      }).toList();
    }

    final title = stringField('title');
    if (title == null) {
      return null;
    }

    final status = stringField('status') ?? 'draft';

    return Event(
      eventId: eventId,
      title: title,
      description: stringField('description') ?? '',
      coverImageUrl: stringField('cover_image_url') ?? '',
      date: stringField('date') ?? '',
      startTime: stringField('start_time') ?? '',
      endTime: stringField('end_time') ?? '',
      eventMode: stringField('event_mode') ?? '',
      location: stringField('location'),
      streamLink: stringField('stream_link'),
      hostName: stringField('host_name') ?? '',
      guestSpeaker: stringField('guest_speaker'),
      contactEmails: arrayField('contact_emails') ?? [],
      tags: arrayField('tags') ?? [],
      isOpenToGuests: boolField('is_open_to_guests'),
      slotsTotal: intField('slots_total') ?? 0,
      registeredCount: intField('registered_count') ?? 0,
      status: status,
      isDeleted: boolField('is_deleted'),
    );
  }
}

/// A single page of events plus the cursor payload for the next page.
class EventPage {
  /// Creates a page of [events] with an optional [nextCursor] payload.
  EventPage({required this.events, this.nextCursor});

  /// The events in this page (already filtered, at most `limit`).
  final List<Event> events;

  /// `{date, eventId}` to resume after on the next page, or null if this is the
  /// last page. The route encodes this into the opaque base64 cursor.
  final Map<String, String>? nextCursor;
}

/// One batch of documents read from Firestore.
class _EventBatch {
  _EventBatch({
    required this.events,
    required this.docCount,
    this.lastDoc,
  });

  /// Successfully parsed events from this batch.
  final List<Event> events;

  /// Number of raw documents returned (used to detect exhaustion).
  final int docCount;

  /// Sort position `{date, eventId}` of the last raw document seen (used to
  /// advance the scan cursor).
  final Map<String, String>? lastDoc;
}
