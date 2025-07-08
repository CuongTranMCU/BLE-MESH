import 'package:ble_mesh/themes/mycolors.dart';
import 'package:ble_mesh/ui/home/admin/admin_group/admin_group.dart';
import 'package:ble_mesh/ui/home/profile.dart';
import 'package:ble_mesh/ui/home/users/user_home.dart';
import 'package:ble_mesh/ui/wifi/mqtt_config_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'admin/admin_home/admin_home.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  // Hàm trả về widget cho admin
  Widget _getAdminScreen(int index) {
    switch (index) {
      case 0:
        return AdminHome();
      case 1:
        return AdminGroup(); //const AdminGroup();
      case 2:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  // Hàm trả về widget cho user
  Widget _getUserScreen(int index) {
    switch (index) {
      case 0:
        return const UserHome();
      case 1:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  // Lấy màn hình dựa trên role
  Widget _getScreenForRole(String? role, int index) {
    return role == 'admin' ? _getAdminScreen(index) : _getUserScreen(index);
  }

  // Tạo danh sách navigation items
  List<Widget> _buildNavItems(String? role) {
    final items = <Widget>[
      const Icon(Icons.home, color: IconColor03),
    ];

    if (role == 'admin') {
      items.add(const Icon(Icons.group, color: IconColor03));
    }

    items.add(const Icon(Icons.account_circle, color: IconColor03));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModels?>(
      builder: (context, user, _) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final navItems = _buildNavItems(user.role);

        return Scaffold(
          body: Stack(
            children: List.generate(navItems.length, (index) {
              return Offstage(
                offstage: _currentIndex != index,
                child: _currentIndex == index ? _getScreenForRole(user.role, index) : const SizedBox.shrink(),
              );
            }),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: navItems,
            animationDuration: Duration(milliseconds: 500),
            color: NavigationBarColor,
            backgroundColor: BackgroundColor,
          ),
        );
      },
    );
  }
}
