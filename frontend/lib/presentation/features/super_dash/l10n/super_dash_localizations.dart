import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

const _localizedJson = r'''
{
  "aboutSuperDash": "About Super Dash",
  "betterLuckNextTime": "Better luck next time.",
  "downloadAppLabel": "Download the app",
  "downloadAppMessage": "Fly into Super Dash, avoid the bugs, collect points, and see how far you can go!",
  "enter": "Enter",
  "flutterGames": "Flutter Games",
  "gameInstructionsPageAutoRunDescription": "Welcome to Super Dash. In this game Dash runs automatically.",
  "gameInstructionsPageAutoRunTitle": "Dash Auto-runs",
  "gameInstructionsPageAvoidBugsDescription": "No one likes bugs! Jump to dodge them and avoid taking damage.",
  "gameInstructionsPageAvoidBugsTitle": "Avoid Bugs",
  "gameInstructionsPageCollectEggsAcornsDescription": "Get points by collecting eggs and acorns in the stage.",
  "gameInstructionsPageCollectEggsAcornsTitle": "Collect Eggs & Acorns",
  "gameInstructionsPageLevelGatesDescription": "Advance through gates to face tougher challenges at higher stages.",
  "gameInstructionsPageLevelGatesTitle": "Level Gates",
  "gameInstructionsPagePowerfulWingsDescription": "Collect the golden feather to power up Dash with Flutter. While in midair, tap to do a double jump and see Dash fly!",
  "gameInstructionsPagePowerfulWingsTitle": "Powerful Wings",
  "gameInstructionsPageTapToJumpDescription": "Tap the screen to make Dash jump.",
  "gameInstructionsPageTapToJumpDescriptionDesktop": "Press spacebar to make Dash jump.",
  "gameInstructionsPageTapToJumpTitle": "Tap to Jump",
  "gameIntroPageHeadline": "Fly into Super Dash, avoid the bugs, collect points, and see how far you can go!",
  "gameIntroPagePlayButtonText": "Play",
  "gameOver": "Game over!",
  "gameScoreLabel": "{points} Pts",
  "howItsMade": "How it's made",
  "howWeBuiltSuperDash": "how we built Super Dash",
  "inFlutterAndGrabThe": " in Flutter and grab the ",
  "initialsBlacklistedMessage": "Keep it PG, use different initials",
  "initialsErrorMessage": "Please enter three initials",
  "leaderboardPageGoBackButton": "Go back",
  "leaderboardPageLeaderboardErrorText": "There was an error while fetching the leaderboard.",
  "leaderboardPageLeaderboardHeadline": "Leaderboard",
  "leaderboardPageLeaderboardNoEntries": "No entries",
  "learn": "Learn ",
  "mobileAppsComingSoon": "Mobile Apps Coming Soon",
  "mobileAppsComingSoonDescription": "in the repo and look for the apps available for download in stores soon! Open this link on a desktop web browser to play today.",
  "mobileAppsComingSoonGrabThe": "Grab the ",
  "mobileAppsComingSoonMobileSourceCode": "mobile source code ",
  "openSourceCode": "open source code.",
  "otherLinks": "Other Links",
  "playAgain": "Play again",
  "privacyPolicy": "Privacy Policy",
  "pts": "Pts",
  "scoreSubmissionErrorMessage": "There was an error submitting your score",
  "seeTheRanking": "See the ranking",
  "share": "Share",
  "shareOn": "Share on:",
  "shareYourScore": "Share your Super Dash score and challenge your friends to do more!",
  "submitScore": "Submit score",
  "superDash": "Super Dash",
  "tapToStart": "Tap/press Space to start",
  "termsOfService": "Terms of Service",
  "totalScore": "Total Score"
}
''';

final Map<String, dynamic> _localizedMap =
    UnmodifiableMapView(jsonDecode(_localizedJson) as Map<String, dynamic>);

/// Simplified localization shim for the embedded Super Dash feature.
class SuperDashLocalizations {
  SuperDashLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const LocalizationsDelegate<SuperDashLocalizations> delegate =
      _SuperDashLocalizationsDelegate();

  static SuperDashLocalizations of(BuildContext context) {
    return Localizations.of<SuperDashLocalizations>(
          context,
          SuperDashLocalizations,
        ) ??
        SuperDashLocalizations(Localizations.localeOf(context));
  }

  String _string(String key) => (_localizedMap[key] as String?) ?? key;

