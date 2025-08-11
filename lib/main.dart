import 'package:areg_app/services/auth_state_notifier.dart';
import 'package:areg_app/services/init_services.dart';
import 'package:areg_app/theme/ThemeNotifier.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'My_app_route.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(child: Text('An error occurred: ${details.exception}')),
    );
  };

  await initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: MyApp(),
    ),
  );
}
