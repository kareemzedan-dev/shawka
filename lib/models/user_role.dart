enum UserRole {
  customer,
  delivery,
  admin,
}

extension UserRoleX on UserRole {
  String get firestoreValue => name;

  static UserRole fromFirestore(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.customer,
    );
  }
}
