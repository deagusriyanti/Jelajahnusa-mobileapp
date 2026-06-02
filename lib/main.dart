import 'package:jelajah_nusa/firebase_options.dart';
import 'package:jelajah_nusa/Screens/splash_screen.dart';
import 'package:jelajah_nusa/theme/theme_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('BACKGROUND MESSAGE MASUK');
  debugPrint('TITLE: ${message.notification?.title}');
  debugPrint('BODY: ${message.notification?.body}');
  debugPrint('DATA: ${message.data}');
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint('Izin notifikasi sementara diberikan');
  } else {
    debugPrint('Izin notifikasi ditolak');
  }
}

Future<void> initializeLocalNotification() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'jelajah_nusa_channel',
    'Jelajah Nusa Notification',
    description: 'Channel notifikasi aplikasi Jelajah Nusa',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> showBasicNotification(String? title, String? body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'jelajah_nusa_channel',
    'Jelajah Nusa Notification',
    channelDescription: 'Channel notifikasi aplikasi Jelajah Nusa',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title ?? 'Jelajah Nusa',
    body ?? 'Ada informasi terbaru',
    notificationDetails,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeLocalNotification();
  await requestNotificationPermission();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String topic = 'jelajah_nusa';

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  Future<void> setupFirebaseMessaging() async {
    final token = await FirebaseMessaging.instance.getToken();

    debugPrint('FCM Token: $token');

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.subscribeToTopic(topic);

    debugPrint('BERHASIL SUBSCRIBE KE TOPIC: $topic');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FOREGROUND MESSAGE MASUK');
      debugPrint('TITLE: ${message.notification?.title}');
      debugPrint('BODY: ${message.notification?.body}');
      debugPrint('DATA: ${message.data}');

      showBasicNotification(
        message.notification?.title ?? message.data['title'],
        message.notification?.body ?? message.data['body'],
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('NOTIFIKASI DIBUKA');
      debugPrint('DATA: ${message.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JelajahNusa',

      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007C89),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF5F6),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007C89),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),

      home: const SplashScreen(),
    );
  }
}
