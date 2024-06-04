import 'package:dayplanner/common_widgets/showDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common_widgets/showSnackBar.dart';
import '../../services/task_services.dart';
import '../../util/constants.dart';
import '../others/task/add_task.dart';
import '../others/task/tasks_list.dart';

class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{
  String userID = '';
  List<String> _categoriesList = ['All'];
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;

    _handleCategories();
  }

  void _handleCategories() async {
    List<String> categories = await getCategories(userID);
    _categoriesList = ['All'];
    setState(() {
      _categoriesList += categories;
    });
  }

  String chooseCategory = "All";

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
              padding: const EdgeInsetsDirectional.fromSTEB(25, 40, 15, 40),
              child: Column (
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20,),
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
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width / 2.8,
                              child: ElevatedButton(
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
                                    Text(
                                      ' New Task',
                                      style: TextStyle(
                                        fontSize: 14
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 2.8,
                                child: DropdownButtonFormField(
                                  isExpanded: true,
                                  dropdownColor: Colors.white.withOpacity(0.9),
                                  decoration: InputDecoration(
                                    fillColor: Colors.white.withOpacity(0.5),
                                    filled: true,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.transparent),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.transparent),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  value: chooseCategory,
                                  items: _categoriesList.map(
                                        (category) =>
                                        DropdownMenuItem(
                                          value: category,
                                          child: Padding(
                                            padding: chooseCategory.length <= 8
                                                ? const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0)
                                                : const EdgeInsetsDirectional.all(0),
                                            child: Text(
                                              category,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: chooseCategory == category ? primaryColor : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      chooseCategory = val as String;
                                      _selectedCategory = chooseCategory;
                                    });
                                  },
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: Colors.white.withOpacity(0.9),
                                surfaceTintColor: primaryColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                                onSelected: (value) {
                                  if (value == 'Add category') {
                                    _showAddCategoryDialog(context);
                                  } else if (value == 'Delete category') {
                                    _showDeleteCategoryDialog();
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                        value: 'Add category',
                                        child: Text(
                                          'Add category',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15
                                          ),
                                        )
                                    ),
                                    const PopupMenuItem<String>(
                                        value: 'Delete category',
                                        child: Text(
                                          'Delete category',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15
                                          ),
                                        )
                                    ),
                                  ];
                                },
                                child: Container(
                                  height: 40,
                                  width: 15,
                                  alignment: Alignment.centerRight,
                                  child: const Icon(
                                    Icons.more_vert,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: TasksList(category: _selectedCategory),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShowDialog(
          title: 'Add new category',
          inputText: 'Enter category name',
          buttonText: 'Submit',
          onPressedFunction: (String controllerText, void Function(String?) setError) async {
            bool categoryExists = await categoryAlreadyExists(controllerText, userID);
            if (categoryExists) {
              setError('This category already exists');
            } else {
              await addCategory(controllerText, userID);
              Navigator.of(context).pop();
              showSnackBar(context, "Category successfully added");
              setError(null);
              _handleCategories();
            }
          },
        );
      },
    );
  }

  void _showDeleteCategoryDialog() {
    Map<String, bool> selectedCategories = {for (var category in _categoriesList) category: false};
    String? errorMessage;

    Future<void> deleteSelectedCategories() async {
      List<String> categoriesToDelete = selectedCategories.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      for (String category in categoriesToDelete) {
        await deleteCategory(category, userID);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text(
                'Delete Categories',
                style: TextStyle(
                  fontFamily: font1
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._categoriesList.map((String category) {
                      return CheckboxListTile(
                        title: Text(category),
                        value: selectedCategories[category],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedCategories[category] = value ?? false;
                            errorMessage = null;
                          });
                        },
                      );
                    }),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: primaryColor
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedCategories.values.every((isSelected) => !isSelected)) {
                      setState(() {
                        errorMessage = 'Please select at least one category to delete.';
                      });
                    } else {
                      await deleteSelectedCategories();
                      _handleCategories();
                      Navigator.of(context).pop();
                      showSnackBar(context, "Categories successfully deleted");
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                        color: primaryColor
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}