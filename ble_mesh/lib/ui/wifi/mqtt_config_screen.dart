import 'dart:async';

import 'package:ble_mesh/models/mqtt_data.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:toastification/toastification.dart';

import '../../themes/mycolors.dart';
import '../../widgets/constant_values.dart';
import '../../widgets/custom_widgets.dart';
import 'loading_screen.dart';

class MqttConfigScreen extends StatefulWidget {
  MqttConfigScreen({
    super.key,
    required this.passwordWiFi,
    required this.SSID,
    required this.BSSID,
  });
  String passwordWiFi;
  String SSID;
  String BSSID;

  @override
  State<MqttConfigScreen> createState() => _MqttConfigScreenState();
}

class _MqttConfigScreenState extends State<MqttConfigScreen> {
  final mqttData = MqttData();
  final _formKey = GlobalKey<FormState>();

  final hostController = TextEditingController();
  final portController = TextEditingController();
  final userNameMQTTController = TextEditingController();
  final passwordMQTTController = TextEditingController();

  late HostLabel selectedHost;

  @override
  void initState() {
    super.initState();
    selectedHost = mqttData.mqttHost;

    hostController.text = mqttData.mqttHostName;
    portController.text = mqttData.mqttPort;
    userNameMQTTController.text = mqttData.mqttUserName;
    passwordMQTTController.text = mqttData.mqttPassword;
  }

  StreamSubscription<ProvisioningResponse>? _subscription;
  bool _isProvisioning = false;
  late Provisioner provisioner;

  Future<void> _startProvisioning() async {
    if (_isProvisioning) return;
    // setState(() {
    // });
    _isProvisioning = true;

    provisioner = Provisioner.espTouchV2();

    try {
      _subscription = provisioner.listen((response) {
        if (mounted) {
          // setState(() =>);
          _isProvisioning = false;
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (response != null) {
            _onDeviceProvisioned(response);
            _stopProvisioning();
          }
        }
      });
    } catch (e) {
      _isProvisioning = false;
      toastification.show(
        type: ToastificationType.error,
        title: Text(
          'Error: ${e.toString()}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        direction: TextDirection.ltr,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }

    try {
      // Chưa đủ 64 byte
      final mqttData = "${selectedHost.protocol}" // 8byte
          "${hostController.text.trim()};" // 20 byte + 1 byte ";"
          "${portController.text.trim()};" // 4 byte + 1 byte ";"
          "${userNameMQTTController.text.trim()};" // 12 byte + 1 byte ";"
          "${passwordMQTTController.text.trim()}"; // 12 byte

      debugPrint("MqttData : $mqttData Size : ${mqttData.length}");

      if (widget.passwordWiFi.isEmpty) {
        provisioner.start(ProvisioningRequest.fromStrings(
          ssid: widget.SSID,
          bssid: widget.BSSID,
          password: null,
          reservedData: mqttData, // 64 byte
        ));
      } else {
        provisioner.start(ProvisioningRequest.fromStrings(
          ssid: widget.SSID, // 32 byte
          bssid: widget.BSSID,
          password: widget.passwordWiFi, // 64 byte
          reservedData: mqttData, //  64 byte
        ));
      }
    } catch (e) {
      toastification.show(
        type: ToastificationType.error,
        title: Text(
          'Error: ${e.toString()}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        direction: TextDirection.ltr,
        autoCloseDuration: const Duration(seconds: 5),
      );
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoadingScreen(onCancel: _stopProvisioning)),
      );
    }
  }

  void _stopProvisioning() async {
    _isProvisioning = false;

    if (provisioner.running) {
      provisioner.stop();
    }

    await _subscription?.cancel();
    _subscription = null;
  }

  _onDeviceProvisioned(ProvisioningResponse response) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Device provisioned'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Device successfully connected to the ${widget.SSID} network'),
              SizedBox.fromSize(size: const Size.fromHeight(20)),
              Text('IP: ${response.ipAddressText}'),
              Text('BSSID: ${response.bssidText}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String mapConnectionType(ConnectionTypeLabel type) {
    if (type == ConnectionTypeLabel.none)
      return "0";
    else if (type == ConnectionTypeLabel.overTCP)
      return "1";
    else if (type == ConnectionTypeLabel.overSSL)
      return "2";
    else if (type == ConnectionTypeLabel.overWS)
      return "3";
    else if (type == ConnectionTypeLabel.overWSS)
      return "4";
    else
      return "-1";
  }

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    userNameMQTTController.dispose();
    passwordMQTTController.dispose();
    _stopProvisioning();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MQTT Configuration',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTitleColor2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/images/mqtt_broker.json",
                width: 200,
                height: 200,
              ),

              //host
              CustomTextFormField(
                controller: hostController,
                hintText: "Enter host",
                textInputType: TextInputType.text,
                maxLength: 20,
                validatorFunction: (val) {
                  if (val == null || val.isEmpty) {
                    return "Host can not be null !";
                  }
                  if (val.length > 20) return "Name host must be less than 20 characters.";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // port
              Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdownButton2<HostLabel>(
                    selectedItem: selectedHost,
                    width: 170,
                    items: HostLabel.values,
                    onSelected: (val) => setState(() {
                      selectedHost = val!;
                    }),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 180,
                    child: CustomTextFormField(
                      controller: portController,
                      hintText: "Enter Port",
                      textInputType: TextInputType.number,
                      maxLength: 4,
                      validatorFunction: (val) {
                        if (val == null || val.isEmpty) {
                          return "Port can't be empty !";
                        }
                        if (val.length > 4) {
                          return "The number port cannot exceed 4 digits.";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              CustomTextFormField(
                controller: userNameMQTTController,
                hintText: 'User name',
                textInputType: TextInputType.text,
                maxLength: 12,
                validatorFunction: (val) {
                  if (val == null || val.isEmpty) {
                    return null;
                  }
                  if (val.length > 20) return "User name cannot exceed 20 characters";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              CustomTextFormField(
                controller: passwordMQTTController,
                hintText: 'Password',
                textInputType: TextInputType.text,
                maxLength: 12,
                isPassword: true,
                validatorFunction: (val) {
                  if (val == null || val.isEmpty) {
                    return null;
                  }
                  if (val.length > 15) return "Password cannot exceed 64 characters";
                  return null;
                },
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 200));

                  mqttData.mqttHost = selectedHost;
                  mqttData.mqttHostName = hostController.text.trim();
                  mqttData.mqttPort = portController.text.trim();
                  mqttData.mqttUserName = userNameMQTTController.text.trim();
                  mqttData.mqttPassword = passwordMQTTController.text.trim();

                  await mqttData.updateData();

                  await _startProvisioning();
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
