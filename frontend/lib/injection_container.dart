import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';

final GetIt _getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: false)
FutureOr<GetIt> configureDependencies() => init(_getIt);

class InjectionContainer extends Equatable {
  const InjectionContainer._();

  static T get<T extends Object>() {
    assert(_getIt.isRegistered<T>(), '$T is not registered');
    return _getIt<T>();
  }

  @override
  List<Object?> get props => [];
}
