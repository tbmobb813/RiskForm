import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application_2/services/historical/yahoo_data_source.dart';
import 'package:flutter_application_2/models/historical/historical_price.dart';

import 'yahoo_data_source_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('YahooDataSource', () {
    late YahooDataSource dataSource;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      dataSource = YahooDataSource(client: mockClient);
    });

    test('fetchDailyPrices returns parsed data on successful response', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": [
            {
              "timestamp": [1704067200, 1704153600, 1704240000],
              "indicators": {
                "quote": [
                  {
                    "open": [150.0, 151.0, 152.0],
                    "high": [155.0, 156.0, 157.0],
                    "low": [149.0, 150.0, 151.0],
                    "close": [154.0, 155.0, 156.0],
                    "volume": [1000000, 1100000, 1200000]
                  }
                ]
              }
            }
          ]
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices.length, equals(3));
      expect(prices[0].open, equals(150.0));
      expect(prices[0].high, equals(155.0));
      expect(prices[0].low, equals(149.0));
      expect(prices[0].close, equals(154.0));
      expect(prices[0].volume, equals(1000000.0));
      expect(prices[1].open, equals(151.0));
      expect(prices[2].close, equals(156.0));
    });

    test('fetchDailyPrices throws exception on non-200 status code', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => dataSource.fetchDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch historical data: 404'),
        )),
      );
    });

    test('fetchDailyPrices returns empty list when result is null', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {}
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices, isEmpty);
    });

    test('fetchDailyPrices returns empty list when result is empty array', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": []
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices, isEmpty);
    });

    test('fetchDailyPrices throws exception when result is not a List', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": "invalid"
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      expect(
        () => dataSource.fetchDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Unexpected Yahoo Finance API response format'),
        )),
      );
    });

    test('fetchDailyPrices returns empty list when indicators are missing', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": [
            {
              "timestamp": [1704067200, 1704153600]
            }
          ]
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices, isEmpty);
    });

    test('fetchDailyPrices handles null values in price arrays', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": [
            {
              "timestamp": [1704067200, 1704153600],
              "indicators": {
                "quote": [
                  {
                    "open": [150.0, null],
                    "high": [null, 156.0],
                    "low": [149.0, null],
                    "close": [154.0, 155.0],
                    "volume": [null, 1100000]
                  }
                ]
              }
            }
          ]
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices.length, equals(2));
      expect(prices[0].open, equals(150.0));
      expect(prices[0].high, equals(0.0)); // null defaults to 0.0
      expect(prices[0].volume, equals(0.0)); // null defaults to 0.0
      expect(prices[1].open, equals(0.0)); // null defaults to 0.0
      expect(prices[1].high, equals(156.0));
      expect(prices[1].close, equals(155.0));
    });

    test('fetchDailyPrices handles missing arrays by using defaults', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      final mockResponse = '''
      {
        "chart": {
          "result": [
            {
              "timestamp": [1704067200, 1704153600],
              "indicators": {
                "quote": [
                  {
                    "close": [154.0, 155.0]
                  }
                ]
              }
            }
          ]
        }
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final prices = await dataSource.fetchDailyPrices(
        symbol: symbol,
        start: start,
        end: end,
      );

      expect(prices.length, equals(2));
      expect(prices[0].open, equals(0.0));
      expect(prices[0].high, equals(0.0));
      expect(prices[0].low, equals(0.0));
      expect(prices[0].close, equals(154.0));
      expect(prices[0].volume, equals(0.0));
    });

    test('fetchDailyPrices handles malformed JSON', () async {
      final symbol = 'AAPL';
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('not valid json', 200));

      expect(
        () => dataSource.fetchDailyPrices(
          symbol: symbol,
          start: start,
          end: end,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
