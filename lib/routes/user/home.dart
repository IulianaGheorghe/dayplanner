import 'package:dayplanner/util/navigationBar.dart';
import 'package:flutter/material.dart';
import '../../util/constants.dart';

class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(

        ),
      bottomNavigationBar: MyBottomNavigationBar(),
    );
  }
}