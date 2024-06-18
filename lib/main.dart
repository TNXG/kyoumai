import 'package:flutter/material.dart'; // 导入Flutter材料设计包
import 'package:firebase_core/firebase_core.dart'; // 导入Firebase核心包
import 'package:firebase_messaging/firebase_messaging.dart'; // 导入Firebase消息传递包
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 导入Flutter本地通知包
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';

class MessageModel {
  final int id;
  final String title;
  final String body;
  final DateTime time;

  MessageModel(
      {required this.id,
      required this.title,
      required this.body,
      required this.time});

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      time: DateTime.parse(map['time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time.toIso8601String(),
    };
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    _notificationsPlugin.initialize(initializationSettings);

    // 创建通知渠道
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_id', // 与显示通知时使用的ID相同
      'channel_name',
      description: 'channel_description',
      importance: Importance.high,
    );

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void showNotification(RemoteMessage message) {
    const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails('channel_id', 'channel_name',
            importance: Importance.max, priority: Priority.high));

    _notificationsPlugin.show(message.hashCode, message.notification?.title,
        message.notification?.body, notificationDetails);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (Platform.isAndroid) {
    // 使用正则表达式提取数字
    final sdkIntMatch =
        RegExp(r'\d+').firstMatch(Platform.operatingSystemVersion);
    if (sdkIntMatch != null) {
      final sdkInt = int.parse(sdkIntMatch.group(0)!);
      if (sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (status != PermissionStatus.granted) {
          // 处理未授权的情况
        }
      }
    }
  }
  NotificationService.initialize(); // 确保通知服务初始化
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late FirebaseMessaging messaging;
  String fcmToken = '';
  List<MessageModel> _messages = [];
  bool isFcmAvailable = false;

  Future<void> _saveMessage(String title, String body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    MessageModel newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      time: DateTime.now(),
    );

    List<String>? storedMessages = prefs.getStringList('messages');
    List<MessageModel> messages = storedMessages != null
        ? storedMessages
            .map((e) => MessageModel.fromMap(json.decode(e)))
            .toList()
        : [];

    messages.add(newMessage);

    await prefs.setStringList(
      'messages',
      messages.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  Future<List<MessageModel>> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedMessages = prefs.getStringList('messages');
    if (storedMessages != null) {
      return storedMessages
          .map((e) => MessageModel.fromMap(json.decode(e)))
          .toList();
    }
    return [];
  }

  Future<void> _retryGetFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      if (token != null) {
        fcmToken = token;
        isFcmAvailable = true;
        print("FCM Token: $token");
      } else {
        isFcmAvailable = false;
        print("Failed to get FCM token.");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加观察者
    messaging = FirebaseMessaging.instance;

    messaging.requestPermission();

    messaging.getToken().then((token) {
      if (token != null) {
        setState(() {
          fcmToken = token;
          isFcmAvailable = true; // 成功获取Token，更新状态为可用
        });
        print("FCM Token: $token");
      } else {
        setState(() {
          isFcmAvailable = false; // 未能获取Token，更新状态为不可用
        });
        print("Failed to get FCM token.");
      }
    });

    _loadMessages().then((loadedMessages) {
      setState(() {
        // 对消息进行时间倒序排序
        _messages = loadedMessages..sort((a, b) => b.time.compareTo(a.time));
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _saveMessage(
          message.notification?.title ?? '', message.notification?.body ?? '');
      setState(() {
        _messages.insert(
            0,
            MessageModel.fromMap({
              'id': message.hashCode,
              'title': message.notification?.title ?? '',
              'body': message.notification?.body ?? '',
              'time': DateTime.now().toIso8601String(),
            }));
        // 保持消息列表按时间倒序排序
        _messages.sort((a, b) => b.time.compareTo(a.time));
        if (_messages.length > 50) {
          _messages.removeAt(_messages.length - 1);
        }
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FCM Tester"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("FCM Token：$fcmToken"),
          ),
          if (!isFcmAvailable) // 当 FCM Token 获取失败时显示按钮
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _retryGetFcmToken, // 点击按钮时尝试重新获取 Token
                child: Text("重新获取 FCM Token"),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                MessageModel message = _messages[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              SizedBox(height: 7),
                              Text(message.body),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd kk:mm').format(message.time),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
