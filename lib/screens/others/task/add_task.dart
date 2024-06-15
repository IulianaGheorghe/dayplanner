import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../common_widgets/map_screen.dart';
import '../../../common_widgets/navigationBar.dart';
import '../../../common_widgets/showSnackBar.dart';
import '../../../services/auth_methods.dart';
import '../../../services/task_services.dart';
import '../../../services/user_services.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';
import '../../../util/notification_service.dart';

class AddTask extends StatefulWidget{
  final DateTime date;
  final int index;
  const AddTask({super.key, required this.date, required this.index});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask>{
  final _formKey = GlobalKey<FormState>();
  late int _navigatorIndex;
  String _title = '';
  String _description = '';
  late DateTime _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedDeadline;
  LatLng? _selectedDestination;
  bool _destinationSelected = false;
  String _selectedPriority = "Low";
  String _selectedCategory = "No category";
  String _status = "To do";
  String userID = '';
  List categoriesList = [];
  String choosePriority = "Low";
  List priorityList = ["Low", "Medium", "High"];
  String chooseCategory = "No category";
  List<int> _selectedRemindersStart = [];
  List<int> _selectedRemindersDeadline = [];

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();
  UserServices userServices = UserServices();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.date;
    _navigatorIndex = widget.index;

    User? user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;

    _handleCategories();
  }

