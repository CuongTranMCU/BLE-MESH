import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class RTDBServiceAccount {
  final _database = FirebaseDatabase.instance.ref();
  final String uid;

  RTDBServiceAccount({this.uid = ""});

  Future updateUserData(String email, String userName, String role) async {
    try {
      final userData = <String, dynamic>{
        "email": email,
        "userName": userName,
        "role": role,
      };
      await _database.child('Accounts/$uid').update(userData);
    } catch (e) {
      print("Error update user data : $e");
    }
  }

  Stream<UserData> getUserStream() {
    final userStream = _database.child('Accounts/$uid').onValue;
    final streamToPublish = userStream.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map<dynamic, dynamic>) {
        // Return a default UserData object if data is null or not a map
        return UserData.empty();
      }
      final userMap = Map<String, dynamic>.from(data);
      return UserData.fromRTDB(userMap);
    });
    return streamToPublish;
  }

  Future<dynamic> getUserdata(String field) async {
    try {
      final snapshot = await _database.child('Accounts/$uid/$field').get();
      if (snapshot.exists) {
        return snapshot.value;
      } else {
        print('No data available.');
        return null;
      }
    } catch (e) {
      print("Error update control : $e");
      return null;
    }
  }
}
