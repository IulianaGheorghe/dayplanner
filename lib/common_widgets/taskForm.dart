import 'package:dayplanner/common_widgets/showSnackBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

import '../services/task_services.dart';
import '../util/components.dart';
import '../util/constants.dart';
import 'map_screen.dart';

class TaskForm extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? initialCategory;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final Map<String, dynamic>? initialRemindersStart;
  final String? initialPriority;
  final TimeOfDay? initialDeadline;
  final Map<String, dynamic>? initialRemindersDeadline;
  final String? initialStatus;
  final LatLng? initialDestination;
  final String? id;
  final bool? isDestinationSelected;
  final bool editMode;
  final Function(String, String, String, String, DateTime, TimeOfDay?, TimeOfDay?, String, LatLng?, String, List<int>?, List<int>?, DateTime) onSubmit;

  const TaskForm({super.key, this.initialTitle, this.initialDescription, this.initialCategory, this.initialDate, this.initialStartTime, this.initialRemindersStart, this.initialPriority,
    this.initialDeadline, this.initialRemindersDeadline, this.initialStatus, this.initialDestination, this.id, this.isDestinationSelected, required this.editMode, required this.onSubmit,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late String userID;
  late String _title;
  late String _description;
  late String _selectedCategory;
  late DateTime _selectedDate;
  TimeOfDay? _selectedStartTime;
  List<int> _selectedRemindersDeadline = [];
  late String _selectedPriority;
  TimeOfDay? _selectedDeadline;
  List<int> _selectedRemindersStart = [];
  late String _status;
  LatLng? _destination;
  String? _id;
  late bool _isDestinationSelected;
  List categoriesList = [];
  List priorityList = ["Low", "Medium", "High"];

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle ?? '';
    _description = widget.initialDescription ?? '';
    _selectedCategory = widget.initialCategory ?? 'No category';
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedStartTime = widget.initialStartTime;
    if (widget.initialRemindersStart != null) {
      _selectedRemindersStart = widget.initialRemindersStart!.keys.toList().map((str) => int.parse(str)).toList();
    }
    _selectedPriority = widget.initialPriority ?? 'Low';
    _selectedDeadline = widget.initialDeadline;
    if (widget.initialRemindersDeadline != null) {
      _selectedRemindersDeadline = widget.initialRemindersDeadline!.keys.toList().map((str) => int.parse(str)).toList();
    }
    _isDestinationSelected = widget.isDestinationSelected ?? false;
    _status = widget.initialStatus ?? 'To do';
    _destination = widget.initialDestination;

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

  void _submitForm() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(
        userID,
        _title,
        _description,
        _selectedCategory,
        _selectedDate,
        _selectedStartTime,
        _selectedDeadline,
        _selectedPriority,
        _destination,
        _status,
        _selectedRemindersStart,
        _selectedRemindersDeadline,
        DateTime.now(),
      );
    }
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
          showSnackBar(context, 'Please select a time later than the current time.', errorColor);
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
          showSnackBar(context, 'Please select a time later than the current time.', errorColor);
          return;
        }
      }
      setState(() {
        _selectedDeadline = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            titleStyle("Task Title*", secondaryTitleSize, TextAlign.left),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _title,
              decoration: addPageInputStyle("Enter Task Name"),
              textCapitalization: TextCapitalization.sentences,
              cursorColor: inputDecorationColor,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  showSnackBar(context, 'Please enter a title.', errorColor);
                  return '';
                }
                return null;
              },
              onSaved: (value) {
                _title = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            titleStyle("Description", secondaryTitleSize, TextAlign.left),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _description,
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
                titleStyle('Category', secondaryTitleSize, TextAlign.left),
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
                  value: _selectedCategory,
                  items: categoriesList.map(
                          (category) =>
                          DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedCategory == category ? primaryColor : Colors.black,
                              ),
                            ),
                          )
                  ).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val as String;
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
                      titleStyle('Date', secondaryTitleSize, TextAlign.left),
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
                      titleStyle('Start Time', secondaryTitleSize, TextAlign.left),
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
              titleStyle('Reminders before Start Time', secondaryTitleSize, TextAlign.left),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                initialValue: _selectedRemindersStart,
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
                title: titleStyle('Choose reminders', secondaryTitleSize, TextAlign.left),
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
                    var resultedList = results.cast<int>();
                    _selectedRemindersStart = resultedList.map((e) => e.toInt()).toList();
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
                      titleStyle('Priority', secondaryTitleSize, TextAlign.left),
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
                        value: _selectedPriority,
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
                            _selectedPriority = val as String;
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
                      titleStyle('Deadline', secondaryTitleSize, TextAlign.left),
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
              titleStyle('Reminders before Deadline', secondaryTitleSize, TextAlign.left),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                initialValue: _selectedRemindersDeadline,
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
                title: titleStyle('Choose reminders', secondaryTitleSize, TextAlign.left),
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
                    var resultedList = results.cast<int>();
                    _selectedRemindersDeadline = resultedList.map((e) => e.toInt()).toList();
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            titleStyle('Add destination', secondaryTitleSize, TextAlign.left),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      initialLocation: _destination,
                      onLocationSelected: (LatLng location) {
                        setState(() {
                          _isDestinationSelected = true;
                        });
                        _destination = location;
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
                  Positioned(
                    bottom: 30.0,
                    child: Text(
                      _destination != null
                          ? 'Tap to edit location'
                          : 'Tap to add location',
                      style: const TextStyle(
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
              visible: _isDestinationSelected,
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
    );
  }
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String formatTime(TimeOfDay time) {
  return '${time.hour}:${time.minute}';
}

extension DateUtils on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
