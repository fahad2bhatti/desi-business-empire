import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/leaderboard/leaderboard.dart';

/// Online leaderboard. One document per player, so a score costs one write
/// and the top list costs one read per row.
abstract class LeaderboardRepository {
  /// Send the player's score, replacing the last one.
  Future<void> submit({
    required String name,
    required int netWorthPaisa,
    required String cardId,
  });

  Future<List<LeaderboardEntry>> top({int limit = 50});

  /// The player's own row, or null if no score was sent yet.
  Future<LeaderboardEntry?> me();

  /// 1 for the best score; the player's place among everyone.
  Future<int> rankOf(int netWorthPaisa);

  /// The player's anonymous id once signed in, else null.
  String? get myId;
}

/// Firestore with anonymous sign-in. Firebase starts the first time it is
/// needed, so the game works without it and without internet.
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  CollectionReference<Map<String, dynamic>> get _players =>
      FirebaseFirestore.instance.collection('players');

  Future<String> _uid() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    return user!.uid;
  }

  @override
  String? get myId =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> submit({
    required String name,
    required int netWorthPaisa,
    required String cardId,
  }) async {
    final uid = await _uid();
    await _players.doc(uid).set({
      'name': name,
      'netWorth': netWorthPaisa,
      'card': cardId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  LeaderboardEntry _entry(String id, Map<String, dynamic> d) => LeaderboardEntry(
    id: id,
    name: (d['name'] as String?) ?? '',
    netWorthPaisa: (d['netWorth'] as num?)?.toInt() ?? 0,
    cardId: (d['card'] as String?) ?? '',
  );

  @override
  Future<List<LeaderboardEntry>> top({int limit = 50}) async {
    await _uid();
    final snap = await _players
        .orderBy('netWorth', descending: true)
        .limit(limit)
        .get();
    return [for (final d in snap.docs) _entry(d.id, d.data())];
  }

  @override
  Future<LeaderboardEntry?> me() async {
    final uid = await _uid();
    final doc = await _players.doc(uid).get();
    final data = doc.data();
    return data == null ? null : _entry(uid, data);
  }

  @override
  Future<int> rankOf(int netWorthPaisa) async {
    await _uid();
    final above = await _players
        .where('netWorth', isGreaterThan: netWorthPaisa)
        .count()
        .get();
    return (above.count ?? 0) + 1;
  }
}
