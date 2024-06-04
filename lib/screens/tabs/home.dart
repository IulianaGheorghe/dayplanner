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
  List _categoriesList = ['All'];
  String _selectedCategory = "All";

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
}