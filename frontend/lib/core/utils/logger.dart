import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Logger {
  static void debug(String message, {dynamic data}) {
    if (kDebugMode) {
      print('🔍 [DEBUG] $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void info(String message, {dynamic data}) {
    if (kDebugMode) {
      print('ℹ️ [INFO] $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void warning(String message, {dynamic data}) {
    print('⚠️ [WARNING] $message${data != null ? ' | Data: $data' : ''}');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    print('❌ [ERROR] $message');
    if (error != null) print('Error: $error');
    if (stackTrace != null && kDebugMode) print('Stack: $stackTrace');
  }
}

class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    Logger.debug('${provider.name ?? provider.runtimeType} updated',
        data: {'old': previousValue, 'new': newValue});
  }
}
