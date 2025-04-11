import 'dart:io';
import 'dart:isolate';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'My_app_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase BEFORE running the app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Text(
          'An error occurred: ${details.exception}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  };
  // ✅ Run SharedPreferences & Heavy Tasks in Background
  await Future.wait([
    _initializeSharedPrefs(),
    _runHeavyTaskInBackground(),
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthStateNotifier(),
      child: MyApp(),
    ),
  );
}

// ✅ Initialize SharedPreferences in Background
Future<void> _initializeSharedPrefs() async {
  await SharedPreferences.getInstance();
  debugPrint("✅ SharedPreferences Initialized");
}

// ✅ Run Heavy Task in Background Isolate
Future<void> _runHeavyTaskInBackground() async {
  ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_heavyWork, receivePort.sendPort);

  receivePort.listen((message) {
    debugPrint("📩 Message from Isolate: $message");
  });
}

// ✅ Heavy Work Function (Runs in Background Thread)
void _heavyWork(SendPort sendPort) {
  for (int i = 1; i <= 5; i++) {
    debugPrint("⚙️ Heavy Task Running... Iteration: $i");
    sleep(const Duration(seconds: 1)); // ✅ Proper delay for isolate
  }
  sendPort.send("✅ Heavy task completed!");
}

// ✅ Save User Session
Future<void> saveUserSession(String userId, String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("user_id", userId);
  await prefs.setString("token", token);
}

// ✅ Check User Session
Future<void> checkUserSession() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString("user_id");
  String? token = prefs.getString("token");

  if (userId != null && token != null) {
    debugPrint("✅ User is logged in: $userId");
  } else {
    debugPrint("🔴 No active session");
  }
}

// ✅ Notification Service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
    DarwinInitializationSettings();
    final InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings, iOS: iosInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
    await _setupNotificationChannel();
  }

  /// ✅ Create Notification Channel
  Future<void> _setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint("✅ Notification Channel Created: ${channel.id}");
  }

  /// ✅ Show Notification
  Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(id, title, body, details);
  }
}

class AuthStateNotifier extends ChangeNotifier {
  String? _role;
  bool _isAuthenticated = false;

  String? get role => _role;
  bool get isAuthenticated => _isAuthenticated;

  AuthStateNotifier() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _role = prefs.getString('role');
    _isAuthenticated = token != null && _role != null;
    notifyListeners();
  }
}
