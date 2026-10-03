class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Returns clean human-readable message without class name, status code, or errors: null.
  /// If validation errors are present, returns the first validation error message.
  String get userFriendlyMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstVal = errors!.values.first;
      if (firstVal is List && firstVal.isNotEmpty) {
        return firstVal.first.toString();
      }
      if (firstVal != null) {
        return firstVal.toString();
      }
    }
    return message;
  }

  @override
  String toString() => userFriendlyMessage;
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Koneksi jaringan terputus. Periksa sambungan internet.',
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Sesi telah berakhir. Silakan masuk kembali.',
    super.statusCode = 401,
  });
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    super.errors,
    super.statusCode = 422,
  });
}
