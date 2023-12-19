import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../util/showSnackBar.dart';

class FirebaseAuthMethods {

  Future<bool> doesUserExist(String email) async {
    final users = FirebaseFirestore.instance.collection('users');
    final userSnapshot = await users.where('email', isEqualTo: email).get();
    if (userSnapshot.docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> handleSignUp({
    required String name,
    required String email,
    required String password,
    required String confirmpassword,
    required BuildContext context,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    if (await doesUserExist(email)) {
      showSnackBar(context, 'An user with same email already exists!');
      throw Exception('An user with same email already exists!');
    } else {
      try {
        if (password != confirmpassword) {
          throw Exception('Passwords do not match.');
        }
        if (email == '' || name == '' || password == '') {
          throw Exception('Field cannot be empty.');
        }
        final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        FirebaseFirestore.instance
            .collection('users')
            .doc(credentials.user?.uid)
            .set({
          'name': name,
          'email': email
        });
      } catch (e) {
        showSnackBar(context, '$e');
        throw Exception('Failed to create user: $e');
      }
    }
  }

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

