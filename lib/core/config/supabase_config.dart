class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ohyvoygeclizvcmivcsv.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oeXZveWdlY2xpenZjbWl2Y3N2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MDMxNTMsImV4cCI6MjA5ODA3OTE1M30.a1Mp1Av2bJpwfFPRJSlG1PHmiCU3JSzRH9yGVkwM6Wc',
  );
}
