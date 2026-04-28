import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/ticket_detail_screen.dart';

/// Background message handler (must be top-level / @pragma('vm:entry-point')).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM received: ${message.messageId}');
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Global navigator key so we can push routes from outside a BuildContext
  /// (e.g. when the user taps a push notification).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Global scaffold messenger key for foreground SnackBars.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Call ONCE at app startup (after Firebase.initializeApp).
  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message → show a SnackBar + deep-link action
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      final ticketId = message.data['ticketId'];
      final messenger = scaffoldMessengerKey.currentState;
      if (n != null && messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00C853),
            content: Text('${n.title ?? "Support"}\n${n.body ?? ""}',
                style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 5),
            action: (ticketId != null && ticketId.toString().isNotEmpty)
                ? SnackBarAction(
                    label: 'OPEN',
                    textColor: Colors.white,
                    onPressed: () => _openTicket(ticketId.toString()),
                  )
                : null,
          ),
        );
      }
    });

    // Tapping a notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Token lifecycle
    await registerTokenForCurrentUser();
    _messaging.onTokenRefresh.listen((_) => registerTokenForCurrentUser());
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) registerTokenForCurrentUser();
    });
  }

  /// Called from MainLayout after the user is authenticated and home is ready.
  /// Checks if the app was cold-started via a notification tap and, if so,
  /// navigates to the correct ticket.
  static Future<void> handleInitialMessage() async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageTap(initial);
  }

  static void _handleMessageTap(RemoteMessage message) {
    final ticketId = message.data['ticketId'];
    if (ticketId == null || ticketId.toString().isEmpty) return;
    _openTicket(ticketId.toString());
  }

  static void _openTicket(String ticketId) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    // Give the framework a tick so the current route is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.push(MaterialPageRoute(
        builder: (_) =>
            TicketDetailScreen(ticketId: ticketId, isAdminView: false),
      ));
    });
  }

  /// Store the current device FCM token in `users/{uid}.fcmTokens[]`.
  static Future<void> registerTokenForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }

  /// Remove the current device token on logout.
  static Future<void> unregisterTokenForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('FCM unregister error: $e');
    }
  }
}
