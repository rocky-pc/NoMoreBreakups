import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_screen.dart';

import 'features/home/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rtcbdviyzkhxwaxwpzqn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Y2Jkdml5emtoeHdheHdwenFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNTg1NDksImV4cCI6MjEwMjYzNDU0OX0.vObVr4yF48U9XHnBeD2_MEz88UO5Aka4vsgV54C7qk8',
  );

  runApp(
    const ProviderScope(
      child: NoMoreBreakupsApp(),
    ),
  );
}

class NoMoreBreakupsApp extends ConsumerWidget {
  const NoMoreBreakupsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'No More Breakups',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.rose,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: session != null ? const MainScreen() : const LoginScreen(),
    );
  }
}
