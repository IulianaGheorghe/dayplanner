import 'package:dayplanner/util/constants.dart';
import 'package:flutter/material.dart';

import '../screens/others/task/tasks_list.dart';
import '../screens/tabs/account.dart';
import '../screens/tabs/calendar.dart';
import '../screens/tabs/home.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int index;

  const MyBottomNavigationBar({super.key, required this.index});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  late int index;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
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

  void handleTabSelection(int selectedIndex) async {
    if (selectedIndex == 1 || selectedIndex == 2) {
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
      const Calendar(),
      const Account(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: screens,
          ),
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
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        currentIndex: index,
        selectedItemColor: primaryColor,
        onTap: handleTabSelection,
      ),
    );
  }
}
