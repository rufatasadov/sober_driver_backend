import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/location_service.dart';
import 'core/localization/language_provider.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/driver_deactivated_screen.dart';
import 'features/intro/presentation/screens/intro_screen.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/orders/presentation/cubit/orders_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'shared/widgets/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service
  ApiService().initialize();

  runApp(const AyiqSurucuDriverApp());
}

class AyiqSurucuDriverApp extends StatelessWidget {
  const AyiqSurucuDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => DashboardCubit()),
        BlocProvider(create: (context) => ProfileCubit()),
        BlocProvider(create: (context) => OrdersCubit()),
        BlocProvider(create: (context) => NotificationsCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Peregon hayda Driver',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize language provider
      final languageProvider = context.read<LanguageProvider>();
      await languageProvider.loadLanguage();

      // Request location permissions first
      final locationService = LocationService();
      await locationService.checkAndRequestPermissions();

      // Check if user is already logged in
      final authCubit = context.read<AuthCubit>();
      await authCubit.checkAuthStatus();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('App initialization error: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const LoadingScreen();
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return FutureBuilder<bool>(
          future: _checkIntroCompleted(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            final introCompleted = snapshot.data ?? true;

            // Show intro screen first if not completed
            if (!introCompleted) {
              return const IntroScreen();
            }

            // Then check auth state
            if (state is AuthAuthenticated) {
              // Initialize socket service if authenticated
              if (!SocketService().isConnected) {
                SocketService().initialize(authToken: state.token);
              }
              return const DashboardScreen();
            } else if (state is AuthDriverDeactivated) {
              return const DriverDeactivatedScreen();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _checkIntroCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('intro_completed') ?? false;
    } catch (e) {
      return false;
    }
  }
}
