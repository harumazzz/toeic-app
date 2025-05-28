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

  void d(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(
    final String message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}

@riverpod
LoggerService loggerService(final Ref ref) => LoggerService();
