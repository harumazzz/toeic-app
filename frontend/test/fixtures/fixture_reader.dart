import 'dart:io';

/// Utility class to read test fixture files
class FixtureReader {
  /// Read fixture file content as string
  static String fixture(final String name) =>
      File('test/fixtures/$name').readAsStringSync();
}

/// Extension to make it easier to read fixtures
String fixture(final String name) => FixtureReader.fixture(name);
