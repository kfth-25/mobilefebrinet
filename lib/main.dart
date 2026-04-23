import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Global NotificationProvider instance so FcmService can access it
final notificationProvider = NotificationProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FcmService.registerBackgroundHandler();
  await NotificationService().init();
  await FcmService().init();
  FcmService().attachNavigator(appNavigatorKey);
  FcmService().attachNotificationProvider(notificationProvider);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Febri.net Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            navigatorKey: appNavigatorKey,
            home: auth.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : (auth.isAuthenticated ? const MainScreen() : const LoginScreen()),
          );
        },
      ),
    );
  }
}
