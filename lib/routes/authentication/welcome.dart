import 'dart:async';
import 'package:dayplanner/routes/authentication/sign_up.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';
import 'log_in.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(todoPattern1),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 170, 0),
                child: Text("Day",
                    style: TextStyle(
                      fontSize: titleSize,
                      fontFamily: font1,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3.0
                        ..color = Colors.black,)
                )
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(marginSize*6,0,50,0),
                  child: Text("Planner",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontFamily: font1,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3.0
                          ..color = Colors.black,)
                  )
              ),
              const SizedBox(height: 150),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LogIn()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    fixedSize: const Size(buttonWidth, buttonHeight),
                    textStyle: const TextStyle(
                        fontSize: buttonText,
                        fontWeight: FontWeight.bold
                    ),
                    side: const BorderSide(color: buttonBorderColor, width: 2),
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    elevation: 15
                ),
                child: const Text("Log in"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SignUp()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    fixedSize: const Size(buttonWidth, buttonHeight),
                    textStyle: const TextStyle(
                        fontSize: buttonText,
                        fontWeight: FontWeight.bold
                    ),
                    side: const BorderSide(color: buttonBorderColor, width: 2),
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    elevation: 15
                ),
                child: const Text("Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}