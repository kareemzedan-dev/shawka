import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/user_role.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.users);

  Stream<List<AppUser>> watchUsersByRole(UserRole role) {
    return _collection
        .where('role', isEqualTo: role.firestoreValue)
        .snapshots()
        .map((snap) {
      final users = snap.docs.map(AppUser.fromFirestore).toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  Stream<List<AppUser>> watchDeliveryAgents({String? governorate}) {
    return _collection
        .where('role', isEqualTo: UserRole.delivery.firestoreValue)
        .snapshots()
        .map((snap) {
      var users = snap.docs.map(AppUser.fromFirestore).toList();
      if (governorate != null && governorate.isNotEmpty) {
        users = users
            .where(
              (u) =>
                  u.governorate.isEmpty || u.governorate == governorate,
            )
            .toList();
      }
      users.sort((a, b) => a.name.compareTo(b.name));
      return users;
    });
  }

  Future<void> updateUser(AppUser user) {
    return _collection.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setRole(String uid, UserRole role) {
    return _collection.doc(uid).update({'role': role.firestoreValue});
  }

  Future<void> setStaffRole(String uid, AdminStaffRole staffRole) {
    return _collection.doc(uid).update({'staffRole': staffRole.firestoreValue});
  }

  Stream<List<AppUser>> watchStaffUsers() {
    return _collection
        .where('role', isEqualTo: UserRole.admin.firestoreValue)
        .snapshots()
        .map((snap) {
      final users = snap.docs.map(AppUser.fromFirestore).toList();
      users.sort((a, b) => a.name.compareTo(b.name));
      return users;
    });
  }

  Future<AppUser?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final snap = await _collection
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      final snap2 = await _collection
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (snap2.docs.isEmpty) return null;
      return AppUser.fromFirestore(snap2.docs.first);
    }
    return AppUser.fromFirestore(snap.docs.first);
  }

  Future<void> setDeliveryActive(String uid, bool isActive) {
    return _collection.doc(uid).update({'isActive': isActive});
  }

  Future<void> updateFcmToken(String uid, String token) {
    return _collection.doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearFcmToken(String uid) {
    return _collection.doc(uid).update({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> touchLastActive(String uid) {
    return _collection.doc(uid).set(
      {'lastActiveAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Stream<AppUser?> watchUser(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<void> updateDriverLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) {
    return _collection.doc(uid).set(
      {
        'location': GeoPoint(latitude, longitude),
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  int countOnlineUsers(List<AppUser> users) =>
      users.where((u) => u.isOnline).length;

  /// عملاء متصلون ضمن محافظة (فارغ = يُحسب للجميع).
  int countOnlineCustomers({
    required List<AppUser> customers,
    required String governorate,
  }) {
    return customers
        .where(
          (u) =>
              u.isOnline &&
              (governorate.isEmpty ||
                  u.governorate.isEmpty ||
                  u.governorate == governorate),
        )
        .length;
  }

  List<AppUser> onlineDrivers(List<AppUser> agents) => agents
      .where((a) => a.isActive && a.isOnline && a.hasLiveLocation)
      .toList();
}
