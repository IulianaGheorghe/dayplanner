import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../../common_widgets/navigationBar.dart';
import '../../../common_widgets/showSnackBar.dart';
import '../../../common_widgets/taskForm.dart';
import '../../../services/task_services.dart';
import '../../../util/constants.dart';
import '../../../util/notification_service.dart';

class AddTask extends StatefulWidget{
  final DateTime date;
  final int index;
  const AddTask({super.key, required this.date, required this.index});

  @override
  State<AddTask> createState() => _AddTaskState();

  // void submitAddTaskForm(userID, title, description, selectedCategory, selectedDate,
  //     selectedStartTime, selectedDeadline, selectedPriority, selectedDestination, status,
  //     selectedRemindersStart, selectedRemindersDeadline, createdAt) {
  //   _AddTaskState? state = _AddTaskState();
  //   state._submitForm(userID, title, description, selectedCategory, selectedDate,
  //       selectedStartTime, selectedDeadline, selectedPriority, selectedDestination, status,
  //       selectedRemindersStart, selectedRemindersDeadline, createdAt);
  // }
}

class _AddTaskState extends State<AddTask>{
  late int _navigatorIndex;
  late DateTime _selectedDate;
  Map<String, int> _startTimeReminders = {};
  Map<String, int> _deadlineReminders = {};
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.date;
    _navigatorIndex = widget.index;
  }

  void _submitForm(userID, title, description, selectedCategory, selectedDate,
  selectedStartTime, selectedDeadline, selectedPriority, selectedDestination, status,
  selectedRemindersStart, selectedRemindersDeadline, createdAt) async {
    setState(() {
      _isLoading = true;
    });
    final taskAdd = Task(
      userID,
      title,
      description,
      selectedCategory,
      selectedDate,
      selectedStartTime,
      selectedDeadline,
      selectedPriority,
      selectedDestination,
      status,
      createdAt,
    );
    try {
      DocumentReference taskRef = await taskAdd.addToFirestore();
      String taskId = taskRef.id;
      showSnackBar(context, "Task successfully added!", primaryColor);
      Navigator.pop(context);
      Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => MyBottomNavigationBar(
            index: _navigatorIndex,
            selectedCalendarDate: _selectedDate,
          ),
        ),
      );

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      if (selectedStartTime != null) {
        var uniqueId = (timestamp*1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
        DateTime startTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedStartTime!.hour,
            selectedStartTime!.minute
        );
        _startTimeReminders['0'] = uniqueId;
        _notificationService.showScheduledNotification(
          id: uniqueId,
          title: title,
          body: 'Your task $title starts now',
          scheduledDate: startTime,);

        if (selectedRemindersStart != []) {
          for (var reminder in selectedRemindersStart) {
            var uniqueId = (timestamp*1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
            DateTime notificationTime = startTime.subtract(Duration(minutes: reminder));
            _startTimeReminders['$reminder'] = uniqueId;
            _notificationService.showScheduledNotification(
              id: uniqueId,
              title: 'Task Reminder',
              body: reminder >= 1440
                  ? 'Your task $title starts in ${reminder ~/ 1440} day(s)'
                  : reminder >= 60
                  ? 'Your task $title starts in ${reminder ~/ 60} hour(s)'
                  : 'Your task $title starts in $reminder minutes',
              scheduledDate: notificationTime,);
          }
        }
      }

      if (selectedDeadline != null) {
        var uniqueId = (timestamp*1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
        String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        DateTime deadlineTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedDeadline!.hour,
          selectedDeadline!.minute,
        );
        _deadlineReminders['0'] = uniqueId;
        _notificationService.showScheduledNotificationWithActions(
          id: uniqueId,
          title: 'Your task $title is due now',
          body: 'Would you like to mark it as done?',
          scheduledDate: deadlineTime,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'yes_action',
              'Yes',
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'no_action',
              'No',
              showsUserInterface: false,
            ),
          ],
          payload: '$userID|$taskId|$formattedDate',
        );

        if (selectedRemindersDeadline != []) {
          for (var reminder in selectedRemindersDeadline) {
            var uniqueId = (timestamp*1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
            DateTime notificationTime = deadlineTime.subtract(Duration(minutes: reminder));
            _deadlineReminders['$reminder'] = uniqueId;
            _notificationService.showScheduledNotification(
              id: uniqueId,
              title: 'Task Deadline Reminder',
              body: reminder >= 60
                  ? 'Your task $title deadline is in ${reminder ~/ 60} hour(s)'
                  : 'Your task $title deadline is in $reminder minutes',
              scheduledDate: notificationTime,);
          }
        }
      }

      if (_startTimeReminders.isNotEmpty) {
        await taskRef.update({'startTimeReminders': _startTimeReminders});
      }
      if (_deadlineReminders.isNotEmpty) {
        await taskRef.update({'deadlineReminders': _deadlineReminders});
      }
    } catch (e) {
      throw Exception('Error adding task to db: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.black,
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Create task',
          style: TextStyle(
            fontFamily: font1,
            fontSize: 23,
            color: Colors.black
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/back7.jpg',
            fit: BoxFit.cover,
          ),
          TaskForm(editMode: false, initialDate: _selectedDate, onSubmit: _submitForm),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}