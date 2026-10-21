import 'package:firebase_database/firebase_database.dart';

import '../../../core/config/firebase_config.dart';

class NotificationRepository {
  final FirebaseDatabase? _database;

  NotificationRepository({FirebaseDatabase? database}) : _database = database;

  DatabaseReference _readRef(String uid) =>
      (_database ??
              FirebaseDatabase.instanceFor(
                app: FirebaseDatabase.instance.app,
                databaseURL: KerkomFirebaseConfig.options.databaseURL,
              ))
          .ref('users/$uid/notificationReads');

  Stream<Set<String>> watchReadIds(String uid) {
    return _readRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <String>{};
      return value.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .toSet();
    });
  }

  Future<void> markRead(String uid, Set<String> ids) async {
    if (ids.isEmpty) return;
    await _readRef(uid).update({for (final id in ids) id: true});
  }
}
