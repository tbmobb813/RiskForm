import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/utils/validation.dart';
import 'package:riskform/exceptions/app_exceptions.dart';

void main() {
  test('Validator basic rules and errors', () {
    final v1 = validate<int>('n', null).required();
    expect(v1.isValid, isFalse);
    expect(v1.firstError, 'n is required');

    final v2 = validate<num>('x', -1).positive();
    expect(v2.isValid, isFalse);
    expect(v2.firstError, 'x must be positive');

    final v3 = validate<num>('y', -1).nonNegative();
    expect(v3.isValid, isFalse);
    expect(v3.firstError, 'y cannot be negative');

    final v4 = validate<num>('z', 10).lessThan(5);
    expect(v4.isValid, isFalse);
    expect(v4.firstError, 'z must be less than 5');

    final v5 = validate<num>('a', 1).greaterThan(5);
    expect(v5.isValid, isFalse);
    expect(v5.firstError, 'a must be greater than 5');

    final v6 = validate<num>('r', 0).inRange(1, 3);
    expect(v6.isValid, isFalse);
    expect(v6.firstError, 'r must be between 1 and 3');

    final v7 = validate<double>('f', double.nan).finite();
    expect(v7.isValid, isFalse);
    expect(v7.firstError, 'f must be a valid number');

    final now = DateTime.now();
    final future = now.add(const Duration(days: 1));
    final past = now.subtract(const Duration(days: 1));
    final vf = validate<DateTime>('d1', past).inFuture();
    expect(vf.isValid, isFalse);
    expect(vf.firstError, 'd1 must be in the future');

    final vp = validate<DateTime>('d2', future).inPast();
    expect(vp.isValid, isFalse);
    expect(vp.firstError, 'd2 must be in the past');

    final vc = validate<int>('c', 5).custom((v) => v > 10, 'too small');
    expect(vc.isValid, isFalse);
    expect(vc.firstError, 'too small');
  });

  test('ValidationResult merge and throwIfInvalid', () {
    final r1 = ValidationResult.fromErrors({'a': 'err1'});
    final r2 = ValidationResult.fromErrors({'b': 'err2'});
    final merged = r1.merge(r2);
    expect(merged.isValid, isFalse);
    expect(merged.errors.length, 2);

    final builder = ValidationBuilder();
    builder.add(validate<int>('n', null).required());
    final result = builder.build();
    expect(result.isValid, isFalse);
    expect(() => builder.throwIfInvalid(), throwsA(isA<ValidationException>()));
  });
}
