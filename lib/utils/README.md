Utility helpers for Firestore and callables

- `serialize_for_callable.dart`: recursively converts `DateTime` and
  Firestore `Timestamp` into UTC ISO8601 strings suitable for `httpsCallable`.
- `firestore_helpers.dart`: helpers to convert client values to Firestore-friendly
  forms (e.g., `DateTime` -> `Timestamp`) and `stripNulls` for shallow sanitization.
- `payload_builders.dart`: builders for canonical callable payloads, e.g. `buildScoreTradePayload`.

Usage examples

1) Build and call the server scoring callable:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'utils/payload_builders.dart' as pb;

final callable = FirebaseFunctions.instance.httpsCallable('scoreTrade');
final payload = pb.buildScoreTradePayload(journalId: 'j1', plannedParams: planned, executedParams: exec);
final res = await callable.call(payload);
```

2) Prepare Firestore-friendly map before write:

```dart
import 'utils/firestore_helpers.dart' as fh;

final doc = fh.toFirestoreMap({'openedAt': DateTime.now(), 'note': null});
final cleaned = fh.stripNulls(doc);
await firestore.collection('positions').doc().set(cleaned);
```

Testing

Run `flutter test` to execute unit tests for these utilities.
