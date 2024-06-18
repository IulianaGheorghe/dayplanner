import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../../common_widgets/showSnackBar.dart';
import '../../../common_widgets/taskForm.dart';
import '../../../services/task_services.dart';
import '../../../util/constants.dart';
import '../../../services/notification_service.dart';
import '../../tabs/home.dart';

class EditTask extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? deadline;
  final String priority;
  final LatLng? destination;
  final String status;
  final String id;
  final Map<String, dynamic>? startTimeReminders;
  final Map<String, dynamic>? deadlineReminders;
  const EditTask({super.key, required this.title, required this.description, required this.category, required this.date, this.startTime, this.deadline, required this.priority, this.destination, required this.status, required this.id, this.startTimeReminders, this.deadlineReminders});

  @override
  State<EditTask> createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  late String _title;
  late String _description;
  late String _selectedCategory;
  late DateTime _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedDeadline;
  late String _selectedPriority;
  LatLng? _selectedDestination;
  late String _status;
  late String _id;
  Map<String, dynamic> _startTimeReminders = {};
  Map<String, dynamic> _deadlineReminders = {};
  bool _destinationSelected = false;
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _title = widget.title;
    _description = widget.description;
    _selectedDate = widget.date;
    _selectedStartTime = widget.startTime;
    _selectedDeadline = widget.deadline;
    _selectedDestination = widget.destination;
    _selectedPriority = widget.priority;
    _selectedCategory = widget.category;
    _status = widget.status;
    _id = widget.id;
    if (widget.startTimeReminders != null) {
      _startTimeReminders = widget.startTimeReminders!;
    }
    if (widget.deadlineReminders != null) {
      _deadlineReminders = widget.deadlineReminders!;
    }
  }

  void _submitForm(userID, title, description, selectedCategory, selectedDate,
      selectedStartTime, selectedDeadline, selectedPriority, selectedDestination, status,
      selectedRemindersStart, selectedRemindersDeadline, createdAt) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (selectedDate != widget.date) {
        // var addNewTask = AddTask(date: DateTime.now(), index: 0);
        // addNewTask.submitAddTaskForm(userID, title, description, selectedCategory, selectedDate,
        //     selectedStartTime, selectedDeadline, selectedPriority, selectedDestination, status,
        //     selectedRemindersStart, selectedRemindersDeadline, createdAt);
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
        DocumentReference taskRef = await taskAdd.addToFirestore();
        String taskId = taskRef.id;

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

        await deleteTask(userID, _id, DateFormat('yyyy-MM-dd').format(widget.date), widget.category);

        showSnackBar(context, "Task updated successfully!", primaryColor);
        Navigator.pop(context);
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
              builder: (BuildContext context) => const Home()
          ),
        );
      } else {
        String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        
        if (selectedCategory != widget.category) {
          await changeTaskCategory(userID, selectedCategory, widget.category, _id, formattedDate);
        }
        if (selectedStartTime != widget.startTime) {
          if (widget.startTime != null) {
            await FlutterLocalNotificationsPlugin().cancel(_startTimeReminders['0']);
          }
          var uniqueId = (timestamp * 1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
          DateTime startTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedStartTime!.hour,
            selectedStartTime!.minute,
          );
          _startTimeReminders['0'] = uniqueId;
          _notificationService.showScheduledNotification(
            id: uniqueId,
            title: title,
            body: 'Your task $title starts now',
            scheduledDate: startTime,
          );
        }
        if (selectedDeadline != widget.deadline) {
          if (widget.deadline != null) {
            await FlutterLocalNotificationsPlugin().cancel(_deadlineReminders['0']);
          }
          var uniqueId = (timestamp * 1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
          DateTime deadlineTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedDeadline!.hour,
            selectedDeadline!.minute,
          );
          _deadlineReminders['0'] = uniqueId;
          _notificationService.showScheduledNotification(
            id: uniqueId,
            title: title,
            body: 'Your task $title is due now',
            scheduledDate: deadlineTime,
          );
        }
        List<int> startRemindersList = widget.startTimeReminders != null
            ? widget.startTimeReminders!.keys.map((str) => int.parse(str)).toList()
            : [];
        if (selectedRemindersStart.length >= 1 &&
            !ListEquality().equals(selectedRemindersStart.sublist(1), startRemindersList.sublist(1))) {
          DateTime startTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedStartTime!.hour,
            selectedStartTime!.minute,
          );
          if (startRemindersList.sublist(1) != []) {
            _startTimeReminders.entries
                .where((entry) => int.parse(entry.key) > 0)
                .map((entry) async => await FlutterLocalNotificationsPlugin().cancel(entry.value));
            _startTimeReminders = {
              _startTimeReminders.keys.first: _startTimeReminders.values.first,
            };
          }
          for (var reminder in selectedRemindersStart.sublist(1)) {
            var uniqueId = (timestamp * 1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
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
              scheduledDate: notificationTime,
            );
          }
        }
        List<int> deadlineReminderList = widget.deadlineReminders != null
            ? widget.deadlineReminders!.keys.map((str) => int.parse(str)).toList()
            : [];
        if (selectedRemindersDeadline.length >= 1 &&
            !ListEquality().equals(selectedRemindersDeadline.sublist(1), deadlineReminderList.sublist(1))) {
          DateTime deadline = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedStartTime!.hour,
            selectedStartTime!.minute,
          );
          if (deadlineReminderList.sublist(1) != []) {
            _deadlineReminders.entries
                .where((entry) => int.parse(entry.key) > 0)
                .map((entry) async => await FlutterLocalNotificationsPlugin().cancel(entry.value));
            _deadlineReminders = {
              _deadlineReminders.keys.first: _deadlineReminders.values.first,
            };
          }
          for (var reminder in selectedRemindersDeadline.sublist(1)) {
            var uniqueId = (timestamp * 1000 + Random().nextInt(1000)) & 0x7FFFFFFF;
            DateTime notificationTime = deadline.subtract(Duration(minutes: reminder));
            _deadlineReminders['$reminder'] = uniqueId;
            _notificationService.showScheduledNotification(
              id: uniqueId,
              title: 'Task Reminder',
              body: reminder >= 1440
                  ? 'Your task $title is due in ${reminder ~/ 1440} day(s)'
                  : reminder >= 60
                  ? 'Your task $title is due in ${reminder ~/ 60} hour(s)'
                  : 'Your task $title is due in $reminder minutes',
              scheduledDate: notificationTime,
            );
          }
        }
        final taskUpdate = {
          'title': title,
          'description': description,
          'category': selectedCategory,
          'startTime': selectedStartTime != null ? "${selectedStartTime!.hour}:${selectedStartTime!.minute}" : "",
          'deadline': selectedDeadline != null ? "${selectedDeadline!.hour}:${selectedDeadline!.minute}" : "",
          'priority': selectedPriority,
          'destination': selectedDestination != null ? "${selectedDestination!.latitude},${selectedDestination!.longitude}" : "",
          'status': status,
          if (_startTimeReminders.isNotEmpty)
            'startTimeReminders': _startTimeReminders,
          if (_deadlineReminders.isNotEmpty)
            'deadlineReminders': _deadlineReminders,
        };
        await updateTask(taskUpdate, userID, formattedDate, _id);
        showSnackBar(context, 'Task updated successfully', primaryColor);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (BuildContext context) => const Home()
          ),
        );
      }
    } catch (e) {
      showSnackBar(context, 'Failed to update task. Please try again.', errorColor);
      throw Exception('Error updating task: $e');
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
        backgroundColor: taskDetailsColor,
        centerTitle: true,
        title: const Text('Edit task',
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
            'assets/images/trq.jpg',
            fit: BoxFit.cover,
          ),
          TaskForm(editMode: true,
            initialTitle: _title,
            initialDescription: _description,
            initialCategory: _selectedCategory,
            initialDate: _selectedDate,
            initialStartTime: _selectedStartTime,
            initialRemindersStart: _startTimeReminders,
            initialDeadline: _selectedDeadline,
            initialRemindersDeadline: _deadlineReminders,
            initialPriority: _selectedPriority,
            initialStatus: _status,
            initialDestination: _selectedDestination,
            id: _id,
            isDestinationSelected: _destinationSelected,
            onSubmit: _submitForm
          ),
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