  String get aboutSuperDash => _string('aboutSuperDash');
  String get betterLuckNextTime => _string('betterLuckNextTime');
  String get downloadAppLabel => _string('downloadAppLabel');
  String get downloadAppMessage => _string('downloadAppMessage');
  String get enter => _string('enter');
  String get flutterGames => _string('flutterGames');
  String get gameInstructionsPageAutoRunDescription =>
      _string('gameInstructionsPageAutoRunDescription');
  String get gameInstructionsPageAutoRunTitle =>
      _string('gameInstructionsPageAutoRunTitle');
  String get gameInstructionsPageAvoidBugsDescription =>
      _string('gameInstructionsPageAvoidBugsDescription');
  String get gameInstructionsPageAvoidBugsTitle =>
      _string('gameInstructionsPageAvoidBugsTitle');
  String get gameInstructionsPageCollectEggsAcornsDescription =>
      _string('gameInstructionsPageCollectEggsAcornsDescription');
  String get gameInstructionsPageCollectEggsAcornsTitle =>
      _string('gameInstructionsPageCollectEggsAcornsTitle');
  String get gameInstructionsPageLevelGatesDescription =>
      _string('gameInstructionsPageLevelGatesDescription');
  String get gameInstructionsPageLevelGatesTitle =>
      _string('gameInstructionsPageLevelGatesTitle');
  String get gameInstructionsPagePowerfulWingsDescription =>
      _string('gameInstructionsPagePowerfulWingsDescription');
  String get gameInstructionsPagePowerfulWingsTitle =>
      _string('gameInstructionsPagePowerfulWingsTitle');
  String get gameInstructionsPageTapToJumpDescription =>
      _string('gameInstructionsPageTapToJumpDescription');
  String get gameInstructionsPageTapToJumpDescriptionDesktop =>
      _string('gameInstructionsPageTapToJumpDescriptionDesktop');
  String get gameInstructionsPageTapToJumpTitle =>
      _string('gameInstructionsPageTapToJumpTitle');
  String get gameIntroPageHeadline => _string('gameIntroPageHeadline');
  String get gameIntroPagePlayButtonText =>
      _string('gameIntroPagePlayButtonText');
  String get gameOver => _string('gameOver');
  String gameScoreLabel(int points) {
    final formatted = NumberFormat.decimalPattern().format(points);
    return _string('gameScoreLabel').replaceAll('{points}', formatted);
  }

  String get howItsMade => _string('howItsMade');
  String get howWeBuiltSuperDash => _string('howWeBuiltSuperDash');
  String get inFlutterAndGrabThe => _string('inFlutterAndGrabThe');
  String get initialsBlacklistedMessage =>
      _string('initialsBlacklistedMessage');
  String get initialsErrorMessage => _string('initialsErrorMessage');
  String get leaderboardPageGoBackButton =>
      _string('leaderboardPageGoBackButton');
  String get leaderboardPageLeaderboardErrorText =>
      _string('leaderboardPageLeaderboardErrorText');
  String get leaderboardPageLeaderboardHeadline =>
      _string('leaderboardPageLeaderboardHeadline');
  String get leaderboardPageLeaderboardNoEntries =>
      _string('leaderboardPageLeaderboardNoEntries');
  String get learn => _string('learn');
  String get mobileAppsComingSoon => _string('mobileAppsComingSoon');
  String get mobileAppsComingSoonDescription =>
      _string('mobileAppsComingSoonDescription');
  String get mobileAppsComingSoonGrabThe =>
      _string('mobileAppsComingSoonGrabThe');
  String get mobileAppsComingSoonMobileSourceCode =>
      _string('mobileAppsComingSoonMobileSourceCode');
  String get openSourceCode => _string('openSourceCode');
  String get otherLinks => _string('otherLinks');
  String get playAgain => _string('playAgain');
  String get privacyPolicy => _string('privacyPolicy');
  String get pts => _string('pts');
  String get scoreSubmissionErrorMessage =>
      _string('scoreSubmissionErrorMessage');
  String get seeTheRanking => _string('seeTheRanking');
  String get share => _string('share');
  String get shareOn => _string('shareOn');
  String get shareYourScore => _string('shareYourScore');
  String get submitScore => _string('submitScore');
  String get superDash => _string('superDash');
  String get tapToStart => _string('tapToStart');
  String get termsOfService => _string('termsOfService');
  String get totalScore => _string('totalScore');
}

class _SuperDashLocalizationsDelegate
    extends LocalizationsDelegate<SuperDashLocalizations> {
  const _SuperDashLocalizationsDelegate();

  @override
  Future<SuperDashLocalizations> load(Locale locale) async {
    return SuperDashLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) => true;

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<SuperDashLocalizations> old,
  ) =>
      false;
}
