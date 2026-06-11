import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/api_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load dynamic testing URL if previously configured in settings
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('api_base_url');
  if (savedUrl != null && savedUrl.isNotEmpty) {
    ApiConstants.baseUrl = savedUrl;
  }

  runApp(const MacacinoApp());
}

class MacacinoApp extends StatelessWidget {
  const MacacinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DocumentProvider>(
          create: (context) => DocumentProvider(
            Provider.of<AuthProvider>(context, listen: false).apiService,
          ),
          update: (context, auth, previous) =>
              DocumentProvider(auth.apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Macacino',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F5EF),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFB45309),
            secondary: Color(0xFFB45309),
            surface: Colors.white,
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
          textTheme: ThemeData.light().textTheme.apply(
            fontFamily: 'Outfit',
            bodyColor: const Color(0xFF0F172A),
            displayColor: const Color(0xFF0F172A),
          ),
        ),
        home: const AuthRouteShell(),
      ),
    );
  }
}

class AuthRouteShell extends StatelessWidget {
  const AuthRouteShell({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Switch between Auth Screen and Library main shell depending on login state
    if (authProvider.isAuthenticated) {
      return const MainShell();
    } else {
      return const AuthScreen();
    }
  }
}
