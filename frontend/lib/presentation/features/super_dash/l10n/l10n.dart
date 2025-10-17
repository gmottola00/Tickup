import 'package:flutter/widgets.dart';
import 'package:tickup/presentation/features/super_dash/l10n/super_dash_localizations.dart';

export 'package:tickup/presentation/features/super_dash/l10n/super_dash_localizations.dart';

extension AppLocalizationsX on BuildContext {
  SuperDashLocalizations get l10n => SuperDashLocalizations.of(this);
}
