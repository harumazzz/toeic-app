import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register_user.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;

  const factory AuthState.loading() = AuthLoading;

  const factory AuthState.authenticated({
    required final User user,
  }) = AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error({
    required final String message,
  }) = AuthError;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login({
    required final String email,
    required final String password,
  }) async {
    if (state is AuthLoading) {
      return;
    }
    state = const AuthState.loading();

    final loginUser = ref.read(loginUserProvider);
    final result = await loginUser(
      LoginParams(email: email, password: password),
    );

    state = result.fold(
      ifLeft: (final failure) => AuthState.error(message: failure.message),
      ifRight: (final user) => AuthState.authenticated(user: user),
    );
  }

  Future<void> logout() async {
    if (state is AuthLoading) {
      return;
    }
    state = const AuthState.loading();
    final logOut = ref.read(logoutUseCaseProvider);
    await logOut(const NoParams());
    state = const AuthState.unauthenticated();
  }

  Future<void> register({
    required final String email,
    required final String password,
    required final String username,
  }) async {
    if (state is AuthLoading) {
      return;
    }
    state = const AuthState.loading();

    final regisetrUser = ref.read(registerUserProvider);
    final result = await regisetrUser(
      RegisterParams(
        email: email,
        password: password,
        username: username,
      ),
    );

    state = result.fold(
      ifLeft: (final failure) => AuthState.error(message: failure.message),
      ifRight: (final user) => AuthState.authenticated(user: user),
    );
  }

  Future<void> getCurrentUser() async {
    if (state is AuthLoading) {
      return;
    }
    if (state is AuthAuthenticated) {
      return;
    }
    final secureStorage = InjectionContainer.get<SecureStorageService>();
    final isRefreshTokenExpired = await secureStorage.isExpired();
    if (isRefreshTokenExpired) {
      await secureStorage.clearAllTokens();
      state = const AuthState.unauthenticated();
      return;
    }

    state = const AuthState.loading();

    final getUser = ref.read(getUserProvider);
    final result = await getUser(const NoParams());
    state = result.fold(
      ifLeft: (final failure) => AuthState.error(message: failure.message),
      ifRight: (final user) => AuthState.authenticated(user: user),
    );
  }
}
