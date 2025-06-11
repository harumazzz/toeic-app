import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  const ToastService._();

  static void show({
    required final BuildContext context,
    required final String message,
    final ToastificationType type = ToastificationType.info,
    final Duration duration = const Duration(seconds: 2),
  }) {
    toastification.show(
      context: context,
      title: Text(
        message,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color:
              type == ToastificationType.error
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      autoCloseDuration: duration,
      type: type,
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
    );
  }

  static void success({
    required final BuildContext context,
    required final String message,
    final Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: ToastificationType.success,
      duration: duration,
    );
  }

  static void error({
    required final BuildContext context,
    required final String message,
    final Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: ToastificationType.error,
      duration: duration,
    );
  }

  static void warning({
    required final BuildContext context,
    required final String message,
    final Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: ToastificationType.warning,
      duration: duration,
    );
  }

  static void info({
    required final BuildContext context,
    required final String message,
    final Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      duration: duration,
    );
  }
}
