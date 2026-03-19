import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/connectivity_provider.dart';
import 'providers/stations_provider.dart';
import 'providers/eta_provider.dart';
import 'providers/gps_tracking_provider.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.init();
  await NotificationService.init();
  runApp(const TramAlgerApp());
}

class TramAlgerApp extends StatelessWidget {
  const TramAlgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => StationsProvider()),
        ChangeNotifierProvider(create: (_) => EtaProvider()),
        ChangeNotifierProvider(create: (_) => GpsTrackingProvider()),
      ],
      child: MaterialApp(
        title: 'Tram Alger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
