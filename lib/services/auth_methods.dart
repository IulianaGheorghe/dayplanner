import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayplanner/services/task_services.dart';
import 'package:dayplanner/util/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../common_widgets/navigationBar.dart';
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
      showSnackBar(context, 'User with same email already exists!', errorColor);
      return;
    }
    if (password != confirmPassword) {
      showSnackBar(context, 'Passwords do not match.', errorColor);
      return;
    }
    if (email.isEmpty || name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showSnackBar(context, 'Please complete all fields.', errorColor);
      return;
    }
    try {
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

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const MyBottomNavigationBar(index: 0)));
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!, errorColor);
    }
  }

  Future<void> handleLogIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    if (email.isEmpty || password.isEmpty) {
      showSnackBar(context, 'Please complete all fields.', errorColor);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const MyBottomNavigationBar(index: 0)));

    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!, errorColor);
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
        showSnackBar(context, 'Password Reset Email Sent', primaryColor);
      } else {
        showSnackBar(context, 'Email is not valid', errorColor);
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!, errorColor);
    }
  }
}

