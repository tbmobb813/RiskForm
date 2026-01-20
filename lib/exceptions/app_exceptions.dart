/// Base exception for all app-specific exceptions.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Thrown when user is not authenticated or session expired.
class AuthenticationException extends AppException {
  const AuthenticationException([super.message = 'User not authenticated'])
      : super(code: 'AUTH_ERROR');

  factory AuthenticationException.sessionExpired() =>
      const AuthenticationException('Session expired. Please log in again.');

  factory AuthenticationException.notLoggedIn() =>
      const AuthenticationException('User must be logged in to perform this action.');
}

/// Thrown when input validation fails.
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
  }) : super(code: 'VALIDATION_ERROR');

  factory ValidationException.field(String field, String error) =>
      ValidationException('Invalid $field', fieldErrors: {field: error});

  factory ValidationException.required(String field) =>
      ValidationException('$field is required', fieldErrors: {field: 'Required'});

  factory ValidationException.multiple(Map<String, String> errors) =>
      ValidationException('Multiple validation errors', fieldErrors: errors);

  bool hasFieldError(String field) => fieldErrors.containsKey(field);
  String? getFieldError(String field) => fieldErrors[field];
}

/// Thrown when Firestore operations fail.
class FirestoreException extends AppException {
  const FirestoreException(
    super.message, {
    super.code = 'FIRESTORE_ERROR',
    super.originalError,
  });

  factory FirestoreException.notFound(String collection, String id) =>
      FirestoreException('Document not found: $collection/$id', code: 'NOT_FOUND');

  factory FirestoreException.permissionDenied() =>
      const FirestoreException('Permission denied', code: 'PERMISSION_DENIED');

  factory FirestoreException.networkError() =>
      const FirestoreException('Network error. Check your connection.', code: 'NETWORK_ERROR');

  factory FirestoreException.fromError(dynamic error) =>
      FirestoreException('Firestore operation failed', originalError: error);
}

/// Thrown when engine computations fail.
class EngineException extends AppException {
  const EngineException(
    super.message, {
    super.code = 'ENGINE_ERROR',
    super.originalError,
  });

  factory EngineException.invalidConfig(String reason) =>
      EngineException('Invalid configuration: $reason', code: 'INVALID_CONFIG');

  factory EngineException.computationFailed(String operation) =>
      EngineException('$operation computation failed', code: 'COMPUTATION_FAILED');

  factory EngineException.invalidPricePath() =>
      const EngineException('Price path cannot be empty', code: 'INVALID_PRICE_PATH');
}

/// Thrown when backtest operations fail.
class BacktestException extends AppException {
  const BacktestException(
    super.message, {
    super.code = 'BACKTEST_ERROR',
    super.originalError,
  });

  factory BacktestException.emptyPricePath() =>
      const BacktestException('Backtest requires a non-empty price path', code: 'EMPTY_PRICE_PATH');

  factory BacktestException.invalidDateRange() =>
      const BacktestException('Invalid date range for backtest', code: 'INVALID_DATE_RANGE');

  factory BacktestException.timeout() =>
      const BacktestException('Backtest timed out', code: 'TIMEOUT');
}

/// Thrown when data layer operations fail.
class DataException extends AppException {
  const DataException(
    super.message, {
    super.code = 'DATA_ERROR',
    super.originalError,
  });

  factory DataException.parseFailed(String type, dynamic value) =>
      DataException('Failed to parse $type from: $value', code: 'PARSE_FAILED');

  factory DataException.serializationFailed(String type) =>
      DataException('Failed to serialize $type', code: 'SERIALIZATION_FAILED');

  factory DataException.missingField(String field) =>
      DataException('Missing required field: $field', code: 'MISSING_FIELD');
}
