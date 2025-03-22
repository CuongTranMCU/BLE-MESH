import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cloud_functions/auth_service.dart';
import '../../../cloud_functions/realtime_db.dart';
import '../../../models/user.dart';
import '../../../widgets/loading.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() {
    return _AccountPageState();
  }
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModels>(context);
    final AuthService authService = AuthService();

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<UserData>(
      stream: RealTimeDBService(uid: user.uid).getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          UserData userData = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // User Information
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(25.0),
                  height: screenHeight / 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          const CircleAvatar(
                            radius: 42,
                            backgroundImage: AssetImage("assets/images/avatar.jpeg"),
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person, // Icon mặc định khi không có ảnh
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Divider(),
                          const SizedBox(height: 10.0),

                          // Username
                          Row(
                            children: [
                              const Icon(Icons.person, size: 38),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  userData.userName,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Divider(),
                          const SizedBox(height: 10.0),

                          // Email
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 38),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  userData.email,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          const Divider(),
                          const SizedBox(height: 10.0),

                          // Logout
                          GestureDetector(
                            onTap: () async {
                              await authService.signOut();
                              //Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.logout, size: 38),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    "Thoát",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Loading();
        }
      },
    );
  }
}
