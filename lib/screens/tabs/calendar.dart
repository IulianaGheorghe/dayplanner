import 'package:dayplanner/util/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String, int> _tasksCount = {};

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;
    _updateTasksCount(_focusedDay);
  }

  Future<void> _updateTasksCount(DateTime dateTime) async {
    Map<String, int> tasksCount = await getTasksCountForMonth(dateTime, userID);
    setState(() {
      _tasksCount = tasksCount;
    });
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
                            onPageChanged: (focusedDay) {
                              int selectedMonth = focusedDay.month;
                              int currentMonth = DateTime.now().month;
                              if (selectedMonth != currentMonth) {
                                setState(() {
                                  _selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
                                  _focusedDay = focusedDay;
                                  _updateTasksCount(_focusedDay);
                                });
                              } else {
                                setState(() {
                                  _selectedDay = DateTime.now();
                                  _focusedDay = focusedDay;
                                  _updateTasksCount(_focusedDay);
                                });
                              }
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
                                String dateString = DateFormat('yyyy-MM-dd').format(date);
                                final tasksCount = _tasksCount[dateString];
                                if (tasksCount != null) {
                                  return Positioned(
                                    right: 1,
                                    top: -6,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.lightBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      width: 18,
                                      height: 18,
                                      child: Center(
                                        child: Text(
                                          '$tasksCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return null;
                                }
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

}