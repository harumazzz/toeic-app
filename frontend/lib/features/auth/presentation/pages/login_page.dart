import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/auth_provider.dart';

class LoginPage extends HookWidget {
  const LoginPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormBuilderState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final emailFocusNode = useFocusNode();
    final passwordFocusNode = useFocusNode();
    return Scaffold(
      body: FormBuilder(
        key: formKey,
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Text(
                  context.t.page.login,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t.subtitle.login,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FormBuilderTextField(
                    name: 'email',
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: context.t.common.email,
                      hintText: context.t.hint.email,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.email(),
                    ]),
                    focusNode: emailFocusNode,
                    onSubmitted: (_) async {
                      if (emailFocusNode.hasFocus) {
                        emailFocusNode.unfocus();
                      }
                      passwordFocusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FormBuilderTextField(
                    controller: passwordController,
                    name: 'password',
                    decoration: InputDecoration(
                      labelText: context.t.common.password,
                      hintText: context.t.hint.password,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    validator: FormBuilderValidators.required(),
                    focusNode: passwordFocusNode,
                    onSubmitted: (_) async {
                      if (passwordFocusNode.hasFocus) {
                        passwordFocusNode.unfocus();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Consumer(
                      builder: (final context, final ref, final child) {
                        switch (ref.watch(
                          authControllerProvider,
                        )) {
                          case AuthInitial():
                          case AuthUnauthenticated():
                          case AuthError():
                            return FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                              ),
                              onPressed: () async {
                                if (formKey.currentState?.saveAndValidate() ??
                                    false) {
                                  final email = emailController.text;
                                  final password = passwordController.text;
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .login(email: email, password: password);
                                }
                              },
                              child: Text(context.t.common.login),
                            );
                          default:
                            return const CircularProgressIndicator();
                        }
                      },
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      onPressed: () async {
                        const RegisterRoute().go(context);
                      },
                      child: Text(context.t.common.register),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
