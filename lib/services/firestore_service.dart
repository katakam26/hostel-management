import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper over Firestore collections used across the app. Screens use
/// this instead of touching FirebaseFirestore directly, so collection names
/// and queries live in one place.
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---- collection references -------------------------------------------
  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get blocks => _db.collection('blocks');
  CollectionReference<Map<String, dynamic>> get floors => _db.collection('floors');
  CollectionReference<Map<String, dynamic>> get rooms => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get beds => _db.collection('beds');
  CollectionReference<Map<String, dynamic>> get tenants => _db.collection('tenants');
  CollectionReference<Map<String, dynamic>> get staff => _db.collection('staff');
  CollectionReference<Map<String, dynamic>> get attendance =>
      _db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get payments =>
      _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get complaints =>
      _db.collection('complaints');
  CollectionReference<Map<String, dynamic>> get requests =>
      _db.collection('requests');
  CollectionReference<Map<String, dynamic>> get menus => _db.collection('menus');
  CollectionReference<Map<String, dynamic>> get notices =>
      _db.collection('notices');
  CollectionReference<Map<String, dynamic>> get expenses =>
      _db.collection('expenses');
  CollectionReference<Map<String, dynamic>> get amenityBookings =>
      _db.collection('amenityBookings');
  CollectionReference<Map<String, dynamic>> get ratings =>
      _db.collection('ratings');
}
