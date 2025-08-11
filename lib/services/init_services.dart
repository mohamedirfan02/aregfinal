import 'dart:isolate';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';


Future<void> initializeApp() async {
  await Future.wait([
    SharedPreferences.getInstance(),
    _runHeavyTaskInBackground(),
    NotificationService().init(),
  ]);
}

Future<void> _runHeavyTaskInBackground() async {
  ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_heavyWork, receivePort.sendPort);

  receivePort.listen((message) {
    debugPrint("📩 Message from Isolate: $message");
  });
}

void _heavyWork(SendPort sendPort) {
  for (int i = 1; i <= 5; i++) {
    debugPrint("⚙️ Heavy Task Running... Iteration: $i");
    sleep(const Duration(seconds: 1));
  }
  sendPort.send("✅ Heavy task completed!");
}
