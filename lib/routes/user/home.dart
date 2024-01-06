import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/constants.dart';

class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    String formattedDate = DateFormat('EEEE, d MMMM').format(currentDate);

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/t2.jpg',
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(25, 40, 25, 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Plan',
                        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, fontFamily: font1),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 20, fontFamily: font2),
                      ),

                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {

                    },
                    style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        fixedSize: const Size(130.0, 50.0),
                        textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold
                        ),
                        side: const BorderSide(color: buttonBorderColor, width: 1),
                        backgroundColor: primaryColor,
                        foregroundColor: buttonTextColor,
                        elevation: 10
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.add_circle,
                          color: Colors.black,
                          size: 30.0,
                        ),
                        Text(' New Task'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}