import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_methods.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';
import 'log_in.dart';

class SignUp extends StatefulWidget{
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUp();
}

class _SignUp extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  String nameController = '';
  String emailController = '';
  String passwordController = '';
  String confirmPasswordController = '';

  void _handleSignUp() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      FirebaseAuthMethods authService = FirebaseAuthMethods();
      try {
        await authService.handleSignUp(
          name: nameController,
          email: emailController,
          password: passwordController,
          confirmPassword: confirmPasswordController,
          context: context,
        );
      } catch (e) {
        throw Exception('Error creating the user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primaryColor,
        body: SingleChildScrollView(
            child: Container(
                alignment: Alignment.center,
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
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
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                                child: const Text(
                                  'Sign Up into your account',
                                  style: TextStyle(color: secondColor,
                                      fontSize: pageSizeName,
                                      fontFamily: font1),
                                ),
                              ),
                              const SizedBox(height: boxDataSize),
                              Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: Box()
                                            .inputBoxDecorationShadow(),
                                        child: TextFormField(
                                          cursorColor: inputDecorationColor,
                                          decoration: Box().textInputDecoration(
                                              'Name', 'Enter your name'),
                                          onSaved: (value) {
                                            nameController = value ?? '';
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: boxDataSize),
                                      Container(
                                        decoration: Box()
                                            .inputBoxDecorationShadow(),
                                        child: TextFormField(
                                          cursorColor: inputDecorationColor,
                                          decoration: Box().textInputDecoration(
                                              'E-mail', 'Enter your e-mail'),
                                          onSaved: (value) {
                                            emailController = value ?? '';
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: boxDataSize),
                                      Container(
                                        decoration: Box()
                                            .inputBoxDecorationShadow(),
                                        child: TextFormField(
                                          cursorColor: inputDecorationColor,
                                          obscureText: true,
                                          decoration: Box().textInputDecoration(
                                              'Password', 'Enter your password'),
                                          onSaved: (value) {
                                            passwordController = value ?? '';
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: boxDataSize),
                                      Container(
                                        decoration: Box()
                                            .inputBoxDecorationShadow(),
                                        child: TextFormField(
                                          obscureText: true,
                                          decoration: Box().textInputDecoration(
                                              'Repeat Password',
                                              'Repeat your password'),
                                          onSaved: (value) {
                                            confirmPasswordController = value ?? '';
                                          },
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
                      onPressed: _handleSignUp,
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          fixedSize: const Size(buttonWidth, buttonHeight),
                          textStyle: const TextStyle(fontSize: buttonText, fontWeight: FontWeight.bold),
                          side: const BorderSide(color: buttonTextColor, width: 2),
                          backgroundColor: secondColor,
                          foregroundColor: buttonTextColor,
                          elevation: 15
                      ),
                      child: const Text("Sign Up"),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      margin: const EdgeInsets.fromLTRB(0, marginSize/2, marginSize, marginSize),
                      child: Text.rich(
                          TextSpan(
                              children: [
                                TextSpan(
                                  text: "\nAlready have an account? ",
                                  style: const TextStyle(color: questionTextColor,
                                      fontSize: questionSize,
                                      fontFamily: font2),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => const LogIn()));
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