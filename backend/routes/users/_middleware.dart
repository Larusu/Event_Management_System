import 'package:dart_frog/dart_frog.dart';

/// Placeholder : Session & Role Enforcement
Handler middleware(Handler handler) {
  return handler.use((innerHandler) {
    return (context) async {
      return innerHandler(context);
    };
  });
}
