import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_action_buttons.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

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
        child: AuthCard(
          children: [
            AuthHeader(
              title: context.t.page.login,
              subtitle: context.t.subtitle.login,
            ),
            AuthTextField.email(
              controller: emailController,
              focusNode: emailFocusNode,
              labelText: context.t.common.email,
              hintText: context.t.hint.email,
              onSubmitted: (_) async {
                if (emailFocusNode.hasFocus) {
                  emailFocusNode.unfocus();
                }
                passwordFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            AuthTextField.password(
              controller: passwordController,
              focusNode: passwordFocusNode,
              labelText: context.t.common.password,
              hintText: context.t.hint.password,
              onSubmitted: (_) async {
                if (passwordFocusNode.hasFocus) {
                  passwordFocusNode.unfocus();
                }
              },
            ),
            const SizedBox(height: 16),
            Consumer(
              builder:
                  (
                    final context,
                    final ref,
                    final child,
                  ) => AuthActionButtons(
                    primaryButtonText: context.t.common.login,
                    secondaryButtonText: context.t.common.register,
                    onPrimaryPressed: () async {
                      if (formKey.currentState?.saveAndValidate() ?? false) {
                        final email = emailController.text;
                        final password = passwordController.text;
                        await ref
                            .read(authControllerProvider.notifier)
                            .login(email: email, password: password);
                      }
                    },
                    onSecondaryPressed: () async {
                      const RegisterRoute().go(context);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
