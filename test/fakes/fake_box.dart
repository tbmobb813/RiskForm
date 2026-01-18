// ignore_for_file: subtype_of_sealed_class

import 'package:hive/hive.dart';

/// Fake implementation of Hive Box for testing
class FakeBox implements Box {
  final Map<String, dynamic> _storage = {};

  @override
  dynamic get(key, {defaultValue}) {
    return _storage[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  // Other Box methods not needed for these tests
  @override
  dynamic noSuchMethod(Invocation invocation) => 
      throw UnimplementedError('${invocation.memberName} not implemented in FakeBox');
}
