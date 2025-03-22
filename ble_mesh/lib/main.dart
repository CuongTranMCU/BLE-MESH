import 'package:ble_mesh/cloud_functions/auth_service.dart';
import 'package:ble_mesh/models/user.dart';
import 'package:ble_mesh/providers/data_provider.dart';
import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/themes/mycolors.dart';
import 'package:ble_mesh/ui/home.dart';
import 'package:ble_mesh/ui/main_navigator.dart';
import 'package:ble_mesh/ui/stock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ToastificationWrapper(
    child: MyApp(),
  ));
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
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => NodesProvider()),
      ],
      child: MaterialApp(
        title: 'Weather UI',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: BgColor,
          scaffoldBackgroundColor: BgColor,
          appBarTheme: const AppBarTheme(color: BgColor, shadowColor: Colors.transparent),
        ),
        // home: const StockPage(title: 'Weather UI'),
        home: MainNavigator(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
