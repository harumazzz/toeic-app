import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_service.g.dart';

@singleton
class LoggerService {
  LoggerService() {
    logger = Logger(
      printer: PrettyPrinter(
        dateTimeFormat:
            (final e) => DateFormat(
              'dd-MM-yyyy HH:mm:ss',
            ).format(e),
      ),
    );
  }
  late Logger logger;

  Future<void> d(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) async {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  Future<void> i(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) async {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  Future<void> w(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) async {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  Future<void> e(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) async {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  Future<void> wtf(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) async {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}

@riverpod
LoggerService loggerService(final Ref ref) => LoggerService();
