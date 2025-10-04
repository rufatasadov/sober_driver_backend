import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/location_service.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
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
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Ayiq Sürücü Customer',
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
        if (state is AuthAuthenticated) {
          // Initialize socket service if authenticated
          if (!SocketService().isConnected) {
            SocketService().initialize(authToken: state.token);
          }
          return const HomeScreen();
        } else {
          return const PhoneInputScreen();
        }
      },
    );
  }
}