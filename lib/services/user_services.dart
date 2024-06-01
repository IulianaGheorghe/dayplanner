import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserServices{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserId() async {
    String? userID;
    final user = _auth.currentUser;
    userID = user!.uid;

    return userID;
  }

  Future<String> getName(String email) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User does not exist!');
    }
    DocumentSnapshot userSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    String name;
    if (userSnapshot.exists) {
      name = userSnapshot.get('name');
    } else {
      throw Exception('User does not exist');
    }
    return name;
  }

  Future<String> getPhoto(String email) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User does not exist!');
    }
    DocumentSnapshot userSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    String photo;
    if (userSnapshot.exists) {
      photo = userSnapshot.get('photo');
    } else {
      throw Exception('User does not exist');
    }
    return photo;
  }

  Future<void> updatePhotoURL(String userId, String newPhotoURL) async {
    FirebaseFirestore firestore = _firestore;
    DocumentReference docRef = firestore.collection('users').doc(userId);
    try {
      await docRef.update({
        'photo': newPhotoURL,
      });
    } catch (error) {
      Exception('Error updating photo URL: $error');
    }
  }

  Future<void> updateUsername(String userId, String newUsername) async {
    FirebaseFirestore firestore = _firestore;
    DocumentReference docRef = firestore.collection('users').doc(userId);
    try {
      await docRef.update({
        'name': newUsername,
      });
    } catch (e) {
      Exception('Error updating username: $e');
    }
  }

  Future<String> getIdFieldForUser(String userID) async {
    try {
      DocumentSnapshot userSnapshot = await _firestore
          .collection('users')
          .doc(userID)
          .get();

      String idField = userSnapshot.get('id');
      return idField;
    } catch (e) {
      throw Exception('Error getting id field for user $userID: $e');
    }
  }

  Future<Map<String, String>> getUserDetails() async {
    User? user = _auth.currentUser;
    String? email = user?.email;
    if (email != null) {
      String userIdField = await getIdFieldForUser(user!.uid);
      String name = await getName(email) ;
      String photo = await getPhoto(email);
      return {
        'userIdField': userIdField,
        'userName': name,
        'userEmail': email,
        'userPhoto': photo,
      };
    }
    return {};
  }

  Future<void> updateProfileDetails(File? imageFile, String userPhoto, String userPassword, String userName) async {
    User? user = _auth.currentUser;
    String userID = await getUserId();
    try {
      if (imageFile != null ) {
        await updatePhotoURL(userID, userPhoto);
      }
      if (userPassword != "") {
        user?.updatePassword(userPassword);
      }
      if (userName != '') {
        await updateUsername(userID, userName);
      }
    } catch (e) {
      throw Exception('Error updating account details: $e');
    }
  }
}