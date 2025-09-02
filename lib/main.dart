import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthenticationScreen/AuthWrapper.dart';
import 'services/theme_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('Supabase initialized successfully');
  } catch (e) {
    print('Failed to initialize Supabase: $e');
    // Continue without Supabase - app will work in offline mode
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Yuvak Mandal Loan System',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Popins',
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: AuthWrapper(),
        );
      },
    );
  }
}

// Removed old MyHomePage class as it's not needed for the Mandal app
