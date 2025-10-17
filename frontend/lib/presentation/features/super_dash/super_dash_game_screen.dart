import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:authentication_repository/authentication_repository.dart'
    show AuthenticationRepository, User;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart'
    show LeaderboardEntryData, LeaderboardRepository;
import 'package:provider/provider.dart';
import 'package:tickup/presentation/features/super_dash/app_lifecycle/app_lifecycle.dart';
import 'package:tickup/presentation/features/super_dash/audio/audio.dart';
import 'package:tickup/presentation/features/super_dash/game_intro/view/game_intro_page.dart';
import 'package:tickup/presentation/features/super_dash/l10n/l10n.dart';
import 'package:tickup/presentation/features/super_dash/settings/persistence/memory_settings_persistence.dart';
import 'package:tickup/presentation/features/super_dash/settings/settings.dart';
import 'package:tickup/presentation/features/super_dash/share/share.dart';

/// Wraps the Super Dash game inside the Tickup app.
class SuperDashGameScreen extends StatefulWidget {
  const SuperDashGameScreen({super.key});

  @override
  State<SuperDashGameScreen> createState() => _SuperDashGameScreenState();
}

class _SuperDashGameScreenState extends State<SuperDashGameScreen> {
  late final SettingsController _settingsController;
  late final AudioController _audioController;
  late final ShareController _shareController;
  late final AuthenticationRepository _authenticationRepository;
  late final LeaderboardRepository _leaderboardRepository;
  late final Future<void> _initialization;
  bool _lifecycleAttached = false;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(
      persistence: MemoryOnlySettingsPersistence(),
    );
    _audioController = AudioController();
    _shareController = ShareController(
      gameUrl: 'https://github.com/flutter/super_dash',
    );
    _authenticationRepository = _LocalAuthenticationRepository();
    _leaderboardRepository = _InMemoryLeaderboardRepository();
    _initialization = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _settingsController.loadStateFromPersistence();
    _audioController.attachSettings(_settingsController);
    await _audioController.initialize();
    await _authenticationRepository.signInAnonymously();
  }

  @override
  void dispose() {
    _audioController.dispose();
    _authenticationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return AppLifecycleObserver(
          child: Builder(
            builder: (context) {
              final lifecycleNotifier =
                  context.read<ValueNotifier<AppLifecycleState>>();
              if (!_lifecycleAttached) {
                _audioController.attachLifecycleNotifier(lifecycleNotifier);
                _lifecycleAttached = true;
              }

              return MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<AudioController>.value(
                    value: _audioController,
                  ),
                  RepositoryProvider<SettingsController>.value(
                    value: _settingsController,
                  ),
                  RepositoryProvider<ShareController>.value(
                    value: _shareController,
                  ),
                  RepositoryProvider<AuthenticationRepository>.value(
                    value: _authenticationRepository,
                  ),
                  RepositoryProvider<LeaderboardRepository>.value(
                    value: _leaderboardRepository,
                  ),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    textTheme: AppTextStyles.textTheme,
                  ),
                  supportedLocales: SuperDashLocalizations.supportedLocales,
                  localizationsDelegates:
                      SuperDashLocalizations.localizationsDelegates,
                  home: const GameIntroPage(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LocalAuthenticationRepository implements AuthenticationRepository {
  _LocalAuthenticationRepository()
      : _userController = StreamController<User>.broadcast() {
    _userController.add(User.unauthenticated);
  }

  final StreamController<User> _userController;

  @override
  Stream<User> get user => _userController.stream;

  @override
  Stream<String?> get idToken => const Stream.empty();

  @override
  Future<String?> refreshIdToken() async => null;

  @override
  Future<void> signInAnonymously() async {
    _userController.add(const User(id: 'local'));
  }

  @override
  void dispose() {
    _userController.close();
  }
}

class _InMemoryLeaderboardRepository implements LeaderboardRepository {
  final List<LeaderboardEntryData> _entries = [];

  @override
  Future<List<LeaderboardEntryData>> fetchTop10Leaderboard() async {
    return List<LeaderboardEntryData>.unmodifiable(_entries);
  }

  @override
  Future<void> addLeaderboardEntry(LeaderboardEntryData entry) async {
    _entries
      ..add(entry)
      ..sort(
        (a, b) => b.score.compareTo(a.score),
      );
    if (_entries.length > 10) {
      _entries.removeRange(10, _entries.length);
    }
  }
}
