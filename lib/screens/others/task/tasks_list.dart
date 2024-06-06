import 'package:dayplanner/screens/others/task/task_details.dart';
import 'package:dayplanner/services/task_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';

bool isTaskDeleting = false;

class TasksList extends StatefulWidget {
  final String category;
  final String sortingType;
  const TasksList({super.key, required this.category, required this.sortingType});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  String? userID = '';
  List<Map<String, dynamic>> tasksData = [];

  @override
  void didUpdateWidget(covariant TasksList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      handleTasksData();
    }
    if (oldWidget.sortingType != widget.sortingType) {
      _sortTasks();
    }
  }

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user?.uid;

    handleTasksData();
  }

  void handleTasksData() async {
    List<Map<String, dynamic>> tasks;
    widget.category == "All"
      ? tasks = await getAllTasksForToday(userID!)
      : tasks = await getTasksByCategoryForToday(userID!, widget.category);
    if (mounted) {
      setState(() {
        tasksData = tasks;
        _sortTasks();
      });
    }
  }

  int getPriorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      case 'Low':
        return 3;
      default:
        return 4;
    }
  }

  int compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    if (a.hour == b.hour) {
      return a.minute.compareTo(b.minute);
    }
    return a.hour.compareTo(b.hour);
  }

  void _sortTasks() {
    setState(() {
      if (widget.sortingType == 'Sort by Priority') {
        tasksData.sort((a, b) {
          int priorityComparison = getPriorityValue(a['priority']).compareTo(getPriorityValue(b['priority']));
          if (priorityComparison == 0) {
            return compareTimeOfDay(a['startTime'], b['startTime']);
          }
          return priorityComparison;
        });
      } else {
        tasksData.sort((a, b) {
          int timeComparison = compareTimeOfDay(a['startTime'], b['startTime']);
          if (timeComparison == 0) {
            return getPriorityValue(a['priority']).compareTo(getPriorityValue(b['priority']));
          }
          return timeComparison;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(todayDate);

    return ListView.builder(
      itemCount: tasksData.length,
      itemBuilder: (context, index) {
        final task = tasksData[index];
        bool? isChecked = task['status'] == 'Done';

        return Column(
            children: [
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
                onDismissed: (direction) async {
                  setState(() {
                    tasksData.removeAt(index);
                    isTaskDeleting = true;
                  });
                  await deleteTask(userID!, task['id'], formattedDate, task['category']);
                  setState(() {
                    isTaskDeleting = false;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          TaskDetails(
                              title: task['title'],
                              description: task['description'],
                              date: task['date'],
                              startTime: task['startTime'],
                              deadline: task['deadline'],
                              priority: task['priority'],
                              destination: task['destination'],
                              status: task['status']
                          ),
                    ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: getColorForPriority(task['priority']),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          width: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(task['title'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                  subtitle: Text(DateFormat('EEEE, d MMMM').format(task['date'])),
                                  trailing: Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      checkColor: Colors.greenAccent,
                                      activeColor: primaryColor,
                                      shape: const CircleBorder(),
                                      value: isChecked,
                                      onChanged: (value) =>
                                          setState(() {
                                            isChecked = value;
                                            task['status'] = (isChecked == true)
                                                ? 'Done'
                                                : 'To do';
                                            updateStatus(userID!, task['id'], formattedDate, task['status']);
                                          }),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: Column(
                                    children: [
                                      Divider(
                                        thickness: 1.5,
                                        color: Colors.grey.shade200,
                                      ),
                                      Row(
                                        children: [
                                          task['startTime'] != null ?
                                            Text("Start time: ${task['startTime'].hour}:${task['startTime'].minute}")
                                            : const Text(""),
                                          const SizedBox(width: 32),
                                          task['deadline'] != null ?
                                            Text("Deadline: ${task['deadline'].hour}:${task['deadline'].minute}")
                                            : const Text(""),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]
        );
      },
    );
  }
}