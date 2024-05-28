import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_methods.dart';
import '../../util/constants.dart';
import '../others/profile/edit_profile.dart';

class Account extends StatefulWidget{
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account>{
  String userName = "";
  String userEmail = "";
  String userPassword = "";
  String userPhoto = "";
  bool showPassword = true;
  File? _imageFile;

  late Future<Map<String, String>> fetchDetails;

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();

  @override
  void initState() {
    super.initState();
    fetchDetails = _getUserDetails();
  }

  Future<Map<String, String>> _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;
    if (email != null) {
      String name = await authMethods.getName(email) ;
      String photo = await authMethods.getPhoto(email);
      setState(() {
        userName = name;
        userEmail = email;
        userPhoto = photo;
      });
      return {
        'userName': name,
        'userEmail': email,
        'userPhoto': photo,
      };
    }
    return {};
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
          backgroundColor: profilePageColor,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Edit profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfile()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'Edit profile',
                    child: Text('Edit profile')
                  ),
                ];
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
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
      padding: const EdgeInsets.only(left: 16, bottom: 25, right: 16),
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              userName,
              style: const TextStyle(
                fontFamily: font1,
                fontSize: 25,
              ),
            ),
          ),
          const SizedBox(height: 5),
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

        ],
      ),
    );
  }
}