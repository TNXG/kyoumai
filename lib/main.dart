import 'package:flutter/material.dart'; // 导入Flutter材料设计包
import 'package:firebase_core/firebase_core.dart'; // 导入Firebase核心包
import 'package:firebase_messaging/firebase_messaging.dart'; // 导入Firebase消息传递包
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 导入Flutter本地通知包
import 'package:shared_preferences/shared_preferences.dart'; // 导入SharedPreferences包
import 'package:permission_handler/permission_handler.dart'; // 导入权限处理包
import 'package:intl/intl.dart'; // 导入日期格式化包
import 'dart:convert'; // 导入JSON编码解码包
import 'dart:io'; // 导入IO包

// 消息模型
class MessageModel {
  int id;
  String title;
  String body;
  DateTime time;

  MessageModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
  });

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (Platform.isAndroid) {
    final sdkIntMatch =
        RegExp(r'\d+').firstMatch(Platform.operatingSystemVersion);
    if (sdkIntMatch != null) {
      final sdkInt = int.parse(sdkIntMatch.group(0)!);
      if (sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (status != PermissionStatus.granted) {
          await Permission.notification.request();
        }
      }
    }
  }
  NotificationService.initialize(); // 确保通知服务初始化
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 正常处理数据消息
  final String title = message.notification?.title ?? '';
  final String body = message.notification?.body ?? '';
  final String time = message.data['time'] ?? DateTime.now().toIso8601String();
  print("[Kyoumai]_firebaseMessagingBackgroundHandler后台推送");
  await _saveMessage(title, body, time); // 确保保存消息
  print("[Kyoumai]后台消息处理被触发: ${message.messageId}");
}

// 通知服务
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
      'kyoumaipush', // 与显示通知时使用的ID相同
      'kyoumai推送服务',
      description: 'kyoumai自建的FCM推送服务',
      importance: Importance.high,
    );

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void showNotification(RemoteMessage message) {
    print("[Kyoumai]showNotification被触发");
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'kyoumaipush',
        'kyoumai推送服务',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    _notificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}

Future<void> _saveMessage(String title, String body, String time) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  MessageModel newMessage = MessageModel(
    id: DateTime.now().millisecondsSinceEpoch,
    title: title,
    body: body,
    time: DateTime.parse(time),
  );

  List<String>? storedMessages = prefs.getStringList('messages');
  List<MessageModel> messages = storedMessages != null
      ? storedMessages.map((e) => MessageModel.fromMap(json.decode(e))).toList()
      : [];

  messages.add(newMessage);
  await prefs.setStringList(
    'messages',
    messages.map((e) => json.encode(e.toMap())).toList(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyoumai',
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    messaging = FirebaseMessaging.instance;

    messaging.requestPermission();

    messaging.getToken().then((token) {
      if (token != null) {
        setState(() {
          fcmToken = token;
          isFcmAvailable = true;
        });
        print("[Kyoumai]FCM Token: $token");
      } else {
        setState(() {
          isFcmAvailable = false;
        });
        print("[Kyoumai]Failed to get FCM token.");
      }
    });

    _loadMessages().then((loadedMessages) {
      setState(() {
        _messages = loadedMessages..sort((a, b) => b.time.compareTo(a.time));
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final String title = message.notification?.title ?? '';
      final String body = message.notification?.body ?? '';
      final String time =
          message.data['time'] ?? DateTime.now().toIso8601String();
      print("[Kyoumai]草");
      NotificationService.showNotification(message);
      print("[Kyoumai]草");
      print("[Kyoumai]Message received: $title, $body, $time");
      await _saveMessage(title, body, time); // 确保保存消息
      _loadMessages().then((loadedMessages) {
        setState(() {
          _messages = loadedMessages..sort((a, b) => b.time.compareTo(a.time));
        });
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[Kyoumai]Message clicked');
    });
  }

  Future<void> _deleteMessage(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _messages.removeAt(index);
    await prefs.setStringList(
      'messages',
      _messages.map((e) => json.encode(e.toMap())).toList(),
    );
    setState(() {});
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
        print("[Kyoumai]FCM Token: $token");
      } else {
        isFcmAvailable = false;
        print("[Kyoumai]Failed to get FCM token.");
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 当应用从后台恢复到前台时，重绘页面
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("kyoumai"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("FCM Token：$fcmToken"),
          ),
          if (!isFcmAvailable)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _retryGetFcmToken,
                child: Text("重新获取 FCM Token"),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                MessageModel message = _messages[index];
                return GestureDetector(
                  onLongPress: () async {
                    final bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('删除消息'),
                          content: Text('确定要删除这条消息吗？'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmDelete ?? false) {
                      _deleteMessage(index);
                    }
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                SizedBox(height: 7),
                                Text(message.body),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd kk:mm:ss')
                                .format(message.time),
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
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