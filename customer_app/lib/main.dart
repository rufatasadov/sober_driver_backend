import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/orders/presentation/cubit/orders_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/auth/presentation/screens/intro_screen.dart';
import 'features/auth/presentation/screens/phone_input_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'shared/widgets/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service
  ApiService().initialize();

  runApp(const AyiqSurucuCustomerApp());
}

class AyiqSurucuCustomerApp extends StatelessWidget {
  const AyiqSurucuCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => OrdersCubit()),
      ],
      child: BlocProvider(
        create: (context) =>
            HomeCubit(ordersCubit: context.read<OrdersCubit>()),
        child: ScreenUtilInit(
          designSize: const Size(375, 812), // iPhone X design size
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'Peregon hayda Customer',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const AppInitializer(),
            );
          },
        ),
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
  bool _hasSeenIntro = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request location permissions first
      final locationService = LocationService();
      await locationService.checkAndRequestPermissions();

      // Load intro flag
      final prefs = await SharedPreferences.getInstance();
      _hasSeenIntro = prefs.getBool('intro_seen') ?? false;

      // Check if user is already logged in
      final authCubit = context.read<AuthCubit>();
      await authCubit.checkAuthStatus();

      // DEV: If unauthenticated, skip OTP and authenticate directly
      if (authCubit.state is AuthUnauthenticated) {
        await authCubit.skipToAuthenticated();
      }

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
        if (state is AuthAuthenticated) {
          // Initialize socket service if authenticated
          if (!SocketService().isConnected) {
            SocketService().initialize(authToken: state.token);
          }
          return const HomeScreen();
        } else {
          // Show intro only once; then go to phone input
          if (_hasSeenIntro) {
            return const PhoneInputScreen();
          }
          return const IntroScreen();
        }
      },
    );
  }
}
