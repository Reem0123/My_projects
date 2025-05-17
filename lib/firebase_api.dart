import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:libyyapp/main.dart';
import 'package:flutter/material.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  static List<RemoteMessage> receivedNotifications = [];

  final _firestore = FirebaseFirestore.instance;

 
  Future<void> saveNotificationToFirestore(RemoteMessage message) async {
  
  try {
    final Map<String, dynamic>? data = message.data;
    final String? type = data?['type'] ?? 'default';
    final String? bookId = data?['bookId'];
    final String? userId = data?['userId'] ?? 'all_users'; 

    Map<String, dynamic> notificationData = {
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'userId': userId,
      'bookId': bookId,
      'isRead': false,
    };


    if (bookId != null && bookId.isNotEmpty) {
      final bookSnapshot = await _firestore.collection('Books').doc(bookId).get();
      if (bookSnapshot.exists) {
        notificationData['bookData'] = bookSnapshot.data();
      }
    }

    if (userId != null && userId != 'all_users') {
      final userSnapshot = await _firestore.collection('Users').doc(userId).get();
      if (userSnapshot.exists) {
        notificationData['userData'] = userSnapshot.data();
      }
    }

    await _firestore.collection('notifications').add(notificationData);
   
  } catch (e) {
    print(' error saving notification : $e');
  }
}
  
  Future<void> initNotifications() async {
    await _requestPermission();
    await _initLocalNotifications();
    final fcmToken = await _firebaseMessaging.getToken();
    print(" FCM Token: $fcmToken");
    _initPushNotificationListeners();
  }

 
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    print(" Notification permission status: ${settings.authorizationStatus}");
  }

  
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        navigatorKey.currentState?.pushNamed('/notification_screen');
      },
    );
  }

  
 void _initPushNotificationListeners() {
  FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(" إشعار وارد من FCM في foreground...");
    receivedNotifications.add(message);
    saveNotificationToFirestore(message);

    final type = message.data['type'];
    switch (type) {
      case 'new_book':
        _showNewBookNotification(message);
        break;
      case 'book_available':
        _showBookAvailableNotification(message);
        break;
      case 'reservation_expired':
        _showReservationExpiredNotification(message);
        break;
      case 'book_receiving_expired':
        _showBookReceivingExpiredNotification(message);
        break;
        case 'return_reminder':
        _showReturnReminderNotification(message);
        break;
        case 'return_expired':
  _showReturnExpiredNotification(message);
  break;
    }
  });
}

void _showReturnExpiredNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'return_expired_channel',
          'Return Expired Notifications',
          channelDescription: 'This channel is used for return expired notifications.',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.red,
          enableVibration: true,
          playSound: true,
          timeoutAfter: 3600000, 
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

void _showReturnReminderNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'return_reminder_channel',
          'Return Reminder Notifications',
          channelDescription: 'This channel is used for return reminder notifications.',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.blue,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

void _showBookReceivingExpiredNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'book_expiry_channel',
          'Book Expiry Notifications',
          channelDescription: 'This channel is used for book receiving expiry notifications.',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.red,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        ),
      ),
    );
  }
}


