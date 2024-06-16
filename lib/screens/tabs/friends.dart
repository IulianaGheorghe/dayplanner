import 'package:dayplanner/common_widgets/showSnackBar.dart';
import 'package:dayplanner/util/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_services.dart';
import 'account.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  String userID = '';
  List<Map<String, String>> friendsDetails = [];
  UserServices userServices = UserServices();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;

    getFriendsDetails();
  }

  void getFriendsDetails() async {
    setState(() {
      isLoading = true;
    });

    friendsDetails = await userServices.getFriends();

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> _isValidID(String id) async {
    return await userServices.isFriendIdValid(id);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: friendsPageColor,
          centerTitle: true,
          title: const Text(
            'Friends',
            style: TextStyle(
              fontFamily: font1,
              fontSize: 23,
              color: Colors.black,
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/b2.png',
              fit: BoxFit.cover,
            ),
            isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor:AlwaysStoppedAnimation<Color>(profilePageColor),
                ),
              )
              : _friendsListWidget(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddIdDialog(context);
          },
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: const Icon(
            Icons.add,
            size: 33,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _friendsListWidget() {
    return friendsDetails.isNotEmpty
        ? ListView.builder(
      itemCount: friendsDetails.length,
      itemBuilder: (context, index) {
        final friend = friendsDetails[index];
        return Column(children: [
          const SizedBox(height: 30),
          Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      "Confirm Deletion",
                      style: TextStyle(
                        fontFamily: font1
                      ),
                    ),
                    content: const Wrap(
                      children: [
                        Text(
                          "Are you sure you want to delete this friend?",
                          style: TextStyle(
                            fontSize: 18
                          ),
                        ),
                        Text(
                          "He won't be able to see your progress either.",
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: primaryColor
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                              color: primaryColor
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) async {
              setState(() {
                friendsDetails.removeAt(index);
              });
              showSnackBar(context, "Friend successfully deleted", primaryColor);
              await userServices.deleteFriend(friend['uid']!);
            },
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                    MaterialPageRoute(builder: (context) => Account(userID: friend['uid']!)),
                  );
                },
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(15),
                height: 125,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.cyan.shade700,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: (friend['photo'] == '')
                            ? const AssetImage('assets/images/user.png')
                        as ImageProvider
                            : NetworkImage(friend['photo']!),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      friend['name']!,
                      style: const TextStyle(
                        color: buttonTextColor,
                        fontSize: 30,
                        fontFamily: font1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]);
      },
    )
        : Container(
      padding: const EdgeInsets.all(40.0),
      margin: const EdgeInsets.only(
          left: 70, right: 70, top: 185, bottom: 190),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        children: [
          Expanded(
            child: Text(
              "You don't have any friends yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                  fontFamily: font1),
            ),
          ),
          Expanded(
            child: Text(
              "Add a friend to see their progress and motivate each other ",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 18,
                  fontFamily: font1),
            ),
          ),
          Expanded(
              child: Icon(
                Icons.sentiment_very_satisfied,
                size: 50,
                color: Colors.blue.shade800,
              )),
        ],
      ),
    );
  }

  void _showAddIdDialog(BuildContext context) {
    TextEditingController idController = TextEditingController();
    String? localErrorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text(
                'Add friend ID',
                style: TextStyle(fontFamily: font1),
              ),
              content: TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter ID',
                  errorText: localErrorMessage,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    String friendId = idController.text;
                    bool isValid = await _isValidID(friendId);
                    if (friendId.isEmpty || !isValid) {
                      setState(() {
                        localErrorMessage = 'The ID is not valid.';
                      });
                    } else {
                      await userServices.addFriend(friendId);
                      showSnackBar(context, "Friend successfully added", primaryColor);
                      setState(() {
                        localErrorMessage = null;
                      });
                      getFriendsDetails();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
