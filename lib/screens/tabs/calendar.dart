import 'package:dayplanner/util/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/task_services.dart';

class Calendar extends StatefulWidget{
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar>{

  String userID = '';
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, int> _tasksCount = {}; // Map to store number of tasks for each day
  Map<DateTime, List<Task>> _tasksByDate = {}; // Map to store tasks grouped by date

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;
    fetchTasksForTimeFrame(DateTime.now(), DateTime.now().add(Duration(days: 30)));
  }

  // Fetch tasks for a specific time frame and group them by date
  Future<void> fetchTasksForTimeFrame(DateTime startDate, DateTime endDate) async {
    // Fetch tasks from database within the specified time frame
    // List<Task> tasks = await getTasksForTimeFrame(startDate, endDate, userID);

    // Group tasks by date
    _tasksByDate.clear();
    // tasks.forEach((task) {
    //   final date = task.date;
    //   _tasksByDate.update(date, (value) => value + [task], ifAbsent: () => [task]);
    // });

    // Calculate task counts for each date
    _tasksCount.clear();
    _tasksByDate.forEach((date, tasks) {
      _tasksCount[date] = tasks.length;
    });

    setState(() {}); // Update the UI
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/b3.png',
                fit: BoxFit.cover,
              ),
              SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Container(
                          color: Colors.white.withOpacity(0.9),
                          child: TableCalendar(
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>isSameDay(day, _selectedDay),
                            firstDay: DateTime.utc(2020, 10, 16),
                            lastDay: DateTime.utc(2030, 12, 30),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.yellow.shade600,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle
                              ),
                              todayTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0,
                                color: Colors.black,
                              ),
                              selectedTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0,
                                color: Colors.black,
                              ),
                            ),
                            calendarFormat: _calendarFormat,
                            onFormatChanged: (format) {
                              if (_calendarFormat != format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              }
                            },
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final tasksCount = _tasksCount[date];
                                return Positioned(
                                  right: 1,
                                  top: -6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 18,
                                    height: 18,
                                    child: Center(
                                      child: Text(
                                        tasksCount != null ? '$tasksCount' : '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<Task>>(
                          future: getTasksForDay(_selectedDay, userID),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text(
                                'There are no tasks for this day.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                ),
                              ));
                            } else {
                              return buildTasksList(snapshot.data!);
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
             ),
            ],
          ),
        ),
    );
  }

  Widget buildTasksList(List<Task> tasks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tasks.map((task) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text(task.description),
            ),
          );
        }).toList(),
      ),
    );
  }


  Color getColorForPriority(String option) {
    switch (option) {
      case 'Low':
        return Colors.blue;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}