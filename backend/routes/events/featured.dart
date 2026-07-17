import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// Default featured count when no `limit` query parameter is supplied.
const _defaultLimit = 3;

/// Inclusive upper bound for `limit` (PDF 3.7 / Dev C task).
const _maxLimit = 10;

/// Inclusive lower bound for `limit` when the param is present.
const _minLimit = 3;

/// GET /events/featured
///
/// Returns the soonest N upcoming approved events. "Featured" is computed
/// automatically — soonest by date, no popularity weighting.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final limit = _parseLimit(context.request.url.queryParameters['limit']);

    final events = await EventService.fetchFeatured(limit: limit);

    // Featured card shape (doc 3.5.3) — description included; no slots fields.
    final responseEvents = events.map((event) {
      return {
        'event_id': event.eventId,
        'title': event.title,
        'cover_image_url': event.coverImageUrl,
        'date': event.date,
        'start_time': event.startTime,
        'end_time': event.endTime,
        'description': event.description,
      };
    }).toList();

    return ResponseHelper.success(
      message: 'Featured events retrieved successfully.',
      data: {'events': responseEvents},
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} featured: $e\n$stack');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'code': EventErrorCode.internalError,
        'message': 'Internal server error',
      },
    );
  }
}

/// Parses and validates `limit` for featured: optional, default 3, range 3–10.
///
/// Throws [EventException] with [EventErrorCode.invalidQueryParam] when the
/// value is present but not an integer in [_minLimit]..[_maxLimit].
int _parseLimit(String? limitParam) {
  if (limitParam == null || limitParam.isEmpty) {
    return _defaultLimit;
  }

  final parsed = int.tryParse(limitParam);
  if (parsed == null || parsed < _minLimit || parsed > _maxLimit) {
    throw EventException(
      EventErrorCode.invalidQueryParam,
      'Invalid limit. Must be an integer between $_minLimit and $_maxLimit.',
    );
  }
  return parsed;
}
