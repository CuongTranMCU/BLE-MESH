// Map user from Realtime Database
class UserData {
  final String email;
  final String userName;

  UserData({
    required this.email,
    required this.userName,
  });

  factory UserData.fromRTDB(Map<dynamic, dynamic> data) {
    return UserData(
      email: data["email"] as String? ?? '',
      userName: data["userName"] as String? ?? '',
    );
  }

  factory UserData.empty() {
    return UserData(
      email: "None",
      userName: "None",
    );
  }
}
