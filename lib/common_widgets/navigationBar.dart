import 'package:dayplanner/util/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/others/task/tasks_list.dart';
import '../screens/tabs/account.dart';
import '../screens/tabs/calendar.dart';
import '../screens/tabs/friends.dart';
import '../screens/tabs/home.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int index;
  final DateTime? selectedCalendarDate;

  const MyBottomNavigationBar({super.key, required this.index, this.selectedCalendarDate});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  String userID = '';
  late int index;
  bool isLoading = false;
  DateTime _selectedCalendarDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.selectedCalendarDate != null) {
      _selectedCalendarDay = widget.selectedCalendarDate!;
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    userID = currentUser!.uid;
    index = widget.index;
  }

  Future<void> waitForTaskDeletion() async {
    if (isTaskDeleting) {
      setState(() {
        isLoading = true;
      });
      await Future.delayed(const Duration(seconds: 2));
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleTabSelection(int selectedIndex) async{
    if (selectedIndex == 1 || selectedIndex == 3) {
      await waitForTaskDeletion();
    }
    if (mounted) {
      setState(() {
        index = selectedIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const Home(),
      Calendar(selectedDay: _selectedCalendarDay),
      const Friends(),
      Account(userID: userID),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          screens[index],
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        currentIndex: index,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        unselectedLabelStyle: TextStyle(color: Colors.grey.shade600),
        onTap: handleTabSelection,
      ),
    );
  }
}