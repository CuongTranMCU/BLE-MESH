import 'dart:async';
import 'package:flutter/material.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:toastification/toastification.dart';
import 'loading_screen.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({
    super.key,
    required this.SSID,
    required this.BSSID,
  });

  final String SSID;
  final String BSSID;

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>(); // Thêm key để kiểm tra form

  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier(false);
  StreamSubscription<ProvisioningResponse>? _subscription;
  bool _isProvisioning = false;
  late Provisioner provisioner;

  void _validateForm() {
    _isButtonEnabled.value = _formKey.currentState?.validate() ?? false;
  }

  Future<void> _startProvisioning() async {
    if (_isProvisioning) return;
    setState(() {
      _isProvisioning = true;
    });

    provisioner = Provisioner.espTouch();

    try {
      _subscription = provisioner.listen((response) {
        if (mounted) {
          setState(() => _isProvisioning = false);

          Navigator.of(context).pop();
          if (response != null) {
            _onDeviceProvisioned(response);
          }
        }
      });
    } catch (e) {
      print(e);

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
      provisioner.start(ProvisioningRequest.fromStrings(
        ssid: widget.SSID,
        bssid: widget.BSSID,
        password: passwordController.text,
      ));
    } catch (e) {
      print(e);
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

    setState(() => _isProvisioning = false);
    await _subscription?.cancel();
    _subscription = null;

    if (provisioner.running) {
      provisioner.stop();
    }
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
              const Text('Device:'),
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

  @override
  void dispose() {
    _stopProvisioning();
    passwordController.dispose();
    _isButtonEnabled.dispose();
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
        title: const Text("SmartConfig"),
        centerTitle: true,
        actions: [
          Image.asset("assets/icons/wifi6.png", width: 38, height: 38),
          const SizedBox(width: 22),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  "assets/icons/access_point_0.png",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  color: Colors.blue,
                ),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: Text("SSID: ${widget.SSID}")),
                const SizedBox(height: 15),
                SizedBox(width: double.infinity, child: Text("BSSID: ${widget.BSSID}")),
                const SizedBox(height: 5),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  maxLength: 64,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password cannot be empty';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                  onChanged: (_) => _validateForm(), // Kiểm tra lại khi nhập
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<bool>(
                  valueListenable: _isButtonEnabled,
                  builder: (context, isEnabled, child) {
                    return ElevatedButton(
                      onPressed: isEnabled ? _startProvisioning : null,
                      child: const Text('Start provisioning'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
