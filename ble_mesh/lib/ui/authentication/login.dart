import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../cloud_functions/auth_service.dart';
import '../../widgets/loading.dart';

class Login extends StatefulWidget {
  final Function toggleView;

  const Login({super.key, required this.toggleView});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();

  String email = "", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscureText = true;

  Future userLogin() async {
    var errorMessage = await _authService.signInWithEmailAndPassword(email: email, password: password);
    setState(() {
      isLoading = false;
    });

    return errorMessage;
  }

  @override
  void dispose() {
    mailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (isLoading)
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/backgrounds/Morning.jpeg'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    // Light-1 Image
                    Align(
                      alignment: Alignment(-0.98, -1),
                      child: FadeInUp(
                        duration: const Duration(seconds: 1),
                        child: Padding(
                          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05, top: MediaQuery.of(context).size.height * 0.08),
                          child: Text(
                            "Welcome Cherish, \n 2nd March, 2025",
                            style: GoogleFonts.imperialScript(
                              fontSize: 26,
                              color: Color(0xFFBDCDE7),
                            ),
                          ),
                          // width: MediaQuery.of(context).size.width * 0.2,
                        ),
                      ),
                    ),

                    // Title "Login"
                    Align(
                      alignment: Alignment(0.05, -0.45),
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50), // Khoảng cách từ trên xuống
                          child: Text(
                            "Login",
                            style: GoogleFonts.italianno(
                              fontSize: 46,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6F6967),
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
                            children: <Widget>[
                              // Input Fields
                              FadeInUp(
                                duration: const Duration(milliseconds: 1800),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0x67FFFFFF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color.fromRGBO(186, 201, 230, 1.0)),
                                    boxShadow: const [BoxShadow(color: Color.fromRGBO(143, 148, 251, .2), blurRadius: 20.0, offset: Offset(0, 10))],
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      TextFormField(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please Enter E-mail';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.mail_outline,
                                            color: Color(0xFF061B36),
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Email ",
                                          hintStyle: TextStyle(color: Color(0xFF061B36)),
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        controller: mailcontroller,
                                        style: TextStyle(color: Color(0xFF061B36)),
                                      ),
                                      const Divider(
                                        color: Color(0xFF061B36),
                                      ),
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
                                        style: TextStyle(color: Color(0xFF061B36)),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF061B36),
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Password",
                                          hintStyle: TextStyle(color: Color(0xFF061B36)),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                        controller: passwordcontroller,
                                        obscureText: _obscureText,
                                      )
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Login Button
                              FadeInUp(
                                duration: const Duration(milliseconds: 1900),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_formkey.currentState!.validate()) {
                                          setState(() {
                                            email = mailcontroller.text.trim();
                                            password = passwordcontroller.text.trim();
                                            isLoading = true;
                                          });
                                          userLogin().then((errorMessage) {
                                            if (errorMessage is String) {
                                              Future.delayed(const Duration(seconds: 3), () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.purple,
                                                    content: Text(
                                                      errorMessage,
                                                      style: const TextStyle(fontSize: 18.0),
                                                    ),
                                                  ),
                                                );
                                              });
                                            } else {
                                              _formkey.currentState!.reset();
                                            }
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 50,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color.fromRGBO(143, 148, 251, 1),
                                              Color.fromRGBO(143, 148, 251, .6),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Login",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 50),
                                    ElevatedButton(
                                      onPressed: () {
                                        widget.toggleView();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent, // Đặt nền trong suốt
                                        shadowColor: Colors.transparent, // Ẩn bóng để tránh đè lên gradient
                                        padding: EdgeInsets.zero, // Xóa padding để nút không bị lệch
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromRGBO(143, 148, 251, 1),
                                              Color.fromRGBO(143, 148, 251, .6),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(maxWidth: 120, maxHeight: 50),
                                          alignment: Alignment.center,
                                          child: Text("Signup", style: TextStyle(color: Colors.white, fontSize: 16)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Forgot Password
                              FadeInUp(
                                duration: const Duration(milliseconds: 2000),
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Color(0xFFFFFFFF)),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Divider(color: Colors.white),
                              Icon(Icons.circle_outlined, size: 48),
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