  void _handleCategories() async {
    final categories = await getCategories(userID);
    setState(() {
      categoriesList = categories;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectStartTime() async {
    TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (pickedTime != null) {
      if (_selectedDate.isSameDate(DateTime.now())) {
        if (pickedTime.hour < now.hour || (pickedTime.hour == now.hour && pickedTime.minute <= now.minute)) {
          showSnackBar(context, 'Please select a time later than the current time.');
          return;
        }
      }
      setState(() {
        _selectedStartTime = pickedTime;
      });
    }
  }

  Future<void> _selectDeadline() async {
    TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (pickedTime != null) {
      if (_selectedDate.isSameDate(DateTime.now())) {
        if (pickedTime.hour < now.hour || (pickedTime.hour == now.hour && pickedTime.minute < now.minute)) {
          showSnackBar(context, 'Please select a time later than the current time.');
          return;
        }
      }
      setState(() {
        _selectedDeadline = pickedTime;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String userID = await userServices.getUserId();
      final taskAdd = Task(
        userID,
        _title,
        _description,
        _selectedCategory,
        _selectedDate,
        _selectedStartTime,
        _selectedDeadline,
        _selectedPriority,
        _selectedDestination,
        _status,
        DateTime.now(),
      );
      try {
        DocumentReference taskRef = await taskAdd.addToFirestore();
        String taskId = taskRef.id;
        showSnackBar(context, "Task successfully added!");
        Navigator.pop(context);
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MyBottomNavigationBar(index: _navigatorIndex),
          ),
        );

        var notificationIDs = [];

        if (_selectedStartTime != null) {
          notificationIDs.add(taskAdd.hashCode + Random().nextInt(1000));
          DateTime startTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedStartTime!.hour,
              _selectedStartTime!.minute
          );
          _notificationService.showScheduledNotification(
            id: notificationIDs.last,
            title: _title,
            body: 'Your task $_title starts now',
            scheduledDate: startTime,);

          if (_selectedRemindersStart != []) {
            for (var reminder in _selectedRemindersStart) {
              notificationIDs.add(taskAdd.hashCode + Random().nextInt(1000));
              DateTime notificationTime = startTime.subtract(Duration(minutes: reminder));
              _notificationService.showScheduledNotification(
                id: notificationIDs.last,
                title: 'Task Reminder',
                body: reminder >= 1440
                    ? 'Your task $_title starts in ${reminder ~/ 1440} day(s)'
                    : reminder >= 60
                      ? 'Your task $_title starts in ${reminder ~/ 60} hour(s)'
                      : 'Your task $_title starts in $reminder minutes',
                scheduledDate: notificationTime,);
            }
          }
        }

        if (_selectedDeadline != null) {
          notificationIDs.add(taskAdd.hashCode + Random().nextInt(1000));
          String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
          DateTime deadlineTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedDeadline!.hour,
            _selectedDeadline!.minute,
          );
          _notificationService.showScheduledNotificationWithActions(
            id: notificationIDs.last,
            title: 'Your task $_title is due now',
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

          if (_selectedRemindersDeadline != []) {
            for (var reminder in _selectedRemindersDeadline) {
              notificationIDs.add(taskAdd.hashCode + Random().nextInt(1000));
              DateTime notificationTime = deadlineTime.subtract(Duration(minutes: reminder));
              _notificationService.showScheduledNotification(
                id: notificationIDs.last,
                title: 'Task Deadline Reminder',
                body: reminder >= 60
                  ? 'Your task $_title deadline is in ${reminder ~/ 60} hour(s)'
                  : 'Your task $_title deadline is in $reminder minutes',
                scheduledDate: notificationTime,);
            }
          }
        }

        if (notificationIDs.isNotEmpty) {
          await taskRef.update({'notificationIDs': notificationIDs});
        }
      } catch (e) {
        throw Exception('Error adding task to db: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  titleStyle("Task Title*", secondaryTitleSize),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: addPageInputStyle("Enter Task Name"),
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: inputDecorationColor,
                    maxLength: 30,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        showSnackBar(context, 'Please enter a title.');
                        return '';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  titleStyle("Description", secondaryTitleSize),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: addPageInputStyle("Enter Task Description"),
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: inputDecorationColor,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    onSaved: (value) {
                      _description = value ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleStyle('Category', secondaryTitleSize),
                      const SizedBox(height: 16),
                      DropdownButtonFormField(
                        dropdownColor: Colors.grey.shade200,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          fillColor: Colors.white.withOpacity(0.8),
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: chooseCategory,
                        items: categoriesList.map(
                                (category) =>
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                        category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: chooseCategory == category ? primaryColor : Colors.black,
                                        ),
                                      ),
                                )
                        ).toList(),
                        onChanged: (val) {
                          setState(() {
                            chooseCategory = val as String;
                            _selectedCategory = chooseCategory;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleStyle('Date', secondaryTitleSize),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _selectDate(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.calendar),
                                    const SizedBox(width: 16),
                                    Text(formatDate(_selectedDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleStyle('Start Time', secondaryTitleSize),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _selectStartTime(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.clock),
                                    const SizedBox(width: 16),
                                    Text(_selectedStartTime != null ? formatTime(_selectedStartTime!) : 'hh : mm',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedStartTime != null) ...[
                    const SizedBox(height: 16),
                    titleStyle('Reminders before Start Time', secondaryTitleSize),
                    const SizedBox(height: 16),
                    MultiSelectDialogField(
                      items: [
                        MultiSelectItem(5, '5 minutes before'),
                        MultiSelectItem(10, '10 minutes before'),
                        MultiSelectItem(15, '15 minutes before'),
                        MultiSelectItem(30, '30 minutes before'),
                        MultiSelectItem(60, '1 hour before'),
                        MultiSelectItem(120, '2 hours before'),
                        MultiSelectItem(180, '3 hours before'),
                        MultiSelectItem(360, '6 hours before'),
                        MultiSelectItem(540, '9 hours before'),
                        MultiSelectItem(720, '12 hours before'),
                        MultiSelectItem(1440, '1 day before'),
                        MultiSelectItem(2880, '2 days before'),
                      ],
                      title: titleStyle('Choose reminders', secondaryTitleSize),
                      selectedColor: primaryColor,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      buttonIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade700,
                      ),
                      buttonText: const Text(
                        'Select reminders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: Colors.grey.shade200,
                        textStyle: const TextStyle(
                          color: primaryColor,
                        ),
                      ),
                      onConfirm: (results) {
                        setState(() {
                          _selectedRemindersStart = results.cast<int>();
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleStyle('Priority', secondaryTitleSize),
                            const SizedBox(height: 16),
                            DropdownButtonFormField(
                              dropdownColor: Colors.grey.shade200,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                fillColor: Colors.white.withOpacity(0.8),
                                filled: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              value: choosePriority,
                              items: priorityList.map(
                                      (e) =>
                                      DropdownMenuItem(
                                        value: e,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              color: getColorForPriority(e),
                                              margin: const EdgeInsets.only(right: 8),
                                            ),
                                            Text(e,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )
                              ).toList(),
                              onChanged: (val) {
                                setState(() {
                                  choosePriority = val as String;
                                  _selectedPriority = choosePriority;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleStyle('Deadline', secondaryTitleSize),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _selectDeadline(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.clock),
                                    const SizedBox(width: 16),
                                    Text(_selectedDeadline != null ? formatTime(_selectedDeadline!) : 'hh : mm',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedDeadline != null) ...[
                    const SizedBox(height: 16),
                    titleStyle('Reminders before Deadline', secondaryTitleSize),
                    const SizedBox(height: 16),
                    MultiSelectDialogField(
                      items: [
                        MultiSelectItem(5, '5 minutes before'),
                        MultiSelectItem(10, '10 minutes before'),
                        MultiSelectItem(15, '15 minutes before'),
                        MultiSelectItem(20, '20 minutes before'),
                        MultiSelectItem(25, '25 minutes before'),
                        MultiSelectItem(30, '30 minutes before'),
                        MultiSelectItem(40, '40 minutes before'),
                        MultiSelectItem(50, '50 minutes before'),
                        MultiSelectItem(60, '1 hour before'),
                        MultiSelectItem(120, '2 hours before'),
                        MultiSelectItem(180, '3 hours before'),
                        MultiSelectItem(240, '4 hours before'),
                        MultiSelectItem(300, '5 hours before'),
                        MultiSelectItem(360, '6 hours before'),
                      ],
                      title: titleStyle('Choose reminders', secondaryTitleSize),
                      selectedColor: primaryColor,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      buttonIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade700,
                      ),
                      buttonText: const Text(
                        'Select reminders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      chipDisplay: MultiSelectChipDisplay(
                        chipColor: Colors.grey.shade200,
                        textStyle: const TextStyle(
                          color: primaryColor,
                        ),
                      ),
                      onConfirm: (results) {
                        setState(() {
                          _selectedRemindersDeadline = results.cast<int>();
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  titleStyle('Add destination', secondaryTitleSize),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) => MapScreen(
                            onLocationSelected: (LatLng location) {
                              setState(() {
                                _destinationSelected = true;
                              });
                              _selectedDestination = location;
                            },
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/location.jpg',
                        ),
                        const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 48.0,
                        ),
                        const Positioned(
                          bottom: 30.0,
                          child: Text(
                            'Tap to add location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _destinationSelected,
                    child: Text(
                      'You\'ve selected your destination!',
                      style: TextStyle(fontSize: 18, color: Colors.lightGreen.shade300, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor
                    ),
                    onPressed: _submitForm,
                    child: const Text('Save', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }
}
extension DateUtils on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}