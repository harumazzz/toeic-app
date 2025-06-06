import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../i18n/strings.g.dart';
import '../widgets/help_widgets.dart';

class HelpScreen extends HookWidget {
  const HelpScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final appVersion = useState('');

    useEffect(() {
      PackageInfo.fromPlatform().then((final packageInfo) {
        appVersion.value =
            '${packageInfo.version} (${packageInfo.buildNumber})';
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.page.help),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HelpHeader(
                title: context.t.help.title,
                description: context.t.help.description,
              ),
              HelpCategorySection(
                title: context.t.help.categories.gettingStarted,
                icon: Symbols.start,
                items: [
                  HelpExpandableItem(
                    title: context.t.help.gettingStarted.createAccount,
                    content: context.t.help.gettingStarted.createAccountContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.gettingStarted.navigation,
                    content: context.t.help.gettingStarted.navigationContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.gettingStarted.trackProgress,
                    content: context.t.help.gettingStarted.trackProgressContent,
                  ),
                ],
              ),

              // Study Features
              HelpCategorySection(
                title: context.t.help.categories.studyFeatures,
                icon: Symbols.school,
                items: [
                  HelpExpandableItem(
                    title: context.t.help.studyFeatures.vocabulary,
                    content: context.t.help.studyFeatures.vocabularyContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.studyFeatures.listening,
                    content: context.t.help.studyFeatures.listeningContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.studyFeatures.grammar,
                    content: context.t.help.studyFeatures.grammarContent,
                  ),
                ],
              ),

              // Test Preparation
              HelpCategorySection(
                title: context.t.help.categories.testPreparation,
                icon: Symbols.quiz,
                items: [
                  HelpExpandableItem(
                    title: context.t.help.testPreparation.practice,
                    content: context.t.help.testPreparation.practiceContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.testPreparation.strategies,
                    content: context.t.help.testPreparation.strategiesContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.testPreparation.scoring,
                    content: context.t.help.testPreparation.scoringContent,
                  ),
                ],
              ),

              // Account Settings
              HelpCategorySection(
                title: context.t.help.categories.accountSettings,
                icon: Symbols.settings,
                items: [
                  HelpExpandableItem(
                    title: context.t.help.accountSettings.changePassword,
                    content:
                        context.t.help.accountSettings.changePasswordContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.accountSettings.updateProfile,
                    content:
                        context.t.help.accountSettings.updateProfileContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.accountSettings.notifications,
                    content:
                        context.t.help.accountSettings.notificationsContent,
                  ),
                ],
              ),

              // Troubleshooting
              HelpCategorySection(
                title: context.t.help.categories.troubleshooting,
                icon: Symbols.troubleshoot,
                items: [
                  HelpExpandableItem(
                    title: context.t.help.troubleshooting.loginIssues,
                    content: context.t.help.troubleshooting.loginIssuesContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.troubleshooting.contentLoading,
                    content:
                        context.t.help.troubleshooting.contentLoadingContent,
                  ),
                  HelpExpandableItem(
                    title: context.t.help.troubleshooting.appPerformance,
                    content:
                        context.t.help.troubleshooting.appPerformanceContent,
                  ),
                ],
              ),
              const ContactSupportCard(),
              VersionInfo(version: appVersion.value),
            ],
          ),
        ),
      ),
    );
  }
}
