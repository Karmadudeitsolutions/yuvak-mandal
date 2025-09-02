import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static const bool DEBUG_MODE = true;
  
  static SupabaseClient get client => Supabase.instance.client;

  static void _debugLog(String message) {
    if (DEBUG_MODE) {
      print('🔧 [SupabaseService] $message');
    }
  }

  static Future<void> initialize() async {
    try {
      _debugLog('🚀 Initializing Supabase...');
      _debugLog('🌐 URL: ${SupabaseConfig.supabaseUrl}');
      _debugLog('🔑 Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      
      _debugLog('✅ Supabase initialized successfully');
      _debugLog('🔗 Client status: ${client.toString()}');
      
      // Test the connection
      await _testConnection();
      
    } catch (e) {
      _debugLog('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testConnection() async {
    try {
      _debugLog('🧪 Testing database connection...');
      
      // Try a simple query to test connection
      await client
          .from('users')
          .select('count')
          .limit(0);
      
      _debugLog('✅ Database connection test successful');
    } catch (e) {
      _debugLog('⚠️ Database connection test failed (this is normal if tables don\'t exist yet): $e');
    }
  }

  // Database operations
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
  }) async {
    var query = client.from(table).select(select ?? '*');

    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from(table)
        .insert(data)
        .select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    var query = client.from(table).update(data);
    
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }

    final response = await query.select();
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    var query = client.from(table).delete();
    
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }

    await query;
  }

  // Real-time subscriptions
  static RealtimeChannel subscribe(
    String table,
    void Function(PostgresChangePayload) callback,
  ) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: callback,
        )
        .subscribe();
  }
}