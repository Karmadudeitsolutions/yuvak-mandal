import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'services/supabase_auth_service.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({Key? key}) : super(key: key);

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  String _connectionStatus = 'Testing connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _connectionStatus = 'Initializing Supabase...';
      });

      // Test basic connection
      final client = SupabaseService.client;
      
      setState(() {
        _connectionStatus = 'Testing database connection...';
      });

      // Try to fetch from a simple table (this might fail if tables don't exist yet)
      try {
        await client.from('users').select('count').count();
        setState(() {
          _connectionStatus = 'Connection successful! Database is ready.';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _connectionStatus = 'Connection established, but database tables may not exist yet.\n'
              'Please run the SQL schema in your Supabase dashboard.\n'
              'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Testing...'),
                        ],
                      )
                    else
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          color: _connectionStatus.contains('successful') 
                              ? Colors.green 
                              : _connectionStatus.contains('failed')
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('URL: https://lgmeeingeisketzfutyy.supabase.co'),
                    const SizedBox(height: 4),
                    Text(
                      'Key: ' +
                          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnbWVlaW5nZWlza2V0emZ1dHl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1MjczNjksImV4cCI6MjA3MjEwMzM2OX0.29FEdMXdL4pOsns_4-XkIb56qQNnyZc12QLmS20wOS0'
                              .substring(0, 20) +
                          '...',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Go to your Supabase dashboard'),
                    const Text('2. Navigate to SQL Editor'),
                    const Text('3. Run the schema from database/supabase_schema.sql'),
                    const Text('4. Enable Row Level Security'),
                    const Text('5. Test authentication and data operations'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testConnection,
                child: const Text('Retry Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}