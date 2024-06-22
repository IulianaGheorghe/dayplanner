import 'dart:async';
import 'dart:io';

import 'package:dayplanner/services/task_services.dart';
import 'package:dayplanner/services/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../common_widgets/indicator.dart';
import '../../services/auth_methods.dart';
import '../../util/constants.dart';
import '../others/account/edit_profile.dart';
import 'package:fl_chart/fl_chart.dart';

class Account extends StatefulWidget{
  final String userID;
  const Account({super.key, required this.userID});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account>{
  String userID = '';
  String currentUserID = '';
  String userName = "";
  String userEmail = "";
  String userIdField = '';
  String userPhoto = "";
  File? _imageFile;
  List _categories = [];
  int _totalTasksCount = 0;
  late TooltipBehavior _tooltipBehavior;
  String _startOfWeek = '';
  String _endOfWeek = '';

  late Future<List<Map<String, dynamic>>> _noOfTodoAndDoneTasksForWeek;
  late Future<Map<String, String>> fetchDetails;

  FirebaseAuthMethods authMethods = FirebaseAuthMethods();
  UserServices userServices = UserServices();

  @override
  void initState() {
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    currentUserID = currentUser!.uid;
    userID = widget.userID;

    _getUserDetails();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _getDataForBarChart();
    _getCategoriesPercentages();
  }

  void _getUserDetails() async {
    fetchDetails = userServices.getUserDetails(userID);
    Map<String, String> userDetails = await userServices.getUserDetails(userID);
    setState(() {
      userIdField = userDetails['userIdField']!;
      userName = userDetails['userName']!;
      userEmail = userDetails['userEmail']!;
      userPhoto = userDetails['userPhoto']!;
    });
  }

  void _getCategoriesPercentages() async {
    _categories = await getCategoryTaskPercentage(userID);
    _totalTasksCount = await getTotalTasksCount(userID);
  }

  void _getDataForBarChart() async {
    final today = DateTime.now();
    final dayOfWeek = today.weekday;
    final startOfWeek = today.subtract(Duration(days: dayOfWeek - 1));
    final endOfWeek = today.add(Duration(days: DateTime.daysPerWeek - dayOfWeek));
    _startOfWeek = DateFormat('yyyy-MM-dd').format(startOfWeek);
    _endOfWeek = DateFormat('yyyy-MM-dd').format(endOfWeek);

    _noOfTodoAndDoneTasksForWeek = getNumberOfTodoAndDoneTasksForWeek(userID, _startOfWeek, _endOfWeek);
  }

  void _previousWeek() {
    DateTime startOfWeek = DateFormat('yyyy-MM-dd').parse(_startOfWeek);
    DateTime endOfWeek = DateFormat('yyyy-MM-dd').parse(_endOfWeek);
    setState(() {
      _startOfWeek = DateFormat('yyyy-MM-dd').format(startOfWeek.subtract(const Duration(days: 7)));
      _endOfWeek = DateFormat('yyyy-MM-dd').format(endOfWeek.subtract(const Duration(days: 7)));
      _noOfTodoAndDoneTasksForWeek = getNumberOfTodoAndDoneTasksForWeek(userID, _startOfWeek, _endOfWeek);
    });
  }

  void _nextWeek() {
    DateTime startOfWeek = DateFormat('yyyy-MM-dd').parse(_startOfWeek);
    DateTime endOfWeek = DateFormat('yyyy-MM-dd').parse(_endOfWeek);
    setState(() {
      _startOfWeek = DateFormat('yyyy-MM-dd').format(startOfWeek.add(const Duration(days: 7)));
      _endOfWeek = DateFormat('yyyy-MM-dd').format(endOfWeek.add(const Duration(days: 7)));
      _noOfTodoAndDoneTasksForWeek = getNumberOfTodoAndDoneTasksForWeek(userID, _startOfWeek, _endOfWeek);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentUserProfile;
    if (userID == currentUserID) {
      isCurrentUserProfile = true;
    } else {
      isCurrentUserProfile = false;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      home: Scaffold(
        appBar: isCurrentUserProfile
        ? AppBar(
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
          )
        : AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: Colors.black,
          ),
          backgroundColor: profilePageColor,
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
                                buildProfile(isCurrentUserProfile),
                                buildBarChart(),
                                const SizedBox(height: 20),
                                buildPieChart(isCurrentUserProfile),
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

  Widget buildProfile(bool isCurrentUserProfile){
    ImageProvider<Object> imageShowed;
    if(_imageFile == null)
    {
      imageShowed = NetworkImage(userPhoto);
    } else {
      imageShowed = FileImage(_imageFile!);
      userPhoto = 'photo';
    }

    void copyToClipboard() {
      Clipboard.setData(ClipboardData(text: userIdField));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID copied to clipboard')),
      );
    }

    return Container(
      height: isCurrentUserProfile ? 325 : 285,
      width: MediaQuery.of(context).size.width / 1.25,
      padding: const EdgeInsets.only(left: 16, bottom: 10, right: 16),
      child: ListView(
        children: [
          isCurrentUserProfile
          ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "ID: $userIdField",
                  style: const TextStyle(
                    fontFamily: font1,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon:  Icon(Icons.copy, color: Colors.grey.shade600,),
                onPressed: copyToClipboard,
              ),
            ],
          )
          : Container(),
          const SizedBox(height: 10),
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
  Widget buildPieChart(bool isCurrentUserProfile) {
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
                  padding: const EdgeInsets.only(top: 40, bottom: 40, left: 20, right: 20),
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
                              text: isCurrentUserProfile
                                  ? '${category['name']}: ${category['tasksCount']}'
                                  : '${category['name']}',
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _noOfTodoAndDoneTasksForWeek,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor:AlwaysStoppedAnimation<Color>(profilePageColor),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final List<ChartData> barChartData = <ChartData>[
            ChartData('Monday', snapshot.data![0]['To do']?.toDouble(), snapshot.data![0]['Done']?.toDouble()),
            ChartData('Tuesday', snapshot.data![1]['To do']?.toDouble(), snapshot.data![1]['Done']?.toDouble()),
            ChartData('Wednesday', snapshot.data![2]['To do']?.toDouble(), snapshot.data![2]['Done']?.toDouble()),
            ChartData('Thursday', snapshot.data![3]['To do']?.toDouble(), snapshot.data![3]['Done']?.toDouble()),
            ChartData('Friday', snapshot.data![4]['To do']?.toDouble(), snapshot.data![4]['Done']?.toDouble()),
            ChartData('Saturday', snapshot.data![5]['To do']?.toDouble(), snapshot.data![5]['Done']?.toDouble()),
            ChartData('Sunday', snapshot.data![6]['To do']?.toDouble(), snapshot.data![6]['Done']?.toDouble()),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: Colors.grey.shade700),
                      onPressed: _previousWeek,
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: '$_startOfWeek - $_endOfWeek',
                        style: const TextStyle(
                          fontFamily: 'font1',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: Colors.grey.shade700),
                      onPressed: _nextWeek,
                    ),
                  ],
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
        } else {
          return const Center(
            child: Text('No data available'),
          );
        }
      },
    );
  }

}

class ChartData {
  ChartData(this.x, this.y, this.y1);
  final String x;
  final double? y;
  final double? y1;
}