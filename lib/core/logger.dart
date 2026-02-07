import 'package:logger/logger.dart';

/// Global logger instance for the application
final AppLogger appLogger = AppLogger._();

/// Centralized logging service to replace print() statements
class AppLogger {
  late final Logger _logger;

  AppLogger._() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to display
        errorMethodCount: 8, // Number of method calls for errors
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: true, // Print timestamp
      ),
    );
  }

  /// Log verbose/debug messages
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log critical/fatal error messages
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log API calls
  void apiCall(String method, String endpoint, {Map<String, dynamic>? params}) {
    info('API $method $endpoint', params);
  }

  /// Log API responses
  void apiResponse(String endpoint, int statusCode, {dynamic body}) {
    if (statusCode >= 200 && statusCode < 300) {
      debug('API Response [$statusCode] $endpoint');
    } else {
      error('API Error [$statusCode] $endpoint', body);
    }
  }
}
