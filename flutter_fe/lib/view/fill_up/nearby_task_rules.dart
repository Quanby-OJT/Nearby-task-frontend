import 'package:flutter/material.dart';
import 'package:flutter_fe/view/service_acc/fill_up.dart';

class NearbyTaskRules extends StatefulWidget {
  final int userId;
  const NearbyTaskRules({super.key, required this.userId});

  @override
  State<NearbyTaskRules> createState() => _NearbyTaskRulesState();
}

class _NearbyTaskRulesState extends State<NearbyTaskRules> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "Welcome to NearByTask",
          ),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            //Welcome to Tinder pero TESDA
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Welcome to NearByTask",
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Be Mindful of the Rules as you are using this application.",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54),
                )),
            //Rule Number 1: Be Honest on your task
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Be Honest and Respectful.",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Ensure that your work, your interaction with your client/tasker as well as your task post (if you are a client) are fair, true and honest.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54),
                )),

            //Rule 2: Stay Safe.
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Stay Safe.",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Don't Rush Yourself when giving out your personal information. Swipe Safely.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54),
                )),

            //Rule 3: Be your best
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Be Your Best in Doing the Task.",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "You are not just doing the task but unleash your strategy, efficiency in finishing the task.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54),
                )),

            //Rule 4: Be Proactive
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Don't just post it on Social Media. Be Proactive.",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 10),
                child: Text(
                  "Always report anything that you think is suspicious.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54),
                )),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FillUpTaskerLogin()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0272B1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Let\'s Set Up Your Tasker Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        )));
  }
}
