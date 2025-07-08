import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // Thêm import Material để dùng ví dụ Navigator
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- Background Handler (Giữ nguyên là top-level/static) ---
@pragma('vm:entry-point') // Đảm bảo hoạt động tốt với tree shaking
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Nếu bạn cần khởi tạo Firebase ở đây (ví dụ: cho các tác vụ nền khác)
  // await Firebase.initializeApp(); // Đảm bảo đã gọi ở main() rồi thì thôi
  print('Handling a background message: ${message.messageId}');
  print('Background Message title: ${message.notification?.title}');
  print('Background Message body: ${message.notification?.body}');
  print('Background Message data: ${message.data}');
}

class MessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Định nghĩa kênh Android với tầm quan trọng cao hơn
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // ID kênh
    'High Importance Notifications', // Tên hiển thị cho người dùng
    description: 'Kênh này dùng cho các thông báo quan trọng.', // Mô tả
    importance: Importance.max, // Đặt mức độ quan trọng cao nhất
    playSound: true,
  );

  // Biến để lưu trữ context điều hướng (nếu cần)
  // Có thể dùng GlobalKey<NavigatorState> hoặc các giải pháp quản lý state khác
  // static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // 1. Xin quyền từ Firebase Messaging (xử lý cả iOS và Android >= 13)
    await _requestPermission();

    // 2. Lấy FCM Token
    await _getToken();

    // 3. Khởi tạo Local Notifications
    await _initLocalNotifications();

    // 4. Khởi tạo Push Notifications (FCM Listeners)
    await _initPushNotifications();

    print("MessagingService Initialized");
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
    // Không cần gọi requestPermission của flutter_local_notifications ở đây nữa
  }

  Future<void> _getToken() async {
    final fcmToken = await _firebaseMessaging.getToken();
    _firebaseMessaging.subscribeToTopic("all");
    print("FCM Token: $fcmToken");
    // TODO: Gửi token này lên server của bạn nếu cần
  }

  // --- Khởi tạo Local Notifications ---
  Future<void> _initLocalNotifications() async {
    // Sử dụng DarwinInitializationSettings cho iOS/macOS
    const DarwinInitializationSettings darwinInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Quyền đã được xin bởi FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Callback cũ nếu cần
    );

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@drawable/ic_launcher'); // Thay bằng icon của bạn

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings, // Thêm macOS nếu cần
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Callback khi người dùng nhấn vào thông báo (cả foreground/background)
      // được hiển thị bởi flutter_local_notifications
      onDidReceiveNotificationResponse: _onDidReceiveLocalNotificationResponse,
      // Callback cho các hành động nền (ít dùng với FCM cơ bản)
      // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );

    // Tạo kênh thông báo cho Android 8.0+
    // Chỉ cần thực hiện trên Android
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);
    }
  }

  // --- Xử lý khi nhấn vào Local Notification ---
  void _onDidReceiveLocalNotificationResponse(NotificationResponse response) {
    print('Local Notification Tapped with payload: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Giải mã payload (là message.toMap() đã được jsonEncode)
        final messageMap = jsonDecode(response.payload!);
        // Tạo lại đối tượng RemoteMessage giả lập từ Map nếu cần truy cập sâu
        // Hoặc đơn giản là lấy data từ map
        final messageData = Map<String, dynamic>.from(messageMap['data'] ?? {});
        _handleNotificationTap(messageData, "Local Tap");
      } catch (e) {
        print('Error decoding local notification payload: $e');
      }
    }
  }

  // --- Khởi tạo FCM Listeners ---
  Future<void> _initPushNotifications() async {
    // Cho phép hiển thị thông báo foreground trên iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, // Hiển thị alert
      badge: true, // Cập nhật badge
      sound: true, // Phát âm thanh
    );

    // Xử lý khi app mở từ trạng thái Terminated qua thông báo
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        print("App opened from terminated state via notification");
        _handleNotificationTap(message.data, "Terminated Tap");
      }
    });

    // Xử lý khi app mở từ trạng thái Background qua thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("App opened from background state via notification");
      _handleNotificationTap(message.data, "Background Tap");
    });

    // Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Xử lý khi nhận thông báo lúc app đang ở Foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final messageData = message.data; // Dữ liệu gửi kèm

      print('Foreground Message received:');
      print('  Title: ${notification?.title}');
      print('  Body: ${notification?.body}');
      print('  Data: $messageData');

      // Chỉ hiển thị local notification nếu có phần notification payload
      // và chúng ta đang ở trên Android (iOS tự hiển thị qua setForeground...)
      // Hoặc nếu muốn tùy chỉnh hiển thị trên cả iOS
      if (notification != null) {
        // && Platform.isAndroid){ // Bỏ comment Platform.isAndroid nếu chỉ muốn hiện local notif trên Android
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode, // ID duy nhất cho thông báo
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@drawable/ic_launcher', // Thay icon của bạn
              importance: _androidChannel.importance,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              // Cấu hình thêm cho iOS nếu cần
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          // Quan trọng: Gửi kèm dữ liệu để xử lý khi nhấn vào
          payload: jsonEncode(message.toMap()), // Mã hóa toàn bộ message hoặc chỉ message.data
        );
      }
    });
  }

  // --- Hàm xử lý tập trung cho việc nhấn thông báo ---
  void _handleNotificationTap(Map<String, dynamic> data, String tapContext) {
    print("Handling notification tap ($tapContext)");
    print("Data: $data");

    // Ví dụ: Kiểm tra dữ liệu để điều hướng
    final String? screen = data['screen']; // Lấy giá trị 'screen' từ data
    final String? itemId = data['item_id']; // Lấy giá trị 'item_id'

    if (screen != null) {
      print("Navigating to screen: $screen with item ID: $itemId");
      // TODO: Thực hiện điều hướng dựa trên dữ liệu
      // Ví dụ sử dụng Navigator (cần có context hoặc GlobalKey)
      // if (navigatorKey.currentState != null) {
      //   switch (screen) {
      //     case 'product_details':
      //       navigatorKey.currentState!.push(MaterialPageRoute(
      //         builder: (context) => ProductDetailsScreen(productId: itemId),
      //       ));
      //       break;
      //     case 'orders':
      //        navigatorKey.currentState!.push(MaterialPageRoute(
      //         builder: (context) => OrdersScreen(),
      //       ));
      //       break;
      //     // Thêm các case khác...
      //     default:
      //       print("Unknown screen type: $screen");
      //   }
      // } else {
      //   print("Navigator key is null, cannot navigate.");
      // }
    } else {
      print("No screen specified in notification data.");
      // TODO: Có thể điều hướng đến màn hình mặc định
    }
  }
}
