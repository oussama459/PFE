import 'package:flutter/material.dart';
import 'home_page.dart'; // Assurez-vous que ce fichier existe
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialiser le plugin de notifications globalement
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour l'initialisation

  // Initialisation des notifications pour Android
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // Settings pour iOS (si besoin)
  const DarwinInitializationSettings iosInitSettings =
  DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

  // Configuration des settings
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings, iOS: iosInitSettings);

  // Initialiser le plugin de notifications
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Lancer l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Promotions en Tunisie',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}