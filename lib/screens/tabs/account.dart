import 'dart:io';

import 'package:dayplanner/services/task_services.dart';
import 'package:dayplanner/services/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../common_widgets/indicator.dart';
import '../../services/auth_methods.dart';
import '../../util/constants.dart';
import '../others/account/edit_profile.dart';
import 'package:fl_chart/fl_chart.dart';

class Account extends StatefulWidget{
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account>{
  String userID = '';
  String userName = "";
  String userEmail = "";
  String userPhoto = "";
  File? _imageFile;
  List _categories = [];
  int _totalTasksCount = 0;
  late TooltipBehavior _tooltipBehavior;
  String _startOfWeek = '';
  String _endOfWeek = '';
  List _noOfTodoAndDoneTasksForWeek = List.generate(7, (index) => {'To do': 0, 'Done': 0});

  late Future<Map<String, String>> fetchDetails;

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();
  UserServices userServices = UserServices();

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User does not exist!');
    }
    userID = user.uid;

    _getUserDetails();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _getDataForBarChart();
    _getCategoriesPercentages();
  }

  void _getUserDetails() async {
    fetchDetails = userServices.getUserDetails();
    Map<String, String> userDetails = await userServices.getUserDetails();
    if (mounted) {
      setState(() {
        userName = userDetails['userName']!;
        userEmail = userDetails['userEmail']!;
        userPhoto = userDetails['userPhoto']!;
      });
    }
  }

  void _getCategoriesPercentages() async {
    final categories = await getCategoryTaskPercentage(userID);
    final totalTasksCount = await getTotalTasksCount(userID);
    if (mounted) {
      setState(() {
        _categories = categories;
        _totalTasksCount = totalTasksCount;
      });
    }
  }

  void _getDataForBarChart() async {
    final today = DateTime.now();
    final dayOfWeek = today.weekday;
    final startOfWeek = today.subtract(Duration(days: dayOfWeek - 1));
    final endOfWeek = today.add(Duration(days: DateTime.daysPerWeek - dayOfWeek));
    _startOfWeek = DateFormat('yyyy-MM-dd').format(startOfWeek);
    _endOfWeek = DateFormat('yyyy-MM-dd').format(endOfWeek);

    final noOfTodoAndDoneTasksForWeek = await getNumberOfTodoAndDoneTasksForWeek(userID, _startOfWeek, _endOfWeek);
    if (mounted) {
      setState(() {
        _noOfTodoAndDoneTasksForWeek = noOfTodoAndDoneTasksForWeek;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: profilePageColor,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Edit profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfile()),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'Edit profile',
                    child: Text('Edit profile')
                  ),
                ];
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/t.jpg',
              fit: BoxFit.cover,
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverFillRemaining(
                  child: FutureBuilder<Map<String, String>>(
                    future: fetchDetails,
                    builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor:AlwaysStoppedAnimation<Color>(profilePageColor),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        return SingleChildScrollView(
                          child: Column(
                              children: [
                                buildProfile(),
                                buildBarChart(),
                                const SizedBox(height: 20),
                                buildPieChart(),
                                const SizedBox(height: 20),
                              ]
                          ),
                        );
                      } else {
                        return const Text('No data available');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfile(){
    ImageProvider<Object> imageShowed;
    if(_imageFile == null)
    {
      imageShowed = NetworkImage(userPhoto);
    } else {
      imageShowed = FileImage(_imageFile!);
      userPhoto = 'photo';
    }

    return Container(
      height: 300,
      width: MediaQuery.of(context).size.width / 2,
      padding: const EdgeInsets.only(left: 16, bottom: 10, right: 16),
      child: ListView(
        children: [
          Center(
            child: Stack(
              children: [
                InkWell(
                  child: userPhoto == ""
                      ? Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 4,
                            color: Theme.of(context).scaffoldBackgroundColor),
                        boxShadow: [
                          BoxShadow(
                              spreadRadius: 2,
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 10))
                        ],
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage('assets/images/user.png'))),
                  )
                      : Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 4,
                            color: Theme.of(context).scaffoldBackgroundColor),
                        boxShadow: [
                          BoxShadow(
                              spreadRadius: 2,
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 10))
                        ],
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: imageShowed)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              userName,
              style: const TextStyle(
                fontFamily: font1,
                fontSize: 25,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              userEmail,
              style: const TextStyle(
                fontFamily: font1,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int touchedIndex = -1;
  Widget buildPieChart() {
    return Container(
      width: MediaQuery.of(context).size.width - 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, top: 15),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                text: 'Percentage distribution of ',
                style: TextStyle(
                  fontFamily: font1,
                  fontSize: 18,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'tasks ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'by ',
                  ),
                  TextSpan(
                    text: 'category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (mounted) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          }
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 30,
                      sections: _categories.map((category) {
                        final index = category['index'];
                        final isTouched = index == touchedIndex;
                        final fontSize = isTouched ? 25.0 : 16.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
                        return PieChartSectionData(
                          color: category['color'],
                          value: category['percentage'],
                          title: '${category['percentage'].round()}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            shadows: shadows,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Indicator(
                              color: category['color'],
                              text: category['name'],
                              isSquare: true,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
              ),
            ],
          ),
        ],
      )
    );
  }

  Widget buildBarChart() {
    final List<ChartData> barChartData = <ChartData>[
      ChartData('Monday', _noOfTodoAndDoneTasksForWeek[0]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[0]['Done']?.toDouble()),
      ChartData('Tuesday', _noOfTodoAndDoneTasksForWeek[1]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[1]['Done']?.toDouble()),
      ChartData('Wednesday', _noOfTodoAndDoneTasksForWeek[2]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[2]['Done']?.toDouble()),
      ChartData('Thursday', _noOfTodoAndDoneTasksForWeek[3]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[3]['Done']?.toDouble()),
      ChartData('Friday', _noOfTodoAndDoneTasksForWeek[4]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[4]['Done']?.toDouble()),
      ChartData('Saturday', _noOfTodoAndDoneTasksForWeek[5]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[5]['Done']?.toDouble()),
      ChartData('Sunday', _noOfTodoAndDoneTasksForWeek[6]['To do']?.toDouble(), _noOfTodoAndDoneTasksForWeek[6]['Done']?.toDouble()),
    ];
    return Container(
        width: MediaQuery.of(context).size.width - 30,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 10),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'Distribution of ',
                  style: TextStyle(
                    fontFamily: font1,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'To do',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' and ',
                    ),
                    TextSpan(
                      text: 'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' tasks',
                    ),
                  ],
                ),
              ),
            ),
            SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                tooltipBehavior: _tooltipBehavior,
                series: <CartesianSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: barChartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    name: 'To do',
                    onPointTap: (ChartPointDetails details) {
                      _tooltipBehavior.showByIndex(0, details.pointIndex!);
                    },
                  ),
                  ColumnSeries<ChartData, String>(
                    dataSource: barChartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y1,
                    name: 'Done',
                    onPointTap: (ChartPointDetails details) {
                      _tooltipBehavior.showByIndex(1, details.pointIndex!);
                    },
                  ),
                ]
            ),
          ],
        )
    );
  }

}

class ChartData {
  ChartData(this.x, this.y, this.y1);
  final String x;
  final double? y;
  final double? y1;
}