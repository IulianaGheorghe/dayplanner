import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayplanner/services/task_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../common_widgets/showSnackBar.dart';

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
    required String confirmPassword,
    required BuildContext context,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    if (await doesUserExist(email)) {
      showSnackBar(context, 'An user with same email already exists!');
      throw Exception('An user with same email already exists!');
    } else {
      try {
        if (password != confirmPassword) {
          throw Exception('Passwords do not match.');
        }
        if (email == '' || name == '' || password == '') {
          throw Exception('Field cannot be empty.');
        }

        String randomUserId = nanoid(10);

        final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        FirebaseFirestore.instance
          .collection('users')
          .doc(credentials.user?.uid)
          .set({
            'name': name,
            'email': email,
            'id': randomUserId,
            'photo': ''
          });

        addInitialCategories(credentials.user!.uid);
      } catch (e) {
        showSnackBar(context, e.toString());
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

  Future<void> handleResetPassword({
    required String email,
    required BuildContext context,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    try {
      if (await doesUserExist(email)) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        showSnackBar(context, 'Password Reset Email Sent');
      } else {
        showSnackBar(context, 'Email is not valid');
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }
}

