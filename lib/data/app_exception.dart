import 'dart:convert';

class AppException implements Exception {
  final String? message;
  final String? prefix;

  AppException([this.message, this.prefix]);

  @override
  String toString() {
    return '${prefix ?? ''}${message ?? ''}';
  }

  /// This extracts clean error detail if message is JSON
  String get cleanMessage {
    if (message == null) return prefix ?? '';
    try {
      final decoded = jsonDecode(message!);
      if (decoded is Map && decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Not JSON or no "detail" field
    }
    return message!;
  }
}

class InternetException extends AppException {
  InternetException([String? message]) : super(message, 'No Internet: ');
}

class RequestTimeout extends AppException {
  RequestTimeout([String? message]) : super(message, 'Request Timeout: ');
}

class ServerException extends AppException {
  ServerException([String? message]) : super(message, 'Internal Server Error: ');
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, 'Invalid Input: ');
}

class FatchDataException extends AppException {
  FatchDataException([String? message]) : super(message, '');
}
