import '../exceptions/app_exceptions.dart';

/// Result of a validation operation.
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult.valid()
      : isValid = true,
        errors = const {};

  const ValidationResult.invalid(this.errors) : isValid = false;

  factory ValidationResult.fromErrors(Map<String, String> errors) {
    if (errors.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(errors);
  }

  /// Throws ValidationException if invalid.
  void throwIfInvalid() {
    if (!isValid) {
      throw ValidationException.multiple(errors);
    }
  }

  /// Merges multiple validation results.
  ValidationResult merge(ValidationResult other) {
    if (isValid && other.isValid) return const ValidationResult.valid();
    return ValidationResult.invalid({...errors, ...other.errors});
  }
}

/// Fluent validator for building validation rules.
class Validator<T> {
  final String fieldName;
  final T? value;
  final List<String> _errors = [];

  Validator(this.fieldName, this.value);

  /// Value must not be null.
  Validator<T> required() {
    if (value == null) {
      _errors.add('$fieldName is required');
    }
    return this;
  }

  /// For numeric values: must be positive (> 0).
  Validator<T> positive() {
    if (value != null && value is num && (value as num) <= 0) {
      _errors.add('$fieldName must be positive');
    }
    return this;
  }

  /// For numeric values: must be non-negative (>= 0).
  Validator<T> nonNegative() {
    if (value != null && value is num && (value as num) < 0) {
      _errors.add('$fieldName cannot be negative');
    }
    return this;
  }

  /// For numeric values: must be less than max.
  Validator<T> lessThan(num max) {
    if (value != null && value is num && (value as num) >= max) {
      _errors.add('$fieldName must be less than $max');
    }
    return this;
  }

  /// For numeric values: must be greater than min.
  Validator<T> greaterThan(num min) {
    if (value != null && value is num && (value as num) <= min) {
      _errors.add('$fieldName must be greater than $min');
    }
    return this;
  }

  /// For numeric values: must be within range (inclusive).
  Validator<T> inRange(num min, num max) {
    if (value != null && value is num) {
      final v = value as num;
      if (v < min || v > max) {
        _errors.add('$fieldName must be between $min and $max');
      }
    }
    return this;
  }

  /// For numeric values: must not be NaN or Infinity.
  Validator<T> finite() {
    if (value != null && value is double) {
      final v = value as double;
      if (v.isNaN || v.isInfinite) {
        _errors.add('$fieldName must be a valid number');
      }
    }
    return this;
  }

  /// For DateTime: must be in the future.
  Validator<T> inFuture() {
    if (value != null && value is DateTime) {
      if ((value as DateTime).isBefore(DateTime.now())) {
        _errors.add('$fieldName must be in the future');
      }
    }
    return this;
  }

  /// For DateTime: must be in the past.
  Validator<T> inPast() {
    if (value != null && value is DateTime) {
      if ((value as DateTime).isAfter(DateTime.now())) {
        _errors.add('$fieldName must be in the past');
      }
    }
    return this;
  }

  /// Custom validation rule.
  Validator<T> custom(bool Function(T value) predicate, String errorMessage) {
    if (value != null && !predicate(value as T)) {
      _errors.add(errorMessage);
    }
    return this;
  }

  /// Returns true if all validations passed.
  bool get isValid => _errors.isEmpty;

  /// Returns list of error messages.
  List<String> get errors => List.unmodifiable(_errors);

  /// Returns first error or null.
  String? get firstError => _errors.isEmpty ? null : _errors.first;
}

/// Builder for validating multiple fields at once.
class ValidationBuilder {
  final Map<String, List<String>> _fieldErrors = {};

  /// Add a field validator.
  ValidationBuilder add<T>(Validator<T> validator) {
    if (!validator.isValid) {
      _fieldErrors[validator.fieldName] = validator.errors;
    }
    return this;
  }

  /// Build the final validation result.
  ValidationResult build() {
    if (_fieldErrors.isEmpty) {
      return const ValidationResult.valid();
    }

    final errors = <String, String>{};
    for (final entry in _fieldErrors.entries) {
      errors[entry.key] = entry.value.join('; ');
    }
    return ValidationResult.invalid(errors);
  }

  /// Throws ValidationException if any validation failed.
  void throwIfInvalid() {
    build().throwIfInvalid();
  }
}

/// Convenience function to create a validator.
Validator<T> validate<T>(String fieldName, T? value) => Validator(fieldName, value);
