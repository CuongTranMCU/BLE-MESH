import 'package:ble_mesh/providers/control_signal_provider.dart';
import 'package:ble_mesh/providers/data_provider.dart';
import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/providers/screen_ui_controller.dart';
import 'package:ble_mesh/providers/user_provider.dart';
import 'package:ble_mesh/providers/verify_email_controller.dart';
import 'package:ble_mesh/themes/mycolors.dart';
import 'package:ble_mesh/ui/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'cloud_services/auth_service.dart';
import 'cloud_services/messaging_service.dart';
import 'database_services/hive_boxes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("❌ Firebase đã được khởi tạo trước đó hoặc có lỗi xảy ra: $e");
  }

  try {
    final messagingService = MessagingService();
    await messagingService.initialize();
  } catch (e) {
    print("❌ Lỗi khi khởi tạo MessagingService: $e");
  }

  try {
    await Hive.initFlutter();
    await Hive.openBox(mqttBox);
  } catch (e) {
    print("❌ Lỗi khi khởi tạo Hive hoặc mở Box: $e");
  }

  runApp(
    const ToastificationWrapper(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<UserModels?>.value(
          value: AuthService().user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => ScreenUiController()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => NodesProvider()),
        ChangeNotifierProvider(create: (_) => VerifyEmailController()),
        ChangeNotifierProvider(create: (_) => ControlSignalProvider()),
      ],
      child: MaterialApp(
        title: 'Weather UI',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: BgColor,
          scaffoldBackgroundColor: BgColor,
          appBarTheme: const AppBarTheme(color: BgColor, shadowColor: Colors.transparent),
        ),
        // home: const StockPage(title: 'Weather UI'),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
