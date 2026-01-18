# Yahoo Data Source Tests

This directory contains comprehensive test coverage for the `YahooDataSource` service.

## Running the Tests

Before running the tests, you need to generate the mock files:

```bash
# Install dependencies
flutter pub get

# Generate mock files
dart run build_runner build --delete-conflicting-outputs

# Run the tests
flutter test test/services/historical/yahoo_data_source_test.dart
```

## Test Coverage

The test suite covers:

1. **Successful data parsing** - Verifies correct parsing of Yahoo Finance API responses
2. **HTTP error handling** - Tests behavior when API returns non-200 status codes
3. **Empty responses** - Tests handling of null or empty result arrays
4. **Malformed JSON** - Tests error handling for invalid JSON responses
5. **Missing fields** - Tests graceful handling when expected fields are missing
6. **Null values in data** - Tests default value handling for null price data
7. **Edge cases** - Tests various edge cases like missing price arrays

## Implementation Details

The `YahooDataSource` class accepts an optional `http.Client` parameter in its constructor, which allows for dependency injection of a mock HTTP client during testing. This enables comprehensive testing without making actual network requests.
