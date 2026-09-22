/// Wraps a real error response from the API ({error: {message, code}} — see
/// middleware/errorHandler.js on the backend) so UI code can show the backend's actual message
/// instead of a generic "something went wrong", and branch on `code` where useful (e.g.
/// 'INVALID_TOTP' to keep the user on the TOTP screen instead of bouncing them back to login).
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;

  ApiException({required this.message, this.statusCode, this.code});

  factory ApiException.fromResponseData(dynamic data, int? statusCode) {
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        message: (error['message'] as String?) ?? 'Something went wrong.',
        code: error['code'] as String?,
        statusCode: statusCode,
      );
    }
    return ApiException(message: 'Something went wrong. Please try again.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
