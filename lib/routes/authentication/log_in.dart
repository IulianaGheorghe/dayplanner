import 'package:dayplanner/routes/authentication/reset_password.dart';
import 'package:dayplanner/routes/authentication/sign_up.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../util/components.dart';
import '../../util/constants.dart';

class LogIn extends StatefulWidget{
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn>{
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primaryColor,
        body: SingleChildScrollView(
            child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Image(image: AssetImage(todoPattern2)),
                    SafeArea(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          margin: const EdgeInsets.fromLTRB(marginSize, marginSize, marginSize, marginSize),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(20,0,0,0),
                                child: Container(
                                    margin: const EdgeInsets.fromLTRB(0,0,marginSize,0),
                                    child: const Text(
                                      'Log In into your account',
                                      style: TextStyle(color: secondColor, fontSize: pageSizeName, fontFamily: font1),
                                    ),
                                ),
                              ),
                              const SizedBox(height: boxDataSize),
                              Form(
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: Box().inputBoxDecorationShadow(),
                                        child: TextField(
                                          key: const Key("emailField"),
                                          controller: emailController,
                                          decoration: Box().textInputDecoration('E-mail', 'Enter your e-mail'),
                                        ),
                                      ),
                                      const SizedBox(height: boxDataSize),
                                      Container(
                                        decoration: Box().inputBoxDecorationShadow(),
                                        child: TextField(
                                          key: const Key("passwordField"),
                                          controller: passwordController,
                                          obscureText: true,
                                          decoration: Box().textInputDecoration('Password', 'Enter your password'),
                                        ),
                                      ),
                                    ],
                                  )
                              )
                            ],
                          ),
                        )
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key("logInButton"),
                      onPressed: () async {
                        // try {
                        //   String role = await _handleLogIn();
                        //     Navigator.push(context,
                        //         MaterialPageRoute(builder: (context) => Home()));
                        // } catch (e) {
                        //   showSnackBar(context, 'User does not exist: $e');
                        // }
                      },
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          fixedSize: const Size(buttonWidth, buttonHeight),
                          textStyle: const TextStyle(
                              fontSize: buttonText,
                              fontWeight: FontWeight.bold
                          ),
                          side: const BorderSide(color: buttonTextColor, width: 2),
                          backgroundColor: secondColor,
                          foregroundColor: buttonTextColor,
                          elevation: 15
                      ),
                      child: const Text("Log In"),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      margin: const EdgeInsets.fromLTRB(0,marginSize*3,marginSize, marginSize),
                      child: Text.rich(
                          TextSpan(
                              children: [
                                TextSpan(
                                  text: "\nForgot Password? ",
                                  style: const TextStyle(color: questionTextColor, fontSize: questionSize, fontFamily: font2),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPassword()));
                                    },
                                ),
                                TextSpan(
                                  text: "\nDon't have an account? ",
                                  style: const TextStyle(color: questionTextColor, fontSize: questionSize, fontFamily: font2),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp()));
                                    },
                                ),
                              ]
                          )
                      ),

                    )
                  ],
                )
            )
        )
    );
  }
}