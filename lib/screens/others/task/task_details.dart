import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';
import 'edit_task.dart';


class TaskDetails extends StatelessWidget{
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? deadline;
  final String priority;
  final LatLng? destination;
  final String status;
  final String category;
  final List notificationIDs;
  final String id;

  const TaskDetails({super.key, required this.title, required this.description, required this.date, required this.startTime, required this.deadline, required this.priority, required this.destination, required this.status, required this.category, required this.notificationIDs, required this.id});

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
        backgroundColor: taskDetailsColor,
        centerTitle: true,
        title: const Text('Task Details',
          style: TextStyle(
              fontFamily: font1,
              fontSize: 23,
              color: Colors.black
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Edit task') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditTask(
                    index: 1,
                    title: title,
                    description: description,
                    category: category,
                    date: date,
                    priority: priority,
                    status: status,
                    startTime: startTime,
                    deadline: deadline,
                    destination: destination,
                    id: id,
                  ),),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                    value: 'Edit task',
                    child: Text('Edit task')
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
            'assets/images/trq.jpg',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width / 1.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: getColorForPriority(priority).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: font1,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2.0
                                    ..color = Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: font1,
                                  fontSize: 25,
                                  color: Colors.teal.shade100,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15,),
                          Text(
                            DateFormat('EEEE, d MMMM').format(date),
                            style: const TextStyle(
                              fontFamily: font1,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      )
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: detailsContainer("Category", category, TextAlign.center),),
                            const SizedBox(width: 16),
                            Expanded(child: detailsContainer("Status", status, TextAlign.center)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (description != '')
                          detailsContainer("Description", description, TextAlign.left),
                        const SizedBox(height: 16),
                        (startTime != null && deadline != null)
                          ? Row(
                            children: [
                              Expanded(child: detailsContainer("Start Time", '${startTime!.hour}:${startTime!.minute}', TextAlign.center),),
                              const SizedBox(width: 16),
                              Expanded(child: detailsContainer("Deadline", '${deadline!.hour}:${deadline!.minute}', TextAlign.center)),
                            ],
                          )
                          : (startTime != null)
                            ? detailsContainer("Start Time", '${startTime!.hour}:${startTime!.minute}', TextAlign.center)
                            : (deadline != null)
                              ? detailsContainer("Deadline", '${deadline!.hour}:${deadline!.minute}', TextAlign.center)
                              : Container(),
                        if (startTime != null || deadline != null)
                          const SizedBox(height: 16),
                        if (destination != null)
                          GestureDetector(
                            onTap: () {
                              launchGoogleMaps(destination!.latitude, destination!.longitude);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Image.asset(
                                    'assets/images/location.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                    top: 40,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width / 1.3,
                                      child: const Text(
                                        'View Route to Destination in Google Maps',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 21.0,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                ),
                                const Positioned(
                                  bottom: 25,
                                  child: Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 48.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void launchGoogleMaps(double destinationLat, double destinationLng) async {
    final Uri url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destinationLat,$destinationLng'
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}