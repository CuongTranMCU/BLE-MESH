import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../cloud_functions/auth_service.dart';
import '../../widgets/loading.dart';

class Signup extends StatefulWidget {
  final Function toggleView;

  const Signup({super.key, required this.toggleView});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final AuthService _authService = AuthService();

  String name = "", email = "", password = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  Future userCreateAccount() async {
    var errorMessage = await _authService.registerWithEmailAndPassword(email: email, password: password, userName: name, role: "user");
    setState(() {
      isLoading = false;
    });

    return errorMessage;
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
                            "Signup",
                            style: GoogleFonts.italianno(
                              fontSize: 42,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6F6967),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Form
                    Align(
                      alignment: const Alignment(0, 0.9),
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
                                      // Nickname
                                      TextFormField(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter nickname';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.person_2_outlined,
                                            color: Color(0xFF061B36),
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Name ",
                                          hintStyle: TextStyle(color: Color(0xFF061B36)),
                                          errorStyle: TextStyle(color: Color(0xFFE33838)),
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        controller: namecontroller,
                                        style: TextStyle(color: Color(0xFF061B36)),
                                      ),

                                      const Divider(color: Color(0xFF061B36)),

                                      // Email
                                      TextFormField(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter e-mail';
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
                                          errorStyle: TextStyle(color: Color(0xFFE33838)),
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        controller: mailcontroller,
                                        style: TextStyle(color: Color(0xFF061B36)),
                                      ),

                                      const Divider(color: Color(0xFF061B36)),

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
                                        style: TextStyle(color: Color(0xFF061B36)),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF061B36),
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Password",
                                          hintStyle: TextStyle(color: Color(0xFF061B36)),
                                          errorStyle: TextStyle(color: Color(0xFFE33838)),
                                          suffixIconColor: Color(0xFF061B36),
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

                                      const Divider(color: Color(0xFF061B36)),

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
                                        style: TextStyle(color: Color(0xFF061B36)),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF061B36),
                                          ),
                                          border: InputBorder.none,
                                          hintText: "Confirm password",
                                          hintStyle: TextStyle(color: Color(0xFF061B36)),
                                          errorStyle: TextStyle(color: Color(0xFFE33838)),
                                          suffixIconColor: Color(0xFF061B36),
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
                                    setState(() {
                                      name = namecontroller.text.trim();
                                      email = mailcontroller.text.trim();
                                      password = passwordcontroller.text.trim();
                                      isLoading = true;
                                    });
                                    userCreateAccount().then((errorMessage) {
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // Đặt nền trong suốt
                                  shadowColor: Colors.transparent, // Ẩn bóng để tránh đè lên gradient
                                  padding: EdgeInsets.zero, // Xóa padding để nút không bị lệch
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(143, 148, 251, 1),
                                      Color.fromRGBO(143, 148, 251, .6),
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: 150, maxHeight: 50),
                                    alignment: Alignment.center,
                                    child: Text("Signup", style: TextStyle(color: Colors.white, fontSize: 16)),
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
