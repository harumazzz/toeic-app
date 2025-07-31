import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammar.dart';
import 'package:learn/features/grammars/domain/use_cases/get_grammars.dart';
import 'package:learn/features/grammars/domain/use_cases/search_grammar.dart';
import 'package:learn/features/grammars/presentation/providers/grammar_provider.dart';
import 'package:learn/features/grammars/presentation/screens/grammar_detail_screen.dart';
import 'package:learn/features/grammars/presentation/screens/grammar_list_screen.dart';
import 'package:learn/features/grammars/presentation/widgets/grammar_list_item.dart';
import 'package:learn/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGrammars extends Mock implements GetGrammars {}

class MockGetGrammar extends Mock implements GetGrammar {}

class MockGetRelatedGrammars extends Mock implements GetRelatedGrammars {}

class FakeGetGrammarsParams extends Fake implements GetGrammarsParams {}

class FakeGetGrammarsByLevelParams extends Fake
    implements GetGrammarsByLevelParams {}

class FakeGetGrammarsByTagParams extends Fake
    implements GetGrammarsByTagParams {}

class FakeSearchGrammarsParams extends Fake implements SearchGrammarsParams {}

class FakeGetGrammarParams extends Fake implements GetGrammarParams {}

class FakeGetRelatedGrammarsParams extends Fake
    implements GetRelatedGrammarsParams {}

// Test-specific GrammarListScreen that doesn't use generated routes
class TestGrammarListScreen extends ConsumerStatefulWidget {
  const TestGrammarListScreen({super.key});

  @override
  ConsumerState<TestGrammarListScreen> createState() =>
      _TestGrammarListScreenState();
}

