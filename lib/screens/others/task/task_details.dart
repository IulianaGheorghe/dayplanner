import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../util/constants.dart';


class TaskDetails extends StatelessWidget{
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? deadline;
  final String priority;
  final LatLng? destination;
  final String status;

  const TaskDetails({super.key, required this.title, required this.description, required this.date, required this.startTime, required this.deadline, required this.priority, required this.destination, required this.status});

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
        title: const Text('Task Details',
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
            'assets/images/b2.jpg',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: const Text(
                      'Date',
                      style: TextStyle(color: Colors.grey),
                    ),
                    subtitle: Text(
                      DateFormat('EEEE, d MMMM').format(date),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (description != '')
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: const Text(
                        'Description',
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: Text(
                        description,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (startTime != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: const Text(
                        'Start Time',
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: Text(
                        '${startTime!.hour}:${startTime!.minute}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (deadline != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: const Text(
                        'Deadline',
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: Text(
                        '${deadline!.hour}:${deadline!.minute}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: const Text(
                      'Priority',
                      style: TextStyle(color: Colors.grey),
                    ),
                    subtitle: Text(
                      priority,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
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