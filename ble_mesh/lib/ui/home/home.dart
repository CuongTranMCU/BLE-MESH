import 'package:ble_mesh/ui/home/admin/account.dart';
import 'package:ble_mesh/ui/home/admin/admin_group.dart';
import 'package:ble_mesh/ui/home/users/user_home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import 'admin/admin_home.dart';

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
        return const AdminHome();
      case 1:
        return const AdminGroup();
      case 2:
        return const AccountPage();
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
        return const AccountPage();
      default:
        return const SizedBox.shrink();
    }
  }

  // Lấy màn hình dựa trên role
  Widget _getScreenForRole(String? role, int index) {
    return role == 'admin' ? _getAdminScreen(index) : _getUserScreen(index);
  }

  // Tạo danh sách navigation items
  List<BottomNavigationBarItem> _buildNavItems(String? role) {
    final items = [
      const BottomNavigationBarItem(
        label: 'Home',
        icon: Icon(Icons.home),
      ),
    ];

    if (role == 'admin') {
      items.add(
        const BottomNavigationBarItem(
          label: 'Group',
          icon: Icon(Icons.group),
        ),
      );
    }

    items.add(
      const BottomNavigationBarItem(
        label: 'Account',
        icon: Icon(Icons.account_circle),
      ),
    );

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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: navItems,
          ),
        );
      },
    );
  }
}
