import 'package:ble_mesh/ui/wifi/mqtt_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../themes/mycolors.dart';
import '../../widgets/custom_widgets.dart';

class WifiConfigScreen extends StatefulWidget {
  const WifiConfigScreen({
    super.key,
    required this.SSID,
    required this.BSSID,
  });

  final String SSID;
  final String BSSID;

  @override
  State<WifiConfigScreen> createState() => _WifiConfigScreenState();
}

class _WifiConfigScreenState extends State<WifiConfigScreen> {
  final passwordController = TextEditingController();
  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          widget.SSID,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTitleColor2,
          ),
        ),
        centerTitle: true,
        actions: [
          Image.asset("assets/icons/wifi6.png", width: 38, height: 38),
          const SizedBox(width: 22),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Lottie.asset("assets/images/eye_wifi.json", width: 200, height: 200),
              CustomTextFormField(
                controller: passwordController,
                hintText: 'Password',
                textInputType: TextInputType.text,
                maxLength: 64,
                isPassword: true,
                validatorFunction: (val) {
                  if (val == null || val.isEmpty) {
                    return null;
                  } else if (val.length > 64) return "Password cannot exceed 64 characters";
                  return null;
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  // ĐÓNG BÀN PHÍM TRƯỚC
                  FocusScope.of(context).unfocus();
                  // Đợi 200 milliseconds
                  await Future.delayed(const Duration(milliseconds: 200));

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MqttConfigScreen(
                              SSID: widget.SSID,
                              BSSID: widget.BSSID,
                              passwordWiFi: passwordController.text.trim(),
                            )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ButtonColor01,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    color: ButtonColor01,
                  ),
                  child: const Center(
                    child: Text(
                      'Start provisioning',
                      style: TextStyle(color: TextColor02, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
