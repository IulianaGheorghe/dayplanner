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

  Future<Map<String, String>> getNameEmailPhoto(String userID) async {
    DocumentSnapshot userSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .get();

    String name;
    String email;
    String photo;
    if (userSnapshot.exists) {
      name = userSnapshot.get('name');
      email = userSnapshot.get('email');
      photo = userSnapshot.get('photo');
    } else {
      throw Exception('User does not exist');
    }
    return {
      'name': name,
      'email': email,
      'photo': photo,
    };
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

  Future<Map<String, String>> getUserDetails(String userID) async {
    try {
      Map<String, String> nameEmailPhoto = await getNameEmailPhoto(userID);
      String name = nameEmailPhoto['name']!;
      String email = nameEmailPhoto['email']!;
      String photo = nameEmailPhoto['photo']!;
      String userIdField = await getIdFieldForUser(userID);

      return {
        'userIdField': userIdField,
        'userName': name,
        'userEmail': email,
        'userPhoto': photo,
      };
    } catch (e) {
      throw Exception('Error getting details for user $userID: $e');
    }
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

  Future<bool> isFriendIdValid(String friendID) async {
    try {
      QuerySnapshot friendSnapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: friendID)
        .limit(1)
        .get();
      return friendSnapshot.size > 0
        ? true
        : false;
    } catch (e) {
      throw Exception('Error checking friendID: $e');
    }
  }

  Future<void> addFriend(String friendID) async {
    User? currentUser = _auth.currentUser;
    try {
      QuerySnapshot friendSnapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: friendID)
          .limit(1)
          .get();
      String dbIdForFriend = friendSnapshot.docs.first.id;

      await _firestore.collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .add({
          'id': dbIdForFriend,
        });

      await _firestore.collection('users')
        .doc(dbIdForFriend)
        .collection('friends')
        .add({
          'id': currentUser.uid,
        });
    } catch (e) {
      throw Exception('Error adding friend: $e');
    }
  }

  Future<Map<String, String>> getDetailsForFriend(String userID) async {
    try {
      DocumentSnapshot friendSnapshot = await _firestore
          .collection('users')
          .doc(userID)
          .get();

      String name = friendSnapshot['name'];
      String photo = friendSnapshot['photo'];
      String uid = friendSnapshot.id;
      Map<String, String> friendDetails = {
        'uid': uid,
        'name': name,
        'photo': photo
      };

      return friendDetails;
    } catch (e) {
      throw Exception('Error getting name and photo for friend $userID: $e');
    }
  }

  Future<List<Map<String, String>>> getFriends() async {
    User? currentUser = _auth.currentUser;
    try {
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .get();

      List<dynamic> friendsIDs = friendsSnapshot.size > 0
          ? friendsSnapshot.docs.map((doc) => doc['id']).toList()
          : [];
      
      List<Map<String, String>> friendsDetails = [];
      for (var friendID in friendsIDs) {
        var friendNameAndPhoto = await getDetailsForFriend(friendID);
        friendsDetails.add(friendNameAndPhoto);
      }

      return friendsDetails;
    } catch (e) {
      throw Exception('Error getting friends IDs for ${currentUser!.uid}: $e');
    }
  }

  Future<void> deleteFriend(String friendUID) async {
    User? currentUser = _auth.currentUser;
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('friends')
          .where('id', isEqualTo: friendUID)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }

      QuerySnapshot querySnapshot2 = await _firestore
          .collection('users')
          .doc(friendUID)
          .collection("friends")
          .where('id', isEqualTo: currentUser.uid)
          .get();

      if (querySnapshot2.docs.isNotEmpty) {
        for (var doc in querySnapshot2.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      throw Exception('Error deleting friend: $e');
    }
  }
}