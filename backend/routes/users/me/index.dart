import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /users/me
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json( 
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  final uid = context.read<String>();
  final userDoc = context.read<Map<String, dynamic>>();

  return ResponseHelper.success(
    message: 'Profile retrieved successfully.',
    data: {
      'user': {
        'uid': uid,
        'email': userDoc['email'],
        'name': userDoc['name'],
        'contact': userDoc['contact'],
        'role': userDoc['role'],
      },
    },
  );
}
