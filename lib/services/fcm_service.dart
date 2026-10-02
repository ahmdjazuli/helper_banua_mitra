import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan.');
      await saveFCMToken();
      _setupTokenRefreshListener();
    } else {
      print('Izin notifikasi ditolak oleh pengguna.');
    }
  }

  static Future<String?> saveFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      print("FCM Token Perangkat: $token");

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return token;
    } catch (e) {
      print("Gagal menyimpan FCM Token: $e");
      return null;
    }
  }

  static void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  static Future<void> removeFCMTokenOnLogout() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'fcmToken': FieldValue.delete(),
        });
        print("FCM Token berhasil dihapus dari Firestore saat logout.");
      }
    } catch (e) {
      print("Gagal menghapus FCM Token saat logout: $e");
    }
  }
}