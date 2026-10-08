import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// محاكاة إيصال تنبيه إلى **تطبيق ولي الأمر** عبر شريط إشعارات النظام (مثل FCM لكن محلي).
/// تُستدعى فقط عند تسجيل دخول دور `parent` في [MainScreen].
class ParentNotificationService {
  ParentNotificationService._();
  static final ParentNotificationService instance = ParentNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _androidChannel = AndroidNotificationChannel(
    'kidshield_parent_alerts',
    'تنبيهات ولي الأمر',
    description: 'محاكاة وصول حدث من جهاز الطفل لحساب الأب',
    importance: Importance.high,
    playSound: true,
    showBadge: true,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initIos = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: initAndroid,
          iOS: initIos,
        ),
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(_androidChannel);
        await android.requestNotificationsPermission();
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (e, st) {
      debugPrint('ParentNotificationService.init: $e\n$st');
    }
  }

  /// إظهار إشعار لحساب الأب (نفس الجهاز في التجربة = «وصلت للأب»).
  Future<void> showParentAlert({
    required int notificationId,
    required String reason,
    String? sourceApp,
    String? childName,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;

    final sub = <String>[];
    if (sourceApp != null && sourceApp.isNotEmpty) {
      sub.add('المصدر: $sourceApp');
    }
    if (childName != null && childName.isNotEmpty) {
      sub.add('الطفل: $childName');
    }
    final body = sub.isEmpty
        ? reason
        : '${sub.join(' · ')}\n$reason';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'KidShield',
    );

    try {
      await _plugin.show(
        notificationId.abs() % 0x3FFFFFFF,
        'KidShield — تنبيه لولي الأمر',
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e, st) {
      debugPrint('ParentNotificationService.showParentAlert: $e\n$st');
    }
  }
}
