import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailConfirmation extends StatefulWidget {
  const EmailConfirmation({super.key});

  @override
  State<EmailConfirmation> createState() => _EmailConfirmation();
}

class _EmailConfirmation extends State<EmailConfirmation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  textAlign: TextAlign.center,
                  'An Email Has Been Sent to your Inbox',
                  style: TextStyle(
                      color: const Color(0xFF0272B1),
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                )),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Text(
                textAlign: TextAlign.justify,
                "Your Account has been Successfully Created. \n\n Please Check Your Inbox with your Provided Email. You are One Swipe Away to create a new task. \n\nIf you don't receive your email, this means that your email provided does not exist.",
                style: GoogleFonts.openSans(color: Colors.black, fontSize: 15),
              ),
            ),
          ]),
        ));
  }
}
