import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../cloud_services/auth_service.dart';
import '../../providers/screen_ui_controller.dart';
import '../../themes/mycolors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();

  String name = "", email = "", password = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  void userCreateAccount(BuildContext context) async {
    try {
      await _authService.registerWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
        userName: name.trim(),
        role: "user",
      );
      _formkey.currentState?.reset();
    } catch (e) {
      toastification.show(
        title: Text(e.toString(), softWrap: true),
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        direction: TextDirection.ltr,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {}
  }

  @override
  void dispose() {
    namecontroller.dispose();
    mailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenController = Provider.of<ScreenUiController>(context);

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
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
              "BLE MESH",
              style: GoogleFonts.aDLaMDisplay(
                fontSize: 42,
                color: Colors.white, // Phải là trắng để hiển thị gradient
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent, // Nếu bạn muốn AppBar không nền
          elevation: 0, // Không có bóng nếu bạn thích thiết kế phẳng
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: <Widget>[
                // Title "Login"
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05, top: MediaQuery.of(context).size.height * 0.08),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTitleColor2, AppTitleColor1],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.aDLaMDisplay(
                          fontSize: 42,
                          color: Colors.white, // Phải đặt màu là trắng để hiển thị gradient đúng
                        ),
                      ),
                    ),
                    // width: MediaQuery.of(context).size.width * 0.2,
                  ),
                ),

                // Form
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Form(
                      key: _formkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Input Fields
                          FadeInUp(
                            duration: const Duration(milliseconds: 1800),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FormFieldColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color.fromRGBO(186, 201, 230, 1.0)),
                                boxShadow: const [BoxShadow(color: Color.fromRGBO(143, 148, 251, .2), blurRadius: 20.0, offset: Offset(0, 10))],
                              ),
                              child: Column(
                                children: <Widget>[
                                  // Nickname
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter nickname';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person_2_outlined,
                                        color: IconColor01,
                                      ),
                                      border: InputBorder.none,
                                      hintText: "Name ",
                                      hintStyle: TextStyle(color: TextColor01),
                                      errorStyle: TextStyle(color: ErrorTextColor),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    controller: namecontroller,
                                    style: TextStyle(color: TextColor01),
                                  ),

                                  const Divider(color: TextColor01),

                                  // Email
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter e-mail';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.mail_outline,
                                        color: IconColor01,
                                      ),
                                      border: InputBorder.none,
                                      hintText: "Email ",
                                      hintStyle: TextStyle(color: TextColor01),
                                      errorStyle: TextStyle(color: ErrorTextColor),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    controller: mailcontroller,
                                    style: TextStyle(color: TextColor01),
                                  ),

                                  const Divider(color: TextColor01),

                                  // Password
                                  TextFormField(
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
                                      errorStyle: TextStyle(color: ErrorTextColor),
                                      suffixIconColor: IconColor01,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureText1 ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _obscureText1 = !_obscureText1;
                                          });
                                        },
                                      ),
                                    ),
                                    controller: passwordcontroller,
                                    obscureText: _obscureText1,
                                  ),

                                  const Divider(color: DividerColor01),

                                  // Confirm Password
                                  TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please Enter Password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }

                                      if (value != passwordcontroller.text.trim()) {
                                        return "Password don't match !";
                                      }

                                      return null;
                                    },
                                    style: TextStyle(color: TextColor01),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.lock_outline, color: IconColor01),
                                      border: InputBorder.none,
                                      hintText: "Confirm password",
                                      hintStyle: TextStyle(color: TextColor01),
                                      errorStyle: TextStyle(color: ErrorTextColor),
                                      suffixIconColor: IconColor01,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureText2 ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _obscureText2 = !_obscureText2;
                                          });
                                        },
                                      ),
                                    ),
                                    obscureText: _obscureText2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          ElevatedButton(
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                name = namecontroller.text.trim();
                                email = mailcontroller.text.trim();
                                password = passwordcontroller.text.trim();
                                userCreateAccount(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ButtonColor01,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: ButtonColor01,
                              ),
                              child: const Center(
                                child: Text(
                                  "Sign up",
                                  style: TextStyle(color: TextColor02, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
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
