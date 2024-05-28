import 'package:dayplanner/util/constants.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    index = widget.index;
  }

  final screens = [
    const Home(),
    const Calendar(),
    const Account(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
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
        onTap: (selectedIndex) =>
            setState(() => index = selectedIndex),
      ),
    );
  }
}