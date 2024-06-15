import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common_widgets/navigationBar.dart';
import '../../../common_widgets/showSnackBar.dart';
import '../../../services/auth_methods.dart';
import '../../../services/user_services.dart';
import '../../../util/constants.dart';


class EditProfile extends StatefulWidget{
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile>{
  String currentUserID = '';
  String userName = "";
  String userEmail = "";
  String userPassword = "";
  String userPhoto = "";
  bool showPassword = true;
  File? _imageFile;
  String? oldProfileImageUrl;

  late Future<Map<String, String>> fetchDetails;

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();
  UserServices userServices = UserServices();

  @override
  void initState() {
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    currentUserID = currentUser!.uid;

    _getUserDetails();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    String userID = await userServices.getUserId();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userID).get();
    setState(() {
      oldProfileImageUrl = userDoc['photo'];
    });
  }

  void _getUserDetails() async {
    fetchDetails = userServices.getUserDetails(currentUserID);
    Map<String, String> userDetails = await userServices.getUserDetails(currentUserID);
    setState(() {
      userName = userDetails['userName']!;
      userEmail = userDetails['userEmail']!;
      userPhoto = userDetails['userPhoto']!;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
    else
    {
      showSnackBar(context, 'Image not added!', errorColor);
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (oldProfileImageUrl!.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(oldProfileImageUrl!).delete();
      }

      String userID = await userServices.getUserId();
      final profilePicID = DateTime.now().millisecondsSinceEpoch.toString();
      final storageReference = FirebaseStorage.instance.ref().child('$userID/profile').child("post_$profilePicID");
      await storageReference.putFile(_imageFile!);
      final downloadUrl = await storageReference.getDownloadURL();
      setState(() {
        userPhoto = downloadUrl;
      });
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  bool _isLoading = false;

  void saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    if( _imageFile != null) {
      await _uploadImage();
    }
    User? user = FirebaseAuth.instance.currentUser;
    String userID = await userServices.getUserId();
    try {
      if (_imageFile != null ) {
        await userServices.updatePhotoURL(userID, userPhoto);
      }
      if (userPassword != "") {
        user?.updatePassword(userPassword);
      }
      if (userName != '') {
        await userServices.updateUsername(userID, userName);
      }
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyBottomNavigationBar(index: 3)),
      );
    } catch (e) {
      throw Exception('Error updating account details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: Colors.black,
          ),
          backgroundColor: profilePageColor,
          centerTitle: true,
          title: const Text('Edit Profile',
            style: TextStyle(
                fontFamily: font1,
                fontSize: 23,
                color: Colors.black
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/t.jpg',
              fit: BoxFit.cover,
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverFillRemaining(
                  child: FutureBuilder<Map<String, String>>(
                    future: fetchDetails,
                    builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor:AlwaysStoppedAnimation<Color>(profilePageColor),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        return buildProfile();
                      } else {
                        return const Text('No data available');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildProfile(){
    ImageProvider<Object> imageShowed;
    if(_imageFile == null)
    {
      imageShowed = NetworkImage(userPhoto);
    } else {
      imageShowed = FileImage(_imageFile!);
      userPhoto = 'photo';
    }

    return Container(
      padding: const EdgeInsets.only(top: 20, left: 16, bottom: 25, right: 16),
      child: ListView(
        children: [
          Center(
            child: Stack(
              children: [
                InkWell(
                  child: userPhoto == ""
                      ? Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 4,
                            color: Theme.of(context).scaffoldBackgroundColor),
                        boxShadow: [
                          BoxShadow(
                              spreadRadius: 2,
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 10))
                        ],
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage('assets/images/user.png'))),
                  )
                      : Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 4,
                            color: Theme.of(context).scaffoldBackgroundColor),
                        boxShadow: [
                          BoxShadow(
                              spreadRadius: 2,
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 10))
                        ],
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: imageShowed)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        _pickImage();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              userEmail,
              style: const TextStyle(
                fontFamily: font1,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            decoration: InputDecoration(
              labelStyle: const TextStyle(color: primaryColor),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              labelText: 'Name',
              hintText: userName,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: const TextStyle( fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            onChanged: (value) {
              setState(() {
                userName = value;
              });
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            obscureText: showPassword,
            decoration: InputDecoration(
              labelStyle: const TextStyle(color: primaryColor),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.grey,
                ),
              ),
              labelText: 'Enter new password',
              hintText: userPassword,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintStyle: const TextStyle( fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            onChanged: (value) {
              setState(() {
                userPassword = value;
              });
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2.5,
                height: 50,
                child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:AlwaysStoppedAnimation<Color>(profilePageColor),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor
                      ),
                      onPressed: () {
                        saveChanges();
                      },
                      child: const Text(
                        'Save changes',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: font1
                        ),
                      ),
                    ),
              ),
            ],
          )
        ],
      ),
    );
  }
}