import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cloud_services/auth_service.dart';
import '../../../cloud_services/rtdb_service_account.dart';
import '../../../models/user.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/loading.dart';
import '../../themes/mycolors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModels>(context);
    final AuthService authService = AuthService();

    double screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<UserData>(
      stream: RTDBServiceAccount(uid: user.uid).getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          UserData userData = snapshot.data!;
          return Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: screenHeight / 2,
                    margin: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [AppTitleColor2.withOpacity(0.8), AppTitleColor1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: IconColor04,
                                width: 3.0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundImage: const AssetImage("assets/images/avatar.jpeg"),
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username
                          Row(
                            children: [
                              const Icon(Icons.person, size: 28, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userData.userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withOpacity(0.4)),

                          // Email
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 28, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userData.email,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withOpacity(0.4)),

                          // Logout
                          GestureDetector(
                            onTap: () async {
                              await authService.signOut();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.logout, size: 28, color: Colors.white),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Thoát",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Loading();
        }
      },
    );
  }
}