void _showReservationExpiredNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reservation_channel',
          'Reservation Notifications',
          channelDescription: 'This channel is used for end reservation peroid notifications.',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.orange,
        ),
      ),
    );
  }
}

  

  void _showNewBookNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'new_books_channel',
            'New Books Notifications',
            channelDescription: 'This channel is used for new books notifications.',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.green,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ),
      );
    }
  }

  void _showBookAvailableNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'available_book_notifications_channel',
            'available Book Notifications',
            channelDescription: 'This channel is used for available books notifications.',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    receivedNotifications.add(message);
    saveNotificationToFirestore(message);
    navigatorKey.currentState?.pushNamed('/notification_screen', arguments: message);
  }

  
  Future<void> sendBookAvailableNotification({
  required String userToken,
  required String bookId,
  required String userId,
}) async {
  try {
    
    final bookSnapshot = await _firestore.collection('Books').doc(bookId).get();
    if (!bookSnapshot.exists) {
      throw Exception('الكتاب غير موجود');
    }
    
    final bookTitle = bookSnapshot['BookTitle'] ?? 'كتاب';
    

   
    const notificationTitle = ' الكتاب متاح الآن!';
    final notificationBody = 'الكتاب "$bookTitle" أصبح متاح الان .يمكنك استعارته ولكن لديك مهلة للاستجابة لا تتجاوز 24 ساعة.';

   
    await sendPushNotification(
      token: userToken,
      title: notificationTitle,
      body: notificationBody,
      type: 'book_available',
      bookId: bookId,
      userId: userId,
    );

   
    await _firestore.collection('notifications').add({
      'title': notificationTitle,
      'body': notificationBody,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle, 
      'type': 'book_available',
      'timestamp': FieldValue.serverTimestamp(),
       'isRead': false,
    });

    print(' done sending notification and saving it for : $userId');

  } catch (e) {
    print('error sending/saving notification : $e');
    rethrow;
  }
}


Future<void> sendReservationExpiredNotification({
  required String userToken,
  required String userId,
  required String bookId,
  required String bookTitle,
}) async {
  try {
   
    const notificationTitle = ' انتهت مهلة الحجز!';
    final notificationBody = 'لقد انتهت مهلة 24 ساعة لحجز الكتاب "$bookTitle". يمكنك الانضمام لقائمة الانتظار مرة أخرى إذا رغبت.';

   
    await sendPushNotification(
      token: userToken,
      title: notificationTitle,
      body: notificationBody,
      type: 'reservation_expired',
      bookId: bookId,
      userId: userId,
    );

    
    await _firestore.collection('notifications').add({
      'title': notificationTitle,
      'body': notificationBody,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'type': 'reservation_expired',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    print(' done sending notification for: $userId');

  } catch (e) {
    print('error sending notification : $e');
    rethrow;
  }
}

  
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    required String type,
    String? bookId,
    String? userId,
  }) async {
    const serverUrl = 'http://192.168.1.6:3000/send-single';

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': {
            'type': type,
            'bookId': bookId ?? '',
            'userId': userId ?? '',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل الإرسال: ${response.body}');
      }
      print(' تم إرسال إشعار من نوع [$type] بنجاح');
    } catch (e) {
      print(' خطأ في إرسال الإشعار: $e');
      rethrow;
    }
  }


