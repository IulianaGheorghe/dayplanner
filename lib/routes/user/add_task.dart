import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/auth_methods.dart';
import '../../services/task_services.dart';
import '../../util/components.dart';
import '../../util/constants.dart';
import '../../util/map_screen.dart';
import '../../util/showSnackBar.dart';

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
  TimeOfDay? _selectedTime;

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();

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

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String userID = await authMethods.getUserId();
      final newsAdd = Task(
        userID,
        _title,
        _description,
        DateTime.now(),
      );
      try {
        await newsAdd.addToFirestore();
        showSnackBar(context, "Task added successfully!");
        Navigator.pop(context);
        // Navigator.pushReplacement<void, void>(
        //   context,
        //   MaterialPageRoute<void>(
        //     builder: (BuildContext context) => TrainerHome(),
        //   ),
        // );
      } catch (e) {
        throw Exception('Error adding news to db: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                          showSnackBar( context, 'Please enter a title.');
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          showSnackBar(context, 'Please enter a description.');
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _description = value ?? '';
                      },
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
                              titleStyle('Time', secondaryTitleSize),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _selectTime(),
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
                                      Text(_selectedTime != null ? formatTime(_selectedTime!) : 'hh : mm'),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen()));
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor
                      ),
                      onPressed: _submitForm,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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