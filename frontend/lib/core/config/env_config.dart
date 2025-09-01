class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://augoixjimymsaboihxcx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1Z29peGppbXltc2Fib2loeGN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwNDQ0ODMsImV4cCI6MjA2NDYyMDQ4M30.HtoG0b0Z_yztbiSgS4Zy7sx1gyzc4lp8zeJdadp0VpQ',
  );

  static const bool isDevelopment = String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      ) ==
      'development';

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
