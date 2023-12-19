import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../util/showSnackBar.dart';

class FirebaseAuthMethods {

  Future<void> handleLogIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
      throw Exception('User does not exist!');
    }
  }

}

