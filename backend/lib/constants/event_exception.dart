import 'package:backend/utils/response_helper.dart';

/// Exception thrown when event operations fail.
class EventException extends AppException {
  EventException(super.code, super.message);
}
