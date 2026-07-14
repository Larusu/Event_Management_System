/// Defines all event error codes returned by the backend.
class EventErrorCode {
  EventErrorCode._();

  /// The event does not exist, is soft-deleted, or is not approved. (404)
  ///
  /// All three cases return the same code and message so the API never
  /// reveals whether an unapproved event exists.
  static const String notFound = 'EVT002';

  /// Maps each event error code to its HTTP status code.
  static const Map<String, int> statusFor = {
    notFound: 404,
  };
}