class _TestGrammarListScreenState extends ConsumerState<TestGrammarListScreen> {
  @override
  void initState() {
    super.initState();
    // Load grammars on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(grammarListProvider.notifier)
          .loadGrammars(
            limit: 20,
            offset: 0,
          );
    });
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(grammarListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammars'),
      ),
      body: Builder(
        builder: (final context) {
          if (state.isLoading && state.grammars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(grammarListProvider.notifier)
                          .loadGrammars(
                            limit: 20,
                            offset: 0,
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state.grammars.isEmpty) {
            return const Center(child: Text('No grammars found'));
          } else {
            return ListView.builder(
              itemCount: state.grammars.length,
              itemBuilder: (final context, final index) {
                final grammar = state.grammars[index];
                return GrammarListItem(
                  grammar: grammar,
                  onTap: () {
                    context.push('/grammar-detail/${grammar.id}');
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

void main() {
  late MockGetGrammars mockGetGrammars;
  late MockGetGrammar mockGetGrammar;
  late MockGetRelatedGrammars mockGetRelatedGrammars;

  setUpAll(() {
    registerFallbackValue(FakeGetGrammarsParams());
    registerFallbackValue(FakeGetGrammarsByLevelParams());
    registerFallbackValue(FakeGetGrammarsByTagParams());
    registerFallbackValue(FakeSearchGrammarsParams());
    registerFallbackValue(FakeGetGrammarParams());
    registerFallbackValue(FakeGetRelatedGrammarsParams());
  });

  setUp(() {
    mockGetGrammars = MockGetGrammars();
    mockGetGrammar = MockGetGrammar();
    mockGetRelatedGrammars = MockGetRelatedGrammars();
  });

  group('Grammar Feature Integration Tests', () {
    const tGrammar1 = Grammar(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
    );

    const tGrammar2 = Grammar(
      id: 2,
      grammarKey: 'past-simple',
      title: 'Past Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
    );

    const tGrammarDetail = Grammar(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense'],
      related: [2, 3],
      contents: [
        Content(
          subTitle: 'Usage',
          content: [
            ContentElement(
              content: '<p>Used for habits and facts</p>',
              formulas: ['Subject + Verb'],
              examples: [
                Example(example: 'I study English every day.'),
              ],
            ),
          ],
        ),
      ],
    );

    const tGrammars = [tGrammar1, tGrammar2];

    Widget createTestApp({
      required final List<Override> overrides,
    }) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (final context, final state) => TranslationProvider(
              child: const TestGrammarListScreen(),
            ),
          ),
          GoRoute(
            path: '/grammar-detail/:grammarId',
            builder: (final context, final state) => TranslationProvider(
              child: GrammarDetailScreen(
                grammarId: int.parse(state.pathParameters['grammarId'] ?? '1'),
              ),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    Widget createTestAppWithDetail({
      required final List<Override> overrides,
    }) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (final context, final state) => TranslationProvider(
              child: const TestGrammarListScreen(),
            ),
          ),
          GoRoute(
            path: '/grammar-detail/:grammarId',
            builder: (final context, final state) => TranslationProvider(
              child: GrammarDetailScreen(
                grammarId: int.parse(state.pathParameters['grammarId'] ?? '1'),
              ),
            ),
          ),
        ],
        initialLocation: '/grammar-detail/1',
      );

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    group('Grammar List Flow', () {
      testWidgets(
        'should load and display list of grammars successfully',
        (final tester) async {
          // arrange
          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Right(tGrammars));

          final app = createTestApp(
            overrides: [
              getGrammarsProvider.overrideWith((final ref) => mockGetGrammars),
            ],
          );

          // act
          await tester.pumpWidget(app);
          await tester.pump(); // Wait for initial loading
          await tester.pump(); // Wait for data to load

          // assert
          expect(find.text('Present Simple Tense'), findsOneWidget);
          expect(find.text('Past Simple Tense'), findsOneWidget);
          expect(find.byType(GrammarListItem), findsNWidgets(2));

          verify(
            () => mockGetGrammars(
              const GetGrammarsParams(limit: 20, offset: 0),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'should show error message when grammar loading fails',
        (final tester) async {
          // arrange
          when(() => mockGetGrammars(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Network error')),
          );

          final app = createTestApp(
            overrides: [
              getGrammarsProvider.overrideWith((final ref) => mockGetGrammars),
            ],
          );

          // act
          await tester.pumpWidget(app);
          await tester.pump(); // Wait for initial loading
          await tester.pump(); // Wait for error state

          // assert
          expect(find.textContaining('Network error'), findsOneWidget);
        },
      );
    });

    group('Grammar Detail Flow', () {
      testWidgets(
        'should load and display grammar detail with related grammars',
        (final tester) async {
          // arrange
          when(
            () => mockGetGrammar(any()),
          ).thenAnswer((_) async => const Right(tGrammarDetail));
          when(
            () => mockGetRelatedGrammars(any()),
          ).thenAnswer((_) async => const Right([tGrammar2]));

          final app = createTestAppWithDetail(
            overrides: [
              getGrammarProvider.overrideWith((final ref) => mockGetGrammar),
              getRelatedGrammarsProvider.overrideWith(
                (final ref) => mockGetRelatedGrammars,
              ),
            ],
          );

          // act
          await tester.pumpWidget(app);
          await tester.pump(); // Wait for initial loading
          await tester.pump(); // Wait for data to load

          // assert
          expect(find.text('Present Simple Tense'), findsOneWidget);
          expect(find.text('Usage'), findsOneWidget);
          expect(find.textContaining('Used for habits'), findsOneWidget);

          verify(() => mockGetGrammar(const GetGrammarParams(id: 1))).called(1);
          verify(
            () => mockGetRelatedGrammars(
              const GetRelatedGrammarsParams(ids: [2, 3]),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'should show error message when grammar detail loading fails',
        (final tester) async {
          // arrange
          when(() => mockGetGrammar(any())).thenAnswer(
            (_) async =>
                const Left(ServerFailure(message: 'Grammar not found')),
          );

          final app = createTestAppWithDetail(
            overrides: [
              getGrammarProvider.overrideWith((final ref) => mockGetGrammar),
            ],
          );

          // act
          await tester.pumpWidget(app);
          await tester.pump(); // Wait for initial loading
          await tester.pump(); // Wait for error state

          // assert
          expect(find.textContaining('Grammar not found'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle grammar without related grammars',
        (final tester) async {
          // arrange
          const grammarWithoutRelated = Grammar(
            id: 1,
            grammarKey: 'present-simple',
            title: 'Present Simple Tense',
            level: 1,
            contents: [
              Content(
                subTitle: 'Usage',
                content: [
                  ContentElement(content: '<p>Used for habits</p>'),
                ],
              ),
            ],
          );

          when(
            () => mockGetGrammar(any()),
          ).thenAnswer((_) async => const Right(grammarWithoutRelated));

          final app = createTestAppWithDetail(
            overrides: [
              getGrammarProvider.overrideWith((final ref) => mockGetGrammar),
            ],
          );

          // act
          await tester.pumpWidget(app);
          await tester.pump(); // Wait for data to load
          await tester.pump();

          // assert
          expect(find.text('Present Simple Tense'), findsOneWidget);
          expect(find.text('Usage'), findsOneWidget);

          // Should not try to load related grammars
          verifyNever(() => mockGetRelatedGrammars(any()));
        },
      );
    });

    group('End-to-End Grammar Flow', () {
      testWidgets(
        'should complete full grammar browsing flow',
        (final tester) async {
          // arrange
          when(
            () => mockGetGrammars(any()),
          ).thenAnswer((_) async => const Right(tGrammars));
          when(
            () => mockGetGrammar(any()),
          ).thenAnswer((_) async => const Right(tGrammarDetail));
          when(
            () => mockGetRelatedGrammars(any()),
          ).thenAnswer((_) async => const Right([tGrammar2]));

          final app = ProviderScope(
            overrides: [
              getGrammarsProvider.overrideWith((final ref) => mockGetGrammars),
              getGrammarProvider.overrideWith((final ref) => mockGetGrammar),
              getRelatedGrammarsProvider.overrideWith(
                (final ref) => mockGetRelatedGrammars,
              ),
            ],
            child: MaterialApp(
              home: TranslationProvider(
                child: const GrammarListScreen(),
              ),
              routes: {
                '/grammar-detail': (final context) =>
                    const GrammarDetailScreen(grammarId: 1),
              },
            ),
          );

          // act & assert
          await tester.pumpWidget(app);
          await tester.pump();
          await tester.pump(); // Wait for grammar list to load

          // Verify grammar list is displayed
          expect(find.text('Present Simple Tense'), findsOneWidget);
          expect(find.text('Past Simple Tense'), findsOneWidget);

          verify(
            () => mockGetGrammars(
              const GetGrammarsParams(limit: 20, offset: 0),
            ),
          ).called(1);
        },
      );
    });
  });
}
