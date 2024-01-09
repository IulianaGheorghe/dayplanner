import 'package:dayplanner/routes/user/tasks_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../util/constants.dart';
import 'add_task.dart';

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
              child: Column (
                children: [
                  Row(
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
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const AddTask()));
                        },
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            fixedSize: const Size(141.0, 55.0),
                            textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold
                            ),
                            side: const BorderSide(color: buttonBorderColor, width: 1),
                            backgroundColor: primaryColor,
                            foregroundColor: buttonTextColor,
                            elevation: 10
                        ),
                        child: const Row(
                          children: [
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
                  const SizedBox(height: 20), // Add some spacing between the button and task list
                  Expanded(
                    child: TasksList(), // Include the TasksList widget here
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