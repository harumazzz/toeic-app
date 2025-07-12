import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('can instantiate AuthRemoteDataSource', () {
    final dio = MockDio();
    final ds = AuthRemoteDataSource(dio);
    expect(ds, isA<AuthRemoteDataSource>());
  });
}
