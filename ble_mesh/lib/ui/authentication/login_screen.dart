import 'package:ble_mesh/ui/wifi/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../cloud_services/auth_service.dart';
import '../../providers/screen_ui_controller.dart';
import '../../themes/mycolors.dart';
import '../../widgets/loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  String email = "", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool _obscureText = true;

// Separate focus nodes for each TextField
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool isLoading = false;

  Future<String?> userLogin() async {
    try {
      return await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    mailcontroller.dispose();
    passwordcontroller.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenController = Provider.of<ScreenUiController>(context);

    return (isLoading)
        ? Loading()
        : Scaffold(
            backgroundColor: BackgroundColor,
            body: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment(0, -0.9),
                      child: Padding(
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05, top: MediaQuery.of(context).size.height * 0.08),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTitleColor2, AppTitleColor1],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            "BLE MESH",
                            style: GoogleFonts.aDLaMDisplay(
                              fontSize: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Title "Login"
                    Align(
                      alignment: Alignment(-1, -0.3),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50), // Khoảng cách từ trên xuống
                            child: Text(
                              "Login to Account",
                              style: GoogleFonts.arima(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppTitleColor2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Form
                    Align(
                      alignment: const Alignment(0, 0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              // Input Fields
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
                                  errorStyle: const TextStyle(color: ErrorTextColor),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                controller: mailcontroller,
                                style: TextStyle(color: TextColor01),
                              ),

                              SizedBox(height: 20),

                              TextFormField(
                                focusNode: _passwordFocusNode,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: TextColor01),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: IconColor01,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "Password",
                                  hintStyle: TextStyle(color: TextColor01),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText ? Icons.visibility_off : Icons.visibility,
                                      color: IconColor01,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: _passwordFocusNode.hasFocus ? FocusedColor : EnabledBorderColor,
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
                                controller: passwordcontroller,
                                obscureText: _obscureText,
                              ),

                              const SizedBox(height: 40),

                              // Login Button
                              GestureDetector(
                                onTap: () {
                                  if (_formkey.currentState!.validate()) {
                                    email = mailcontroller.text.trim();
                                    password = passwordcontroller.text.trim();
                                    setState(() {
                                      isLoading = true;
                                    });
                                    userLogin().then((errorMessage) {
                                      if (errorMessage != null) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        toastification.show(
                                          title: Text(errorMessage, softWrap: true),
                                          type: ToastificationType.error,
                                          style: ToastificationStyle.minimal,
                                          direction: TextDirection.ltr,
                                          alignment: Alignment.topCenter,
                                          autoCloseDuration: const Duration(seconds: 3),
                                        );
                                      } else {
                                        if (_formkey.currentState != null) {
                                          _formkey.currentState!.reset();
                                        } else {
                                          print("Error: _formkey.currentState is null");
                                        }
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: ButtonColor01,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Sign in",
                                      style: TextStyle(color: TextColor02, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 50),

                              FadeInUp(
                                duration: const Duration(milliseconds: 2000),
                                //  giúp các phần tử trong Row có cùng chiều cao tối thiểu cần thiết
                                child: IntrinsicHeight(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          screenController.screen = Screen.ResetPasswordScreen;
                                        },
                                        child: const Text(
                                          "Forget password",
                                          style: TextStyle(
                                            color: TextColor01,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(color: DividerColor01, width: 20, thickness: 2),
                                      InkWell(
                                        onTap: () {
                                          screenController.screen = Screen.SignupScreen;
                                        },
                                        child: const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            color: TextColor03,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),
                              Padding(
                                padding: const EdgeInsets.only(left: 90, right: 90),
                                child: Divider(color: DividerColor01, thickness: 1.5),
                              ),
                              IconButton(
                                  onPressed: () {},
                                  icon: Image.asset(
                                    'assets/icons/google.png',
                                    height: 32,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}
