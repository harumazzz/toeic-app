import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

@TypedGoRoute<AppRoute>(
  path: '/',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<LoginRouteData>(path: 'login'),
    TypedGoRoute<RegisterRouteData>(path: 'register'),
    TypedGoRoute<ForgotPasswordRouteData>(path: 'forgot-password'),
    TypedGoRoute<HomeRouteData>(path: 'home'),
  ],
)
class AppRoute extends GoRouteData {
  const AppRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const HomeRouteData().build(context, state);
}

class LoginRouteData extends GoRouteData {
  const LoginRouteData();

  @override
  Widget build(final BuildContext context, final GoRouterState state) =>
      const Scaffold(body: Center(child: Text('Login Screen')));
}

class RegisterRouteData extends GoRouteData {
  const RegisterRouteData();

  @override
  Widget build(final BuildContext context, final GoRouterState state) =>
      const Scaffold(body: Center(child: Text('Register Screen')));
}

class ForgotPasswordRouteData extends GoRouteData {
  const ForgotPasswordRouteData();

  @override
  Widget build(final BuildContext context, final GoRouterState state) =>
      const Scaffold(body: Center(child: Text('Forgot Password Screen')));
}

class HomeRouteData extends GoRouteData {
  const HomeRouteData();

  @override
  Widget build(final BuildContext context, final GoRouterState state) =>
      Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Home Screen')),
      );
}

final GoRouter router = GoRouter(initialLocation: '/home', routes: $appRoutes);
