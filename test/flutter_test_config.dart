import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// This file is loaded by the test harness before running tests.
// It must export `testExecutable` which the test listener will call.

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide mock handlers for firebase_core pigeon platform channels so tests
  // don't attempt real platform channel connections.
  const initializeCoreChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    initializeCoreChannel,
    (MethodCall method) async {
      return <String, dynamic>{'name': 'flutterTestApp', 'options': <String, dynamic>{}};
    },
  );

  const initializeAppChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeApp',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    initializeAppChannel,
    (MethodCall method) async {
      return <String, dynamic>{'name': 'flutterTestApp', 'appName': 'flutterTestApp'};
    },
  );

  const allAppsChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.allApps',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    allAppsChannel,
    (MethodCall method) async {
      return <Map<String, dynamic>>[];
    },
  );

  const appChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.app',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    appChannel,
    (MethodCall method) async {
      return <String, dynamic>{'name': 'flutterTestApp', 'options': <String, dynamic>{}};
    },
  );

  const deleteAppChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.deleteApp',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    deleteAppChannel,
    (MethodCall method) async {
      return null;
    },
  );

  await testMain();
}