Future<void> sendReturnReminderNotification({
  required String userToken,
  required String userId,
  required String bookId,
  required String bookTitle,
}) async {
  try {
    
    const notificationTitle = ' موعد إرجاع الكتاب يقترب!';
    final notificationBody = 'تبقى يومين فقط على موعد إرجاع كتاب "$bookTitle". يرجى إعادته في الوقت المحدد لتجنب أي تأخير.';

   
    await sendPushNotification(
      token: userToken,
      title: notificationTitle,
      body: notificationBody,
      type: 'return_reminder',
      bookId: bookId,
      userId: userId,
    );

  
    await _firestore.collection('notifications').add({
      'title': notificationTitle,
      'body': notificationBody,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'type': 'return_reminder',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    print(' تم إرسال إشعار تذكير بالإرجاع للمستخدم: $userId');

  } catch (e) {
    print(' فشل في إرسال إشعار تذكير بالإرجاع: $e');
    rethrow;
  }
}

 
Future<void> sendBookReceivingExpiredNotification({
  required String userToken,
  required String userId,
  required String bookId,
  required String bookTitle,
}) async {
  try {
  
    const notificationTitle = ' انتهت مهلة استلام الكتاب!';
    final notificationBody = 'لقد انتهت المهلة المحددة (24 ساعة) لاستلام كتاب "$bookTitle". تم إلغاء حجزك وسيتم عرض الكتاب للمستخدمين الآخرين.';

    
    await sendPushNotification(
      token: userToken,
      title: notificationTitle,
      body: notificationBody,
      type: 'book_receiving_expired',
      bookId: bookId,
      userId: userId,
    );

    
    await _firestore.collection('notifications').add({
      'title': notificationTitle,
      'body': notificationBody,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'type': 'book_receiving_expired',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      
    });

    print(' تم إرسال إشعار انتهاء مهلة استلام الكتاب للمستخدم: $userId');

  } catch (e) {
    print(' فشل في إرسال إشعار انتهاء مهلة استلام الكتاب: $e');
    rethrow;
  }
}

 
 Future<void> sendNewBookNotification({
  required String bookId,
  required String bookTitle,
  required String author,
  required String category,
}) async {
  try {
    
    final users = await _firestore.collection('Users').get();
    
   
    const title = ' كتاب جديد في المكتبة!';
    final body = 'تمت إضافة "$bookTitle" للكاتب $author ';

   
    await _sendMulticastNotification(
      tokens: users.docs
          .map((doc) => doc['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList(),
      title: title,
      body: body,
      type: 'new_book',
      bookId: bookId,
    );

   
    final batch = _firestore.batch();
    
    for (var userDoc in users.docs) {
      final userId = userDoc.id;
      
      final notificationRef = _firestore.collection('notifications').doc();
      
      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'author': author,
        'category': category,
        'type': 'new_book',
        'userId': userId, 
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    
    await batch.commit();
    print(' تم إرسال الإشعارات وحفظها لكل مستخدم بنجاح');

  } catch (e) {
    print(' فشل إرسال إشعارات الكتاب الجديد: $e');
    rethrow;
  }
}

Future<void> sendNewNewsNotification({
  required String newsTitle,
  required String newsContent,
}) async {
  try {
    
    final users = await _firestore.collection('Users').get();
    
   
    const title = ' خبر جديد في المكتبة!';
    final body = newsTitle.length > 30 
        ? '${newsTitle.substring(0, 30)}...' 
        : newsTitle;

   
    await _sendMulticastNotification(
      tokens: users.docs
          .map((doc) => doc['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList(),
      title: title,
      body: body,
      type: 'new_news',
      bookId: '', 
    );

   
    final batch = _firestore.batch();
    
    for (var userDoc in users.docs) {
      final userId = userDoc.id;
      
      final notificationRef = _firestore.collection('notifications').doc();
      
      batch.set(notificationRef, {
        'title': title,
        'body': body,
        'newsTitle': newsTitle,
        'newsContent': newsContent,
        'type': 'new_news',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    
    await batch.commit();
    print(' تم إرسال إشعارات الخبر الجديد لكل مستخدم بنجاح');

  } catch (e) {
    print(' فشل إرسال إشعارات الخبر الجديد: $e');
    rethrow;
  }
}

Future<void> sendReturnExpiredNotification({
  required String userToken,
  required String userId,
  required String bookId,
  required String bookTitle,
}) async {
  try {
    
    const notificationTitle = ' انتهت مدة الإرجاع!';
    final notificationBody = 'لقد انتهت مدة استعارة كتاب "$bookTitle". يرجى إعادته فوراً لتجنب العقوبات.';

   
    await sendPushNotification(
      token: userToken,
      title: notificationTitle,
      body: notificationBody,
      type: 'return_expired',
      bookId: bookId,
      userId: userId,
    );

    
    await _firestore.collection('notifications').add({
      'title': notificationTitle,
      'body': notificationBody,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'type': 'return_expired',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    print(' تم إرسال إشعار انتهاء مدة الإرجاع للمستخدم: $userId');

  } catch (e) {
    print(' فشل في إرسال إشعار انتهاء مدة الإرجاع: $e');
    rethrow;
  }
}


 
  Future<void> _sendMulticastNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required String type,
    String bookId = '',
  }) async {
    const serverUrl = 'http://192.168.1.6:3000/send-multicast';

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': {
            'type': type,
            'bookId': bookId,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل الإرسال الجماعي: ${response.body}');
      }
      print(' تم إرسال إشعار جماعي لـ ${tokens.length} مستخدم');
    } catch (e) {
      print(' خطأ في الإرسال الجماعي: $e');
      rethrow;
    }
  }
}