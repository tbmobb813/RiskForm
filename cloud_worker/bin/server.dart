import 'dart:convert';
import 'dart:io';

/// Cloud Run backtest worker server.
///
/// Endpoints:
/// - GET /health - Health check
/// - POST /run-backtest - Execute backtest with provided config
///
/// To run locally:
///   cd cloud_worker
///   dart run bin/server.dart
///
/// To deploy to Cloud Run:
///   gcloud builds submit --tag gcr.io/PROJECT_ID/riskform-backtest-worker
///   gcloud run deploy riskform-backtest-worker \
///     --image gcr.io/PROJECT_ID/riskform-backtest-worker \
///     --platform managed \
///     --region us-central1 \
///     --allow-unauthenticated \
///     --concurrency 1 \
///     --memory 512Mi \
///     --timeout 300
Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  _log('INFO', 'server_started', {'port': port});

  await for (final request in server) {
    await _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  // Health check endpoint
  if (method == 'GET' && path == '/health') {
    await _handleHealth(request);
    return;
  }

  // Run backtest endpoint
  if (method == 'POST' && path == '/run-backtest') {
    await _handleRunBacktest(request);
    return;
  }

  // 404 Not Found
  request.response
    ..statusCode = HttpStatus.notFound
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'error': 'Not found'}));
  await request.response.close();
}

Future<void> _handleHealth(HttpRequest request) async {
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    }));
  await request.response.close();
}

Future<void> _handleRunBacktest(HttpRequest request) async {
  final startTime = DateTime.now();

  try {
    // Parse request body
    final body = await utf8.decoder.bind(request).join();
    final jsonBody = jsonDecode(body) as Map<String, dynamic>;

    final configUsed = jsonBody['configUsed'] as Map<String, dynamic>?;
    if (configUsed == null) {
      _log('ERROR', 'invalid_request', {'message': 'Missing configUsed'});
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Missing configUsed in request body'}));
      await request.response.close();
      return;
    }

    _log('INFO', 'backtest_started', {
      'symbol': configUsed['symbol'],
      'strategyId': configUsed['strategyId'],
    });

    // TODO: Import and use actual BacktestEngine from main project
    // For now, return a placeholder result
    //
    // In production, this would be:
    //
    // import 'package:riskform/services/engines/backtest_engine.dart';
    // import 'package:riskform/models/backtest/backtest_config.dart';
    //
    // final config = BacktestConfig.fromMap(configUsed);
    // final engine = BacktestEngine();
    // final result = engine.run(config);
    // final resultMap = result.toMap();

    final resultMap = _createPlaceholderResult(configUsed);

    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    _log('INFO', 'backtest_completed', {
      'durationMs': durationMs,
      'cyclesCompleted': resultMap['cyclesCompleted'],
    });

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'backtestResult': resultMap}));
    await request.response.close();

  } catch (e, stackTrace) {
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    _log('ERROR', 'backtest_failed', {
      'error': e.toString(),
      'durationMs': durationMs,
    });
    stderr.writeln('Stack trace: $stackTrace');

    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
}

/// Create a placeholder backtest result for testing.
///
/// TODO: Replace with actual engine call once the engine is properly
/// imported into the cloud_worker package.
Map<String, dynamic> _createPlaceholderResult(Map<String, dynamic> configUsed) {
  return {
    'configUsed': configUsed,
    'equityCurve': [100000.0, 101000.0, 102500.0, 103000.0, 104200.0],
    'maxDrawdown': -0.08,
    'totalReturn': 0.042,
    'cyclesCompleted': 5,
    'notes': [
      'Cloud backtest completed',
      'Placeholder result - replace with actual engine',
    ],
    'cycles': <Map<String, dynamic>>[],
    'avgCycleReturn': 0.0084,
    'avgCycleDurationDays': 21.0,
    'assignmentRate': 0.2,
    'uptrendAvgCycleReturn': 0.012,
    'downtrendAvgCycleReturn': 0.004,
    'sidewaysAvgCycleReturn': 0.008,
    'uptrendAssignmentRate': 0.1,
    'downtrendAssignmentRate': 0.4,
    'sidewaysAssignmentRate': 0.2,
    'engineVersion': '1.0.0',
    'regimeSegments': <Map<String, dynamic>>[],
  };
}

/// Structured logging for Cloud Logging compatibility.
void _log(String severity, String event, Map<String, dynamic> data) {
  final logEntry = {
    'severity': severity,
    'event': event,
    'timestamp': DateTime.now().toIso8601String(),
    ...data,
  };
  stdout.writeln(jsonEncode(logEntry));
}
