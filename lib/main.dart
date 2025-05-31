import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:libyyapp/mainPagesAdmin/AddBookForm.dart';
import 'package:libyyapp/firebase_options.dart';
import 'package:libyyapp/mainPagesAdmin/manageUserAccounts.dart';
import 'package:libyyapp/mainPagesReader/FavoriteBooks.dart';
import 'package:libyyapp/mainPagesReader/HomePage.dart';
import 'package:libyyapp/auth/LoginPage.dart';
import 'package:libyyapp/auth/SignUpPage.dart';
import 'package:libyyapp/WelcomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libyyapp/mainPagesAdmin/HomePageAdmin.dart';
import 'package:libyyapp/mainPagesReader/ReservationHistory.dart';
import 'package:libyyapp/mainPagesReader/borowingHistory.dart';
import 'package:libyyapp/mainPagesReader/libraryCard.dart';
import 'package:libyyapp/notification_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


final navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // local notifications
  await initNotifications(); 
  // Firebase Cloud Messaging
  await setupFCM(); 
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('============User is currently signed out!');
      } else {
        print('============User is signed in!');
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
        scaffoldBackgroundColor: Colors.white, 
        fontFamily: 'Zain',
      ),
      navigatorKey: navigatorKey,
      routes: {
        "signUp": (context) => SignUpPage(),
        "Login": (context) => LoginPage(),
        "Home": (context) => HomePage(),
        "HomeAdmin": (context) => Homepageadmin(),
        "AddBookForm": (context) => Addbookform(),
        'ReservationHistory' : (context)=>ReservationHistoryScreen(),
        "BorrowingHistory": (context) => BorrowHistoryScreen(),
        '/notification_screen': (context) => NotificationsScreen(),
        'LibraryCard': (context) => UserProfileCard(),
        'manageUserAccounts' : (context) => ManageUserAccounts(),
        'FavoriteBooks' : (context)=> FavoritesScreen()
        
      },
      home: WelcomePage(),
    );
  }
}


Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      navigatorKey.currentState?.pushNamed('/notification_screen');
    },
  );

  
  await createNotificationChannel();
}


// notification channel for android
Future<void> createNotificationChannel() async {
  // channel for available books
  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'available_book_notifications_channel',
    'available Book Notifications',
    importance: Importance.high,
  );

  // channel for new books
  const AndroidNotificationChannel newBooksChannel = AndroidNotificationChannel(
    'new_books_channel',
    'New Books Notifications',
    importance: Importance.high,
    description: 'This channel is used for new books notifications.',
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(defaultChannel);
  await androidPlugin?.createNotificationChannel(newBooksChannel);
}



Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'available_book_notifications_channel',
    'available Book Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // notification id
    title, // notification title
    body, // notification content
    platformDetails,
  );
}

// Firebase Cloud Messaging (FCM)
Future<void> setupFCM() async {
  // listening for messages received
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Message received: ${message.notification?.title}");
    showNotification(message.notification?.title ?? '', message.notification?.body ?? '');
  });

  // التحقق من الإشعارات عندما يفتح المستخدم التطبيق من الإشعار
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Message clicked!");
  });

  // التحقق من الإشعارات عندما يكون التطبيق في حالة مغلقة
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print("App opened from terminated state with message: ${message.notification?.title}");
    }
  });
}


Future<void> getFCMToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
}