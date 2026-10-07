import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class BackendService {
  BackendService._();
  static final instance = BackendService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  final _uuid = const Uuid();

  String get uid => auth.currentUser!.uid;

  Future<void> initialize({required bool useEmulators}) async {
    if (useEmulators) {
      const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '10.0.2.2');
      await auth.useAuthEmulator(host, 9099);
      firestore.useFirestoreEmulator(host, 8080);
      functions.useFunctionsEmulator(host, 5001);
    }
    if (auth.currentUser == null) await auth.signInAnonymously();
    if (!useEmulators && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseMessaging.instance.requestPermission();
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _saveToken(token);
        FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
      } catch (error) {
        debugPrint('FCM tidak tersedia: $error');
      }
    }
  }

  Future<void> _saveToken(String token) => firestore.doc('users/$uid/devices/current').set({
        'token': token,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final result = await functions.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> createRoom(String name, String title, int minutes) =>
      _call('createRoom', {'displayName': name, 'title': title, 'durationMinutes': minutes});

  Future<Map<String, dynamic>> joinRoom(String name, String code) =>
      _call('joinRoom', {'displayName': name, 'code': code});

  Future<Map<String, dynamic>> startSession(String roomId) =>
      _call('startSession', {'roomId': roomId});

  Future<void> endSession(String roomId, String sessionId) async =>
      _call('endSession', {'roomId': roomId, 'sessionId': sessionId});

  Future<void> leaveRoom(String roomId) async =>
      _call('leaveRoom', {'roomId': roomId});

  Future<void> submitSuspectedUse({
    required String roomId,
    required String sessionId,
    required String episodeId,
    required DateTime observedAt,
    required int durationMs,
    required double peakAccel,
    required double peakGyro,
    required double orientationChangeDeg,
    required double confidence,
  }) async {
    await _call('submitFocusEvent', {
      'roomId': roomId,
      'sessionId': sessionId,
      'eventId': _uuid.v4(),
      'episodeId': episodeId,
      'type': 'suspected_use',
      'observedAtMs': observedAt.millisecondsSinceEpoch,
      'durationMs': durationMs.clamp(250, 120000),
      'ruleVersion': 'motion-rule-2',
      'calibrationVersion': 'table-orientation-1',
      'evidence': {
        'peakGyro': peakGyro,
        'rmsGyro': peakGyro,
        'peakAccel': peakAccel,
        'orientationChangeDeg': orientationChangeDeg,
        'confidence': confidence,
      },
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String id) =>
      firestore.doc('rooms/$id').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMembers(String id) =>
      firestore.collection('rooms/$id/members').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPresence(String roomId, String sessionId) =>
      firestore.collection('rooms/$roomId/sessions/$sessionId/presence').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEvents(String roomId, String sessionId) =>
      firestore.collection('rooms/$roomId/sessions/$sessionId/events')
          .orderBy('receivedAt', descending: true).limit(50).snapshots();

  Future<void> heartbeat(String roomId, String sessionId, String state) =>
      firestore.doc('rooms/$roomId/sessions/$sessionId/presence/$uid').set({
        'state': state,
        'heartbeatAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
