import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';

/// Handles "login with unique ID" by mapping a user's owner-issued unique ID
/// to a synthetic email under the hood, then loading their role from Firestore.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Domain we attach to a unique ID to form a Firebase Auth email.
  static const _authDomain = 'hostel.app';

  static String _emailForId(String uniqueId) =>
      '${uniqueId.trim().toLowerCase()}@$_authDomain';

  /// Watch Firebase auth state and keep [currentUser] in sync with the user doc.
  Future<void> bootstrap() async {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
      } else {
        _currentUser = await _loadUserDoc(user.uid);
      }
      notifyListeners();
    });
    // Pick up an already-signed-in session on cold start.
    final existing = _auth.currentUser;
    if (existing != null) {
      _currentUser = await _loadUserDoc(existing.uid);
      notifyListeners();
    }
  }

  Future<AppUser?> _loadUserDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  /// Log in with the owner-issued unique ID + password.
  Future<AppUser> loginWithUniqueId({
    required String uniqueId,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _emailForId(uniqueId),
      password: password,
    );
    final user = await _loadUserDoc(cred.user!.uid);
    if (user == null) {
      throw Exception('No profile found for this ID. Contact the owner.');
    }
    _currentUser = user;
    notifyListeners();
    return user;
  }

  /// Owner self-signup (the first/admin account). The login id is fixed to
  /// `OWNER`, so the Auth account uses the synthetic `owner@hostel.app` email —
  /// that way the owner logs in with id `OWNER` + [password] like everyone else.
  /// [contactEmail] is stored only as profile metadata.
  Future<AppUser> registerOwner({
    required String password,
    required String name,
    String? contactEmail,
  }) async {
    const ownerId = 'OWNER';
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailForId(ownerId),
      password: password,
    );
    final user = AppUser(
      uid: cred.user!.uid,
      uniqueId: ownerId,
      role: AppRole.owner,
      name: name,
      email: contactEmail,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    _currentUser = user;
    notifyListeners();
    return user;
  }

  /// Issue a new tenant/staff login. Creates the Firebase Auth account on a
  /// throwaway secondary app so the Owner stays signed in, writes the
  /// `users/{uid}` doc, and returns the new uid. The synthetic email is
  /// `{uniqueId}@hostel.app`; the user logs in with [uniqueId] + [password].
  Future<String> issueAccount({
    required String uniqueId,
    required String password,
    required AppRole role,
    required String name,
    String? linkedId,
  }) async {
    // A named secondary app keeps its own auth session, so creating a user
    // here does NOT replace the Owner's currentUser on the default app.
    final secondary = await Firebase.initializeApp(
      name: 'provisioning',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final cred = await FirebaseAuth.instanceFor(app: secondary)
          .createUserWithEmailAndPassword(
        email: _emailForId(uniqueId),
        password: password,
      );
      final uid = cred.user!.uid;
      final user = AppUser(
        uid: uid,
        uniqueId: uniqueId,
        role: role,
        name: name,
        linkedId: linkedId,
      );
      await _db.collection('users').doc(uid).set(user.toMap());
      await FirebaseAuth.instanceFor(app: secondary).signOut();
      return uid;
    } finally {
      await secondary.delete();
    }
  }

  /// Back-link the `users/{uid}` doc to its tenants/staff document id once that
  /// document has been created (so the right id is known after [issueAccount]).
  Future<void> linkUserToDoc({
    required String uid,
    required String linkedId,
  }) async {
    await _db.collection('users').doc(uid).update({'linkedId': linkedId});
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
