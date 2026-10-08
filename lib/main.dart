import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/child_main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logo_splash_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  int? _savedUserId;
  String _userRole = 'parent';
  bool _isCheckingSession = true;
  bool _showLogoSplash = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final userId = await SessionService.getSession();
    final role = await SessionService.getRole();
    if (mounted) {
      setState(() {
        _savedUserId = userId;
        _userRole = role;
        _isCheckingSession = false;
        if (userId != null) {
          _showLogoSplash = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        final lightTheme = AppTheme.lightTheme.copyWith(
          textTheme: AppTheme.lightTheme.textTheme.apply(
            fontFamily: 'IBMPlexSansArabic',
          ),
        );

        final darkTheme = AppTheme.darkTheme.copyWith(
          textTheme: AppTheme.darkTheme.textTheme.apply(
            fontFamily: 'IBMPlexSansArabic',
          ),
        );

        return MaterialApp(
          title: 'KidShield',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeProvider.themeMode,
          home: _isCheckingSession
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _savedUserId != null
                  ? _userRole == 'child'
                      ? ChildMainScreen(
                          userId: _savedUserId!,
                          themeProvider: _themeProvider,
                        )
                      : MainScreen(
                          userId: _savedUserId!,
                          themeProvider: _themeProvider,
                        )
                  : _showLogoSplash
                      ? LogoSplashScreen(
                          onDone: () {
                            if (mounted) {
                              setState(() => _showLogoSplash = false);
                            }
                          },
                        )
                      : LoginScreen(themeProvider: _themeProvider),
        );
      },
    );
  }
}
