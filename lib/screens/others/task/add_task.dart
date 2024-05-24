import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../common_widgets/map_screen.dart';
import '../../../common_widgets/navigationBar.dart';
import '../../../common_widgets/showSnackBar.dart';
import '../../../services/auth_methods.dart';
import '../../../services/task_services.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';

String valueChoose = "Low";
List priorityList = ["Low", "Medium", "High"];

class AddTask extends StatefulWidget{
  const AddTask({super.key});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask>{
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedDeadline;
  LatLng? _selectedDestination;
  bool _destinationSelected = false;
  String _selectedPriority = "Low";
  String _status = "To do";
  String userID = '';
  List categoriesList = [];

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();

  @override
  void initState() {
    super.initState();

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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _selectedStartTime) {
      setState(() {
        _selectedStartTime = pickedTime;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _selectedDeadline) {
      setState(() {
        _selectedDeadline = pickedTime;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String userID = await authMethods.getUserId();
      final taskAdd = Task(
        userID,
        _title,
        _description,
        _selectedDate,
        _selectedStartTime,
        _selectedDeadline,
        _selectedPriority,
        _selectedDestination,
        _status,
        DateTime.now(),
      );
      try {
        await taskAdd.addToFirestore();
        showSnackBar(context, "Task added successfully!");
        Navigator.pop(context);
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const MyBottomNavigationBar(),
          ),
        );
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
                  titleStyle("Task Title", secondaryTitleSize),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: addPageInputStyle("Enter Task Name"),
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
                        value: valueChoose,
                        items: categoriesList.map(
                                (e) =>
                                DropdownMenuItem(
                                  value: e,
                                  child: Text(e)
                                )
                        ).toList(),
                        onChanged: (val) {
                          setState(() {
                            valueChoose = val as String;
                            _selectedPriority = valueChoose;
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
                                    Text(formatDate(_selectedDate)),
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
                                    Text(_selectedStartTime != null ? formatTime(_selectedStartTime!) : 'hh : mm'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                              value: valueChoose,
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
                                            Text(e),
                                          ],
                                        ),
                                      )
                              ).toList(),
                              onChanged: (val) {
                                setState(() {
                                  valueChoose = val as String;
                                  _selectedPriority = valueChoose;
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
                                    Text(_selectedDeadline != null ? formatTime(_selectedDeadline!) : 'hh : mm'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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