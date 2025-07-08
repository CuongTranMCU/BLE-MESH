import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../cloud_services/auth_service.dart';
import '../../providers/screen_ui_controller.dart';
import '../../themes/mycolors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _canResend = true;
  int _countDown = 30;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _authService.resetPassword(_mailController.text.trim());
        _startCountdown();
        toastification.show(
          title: const Text('Password reset email sent', softWrap: true),
          type: ToastificationType.success,
          style: ToastificationStyle.minimal,
          direction: TextDirection.ltr,
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
      } catch (e) {
        toastification.show(
          title: Text('Failed to reset password: $e', softWrap: true),
          type: ToastificationType.error,
          style: ToastificationStyle.minimal,
          direction: TextDirection.ltr,
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _startCountdown() {
    _canResend = false;
    _countDown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countDown > 0) {
        debugPrint("Count : $_countDown");
        _countDown--;
      } else {
        _canResend = true;
        _timer?.cancel();
      }
      setState(() {});
    });
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _mailController.dispose();

    _emailFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenController = Provider.of<ScreenUiController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: IconColor01,
          ),
          onPressed: () {
            screenController.screen = Screen.LoginScreen;
          },
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTitleColor2, AppTitleColor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "Reset password",
            style: GoogleFonts.aDLaMDisplay(
              fontSize: 38,
              color: Colors.white, // Phải là trắng để hiển thị gradient
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Nếu bạn muốn AppBar không nền
        elevation: 0, // Không có bóng nếu bạn thích thiết kế phẳng
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Lottie.asset(
                      'assets/images/reset_password.json',
                      width: 200,
                      height: 200,
                      delegates: LottieDelegates(
                        // Sử dụng values để cung cấp các delegate
                        values: [
                          // Delegate để thay đổi màu sắc
                          ValueDelegate.color(
                            const ['Shape Layer 1', 'Ellipse 1', 'Fill 1'],
                            value: IconColor02, // Giá trị màu sắc muốn áp dụng (từ state)
                          ),
                          // Thêm các ValueDelegate khác nếu cần (ví dụ: opacity, position...)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  Text(
                    "Please enter your email so we can send you a link to reset your password.",
                    style: GoogleFonts.jost(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                      color: TextColor03,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter E-mail';
                      }
                      return null;
                    },
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: IconColor01,
                      ),
                      border: InputBorder.none,
                      hintText: "Email ",
                      hintStyle: TextStyle(color: TextColor01),
                      filled: true,
                      fillColor: _emailFocusNode.hasFocus ? FocusedColor : EnabledBorderColor,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: FocusedBorderColor, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: EnabledBorderColor, width: 1.2),
                      ),
                      errorStyle: TextStyle(color: Color(0xFFE33838)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    controller: _mailController,
                    style: TextStyle(color: TextColor01),
                  ),
                  const SizedBox(height: 40.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canResend ? _resetPassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ButtonColor01,
                        disabledBackgroundColor: DisabledBackgroundColor,
                        disabledForegroundColor: DisableForegroundColor,
                        foregroundColor: TextColor02,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Send Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  if (!_canResend)
                    Center(
                      child: Text(
                        '$_countDown seconds',
                        style: TextStyle(
                          color: ErrorTextColor,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
