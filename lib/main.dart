import 'dart:convert';
import 'package:jelajah_nusa/firebase_options.dart';
import 'package:jelajah_nusa/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  const AndroidNotificationDetails android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi JelajahNusa',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
   final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform);
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';

  const BigTextStyleInformation styleInfo = BigTextStyleInformation('');

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'detail_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi Detail JelajahNusa',
    importance: Importance.max,
    priority: Priority.max,
  );

  const NotificationDetails platform = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(1, title, body, platform);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification?.title,
      message.notification?.body,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await requestNotificationPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String topic = "jelajah_nusa";

  @override
  void initState() {
    super.initState();

    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();

    print("FCM Token: $token");

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.subscribeToTopic(topic);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        showNotificationFromData(message.data);
      } else {
        showBasicNotification(
          message.notification?.title,
          message.notification?.body,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'JelajahNusa',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),

        scaffoldBackgroundColor: const Color(0xFFEAF6F6),

        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
