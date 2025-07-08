// Map user from Authentication  // Use for Stream Provider
class UserModels {
  final String uid;
  final String? email;
  final String? role;
  final bool emailVerify;

  UserModels({
    required this.uid,
    required this.email,
    required this.role,
    required this.emailVerify,
  });
}
