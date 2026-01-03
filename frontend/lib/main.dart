import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('ERROR: Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
    print('Available env vars: ${dotenv.env.keys.toList()}');
    // Run app without Supabase for now
    runApp(const ProviderScope(child: VibeCheckApp(supabaseInitialized: false)));
    return;
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  print('Supabase Initialized');
  
  runApp(const ProviderScope(child: VibeCheckApp(supabaseInitialized: true)));
}

class VibeCheckApp extends StatelessWidget {
  final bool supabaseInitialized;
  
  const VibeCheckApp({super.key, this.supabaseInitialized = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Vibe Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF000000),
          onPrimary: Colors.white,
          secondary: Color(0xFFFF4500), // Reddit Orange
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: supabaseInitialized ? const AuthGate() : const _ConfigErrorScreen(),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 24),
              Text(
                'Configuration Error',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.\n\nAdd these to frontend/.env',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check if user is logged in
        final user = Supabase.instance.client.auth.currentUser;
        
        if (user != null) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

