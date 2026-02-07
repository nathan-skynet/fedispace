import 'dart:convert';
// Custom exception types for better error handling

/// Base exception class for all API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

/// Exception thrown when network connectivity issues occur
class NetworkException extends ApiException {
  NetworkException(String message, {dynamic originalError})
      : super(
          message,
          originalError: originalError,
        );
}

/// Exception thrown when authentication fails
class AuthenticationException extends ApiException {
  AuthenticationException(String message, {int? statusCode})
      : super(
          message,
          statusCode: statusCode ?? 401,
        );
}

/// Exception thrown when requested resource is not found
class NotFoundException extends ApiException {
  NotFoundException(String message)
      : super(
          message,
          statusCode: 404,
        );
}

/// Exception thrown when server returns an error
class ServerException extends ApiException {
  ServerException(String message, {int? statusCode})
      : super(
          message,
          statusCode: statusCode ?? 500,
        );
}

/// Exception thrown when validation fails
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  ValidationException(
    String message, {
    this.errors,
  }) : super(message, statusCode: 422);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return 'ValidationException: $message\nErrors: $errors';
    }
    return 'ValidationException: $message';
  }
}

/// Helper class to handle HTTP responses and throw appropriate exceptions
class ErrorHandler {
  /// Process HTTP response and throw appropriate exception if needed
  static void handleResponse(int statusCode, String response) {
    if (statusCode >= 200 && statusCode < 300) {
      return; // Success, no error
    }

    // Try to parse error message from response
    String errorMessage = 'An error occurred';
    try {
      final Map<String, dynamic> json = 
          (response.isNotEmpty) ? parseJson(response) : {};
      errorMessage = json['error'] ?? json['message'] ?? errorMessage;
    } catch (_) {
      // If parsing fails, use the raw response
      errorMessage = response.isNotEmpty ? response : errorMessage;
    }

    if (statusCode == 400) {
      throw ValidationException(errorMessage);
    } else if (statusCode == 401 || statusCode == 403) {
      throw AuthenticationException(errorMessage, statusCode: statusCode);
    } else if (statusCode == 404) {
      throw NotFoundException(errorMessage);
    } else if (statusCode == 422) {
      throw ValidationException(errorMessage);
    } else if (statusCode >= 500) {
      throw ServerException(errorMessage, statusCode: statusCode);
    } else {
      throw ApiException(errorMessage, statusCode: statusCode);
    }
  }

  /// Safely parse JSON and throw NetworkException on failure
  static Map<String, dynamic> parseJson(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw NetworkException(
        'Failed to parse server response',
        originalError: e,
      );
    }
  }

  /// Handle network errors
  static Never handleNetworkError(dynamic error) {
    if (error is ApiException) {
      throw error;
    }
    throw NetworkException(
      'Network request failed: ${error.toString()}',
      originalError: error,
    );
  }
}
