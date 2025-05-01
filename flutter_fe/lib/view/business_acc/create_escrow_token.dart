import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';

import '../chat/payment.dart';

class EscrowTokenScreen extends StatefulWidget {
  const EscrowTokenScreen({super.key});

  @override
  State<EscrowTokenScreen> createState() => _EscrowTokenScreenState();
}

class _EscrowTokenScreenState extends State<EscrowTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final EscrowManagementController _escrowController = EscrowManagementController();
  bool isLoading = false;
  bool processingData = false;
  String userRole = "";
  final storage = GetStorage();

  //Initialize All Data
  @override
  void initState() {
    super.initState();
    setState(() {
      userRole = storage.read('user_role');
    });
  }

  @override
  void dispose() {
    _escrowController.dispose();
    setState(() {
      userRole = "";
    });
    super.dispose();
  }

  //Main Application
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Deposit Your Amount"),
        backgroundColor: Color(0XFF03045E),
        centerTitle: true,
        titleTextStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How much Would You Want to Deposit?",
                  style: GoogleFonts.roboto(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _escrowController.amountController,
                decoration: InputDecoration(
                    labelText: "Enter Amount (in Philippine Pesos)",
                    labelStyle: GoogleFonts.montserrat(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter your Amount to Deposit";
                  } else if (double.parse(value
                          .replaceAll("₱", "")
                          .replaceAll(",", "")) <
                      2000) {
                    return "Minimum Deposit is P2,000.00";
                  }
                  return null;
                },
                inputFormatters: [
                  CurrencyTextInputFormatter.currency(
                    locale: 'en_PH',
                    symbol: '₱',
                    decimalDigits: 2,
                  )
                ],
              ),
              SizedBox(height: 10),
              Text(
                "Current Price: P1.00 to 1 NearByTask Token",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ValueListenableBuilder(
                valueListenable: _escrowController.tokenCredits,
                builder: (context, value, child) {
                  return Text(
                    "You will receive: ${value.toStringAsFixed(0)} NearByTask Token/s to your account"
                        .replaceAllMapped(
                            RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[0]},'),
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                    ),
                  );
                },
              ),
              SizedBox(height: 30),
              Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(
                      FontAwesomeIcons.shield,
                      color: Color(0XFF4DBF66),
                    ),
                    SizedBox(width: 10),
                    Text("Payments secured via Escrow.")
                  ])),
              SizedBox(height: 30),
              Center(
                  child: ElevatedButton(
                      onPressed: () => warnUser(context),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Color(0XFF03045E)),
                      ),
                      child: Text("Deposit Amount",
                          style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)))),
              Text(
                  "NOTE: We will verify first your payment before you receive your NearByTask Credits.",
                  style: TextStyle(color: Colors.black38))
            ]
          )
        )
      )
    );
  }

  void warnUser(BuildContext parentContext) {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("ALERT: Does the Amount You Entered Sufficient?",
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      Navigator.of(dialogContext)
                          .pop(); // Use dialogContext to pop the dialog
                      return;
                    }

                    setState(() {
                      processingData = true;
                    });

                    try {
                      Navigator.of(dialogContext)
                          .pop(); // Use dialogContext to pop the dialog
                      ScaffoldMessenger.of(parentContext).showMaterialBanner(
                        // Use parentContext here
                        MaterialBanner(
                          backgroundColor: Color(0xFFD6932A),
                          content: Text(
                              "Please Wait while we process your transaction."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(parentContext)
                                    .hideCurrentMaterialBanner();
                              },
                              child: Text("Dismiss"),
                            ),
                          ],
                        ),
                      );

                      // Auto-dismiss the banner after 10 seconds
                      Future.delayed(Duration(seconds: 10), () {
                        ScaffoldMessenger.of(parentContext)
                            .hideCurrentMaterialBanner();
                        debugPrint("Material Banner Dismissed!");
                      });

                      Map<String, dynamic> result =
                          await _escrowController.depositAmountToEscrow();

                      if (result.containsKey("message")) {
                        ScaffoldMessenger.of(parentContext)
                            .hideCurrentMaterialBanner();
                        Navigator.push(
                          parentContext, // Use parentContext for navigation
                          MaterialPageRoute(
                            builder: (context) => EscrowPaymentScreen(
                              paymentUrl: result['payment_url'],
                            ),
                          ),
                        );
                      } else if (result.containsKey("error")) {
                        ScaffoldMessenger.of(parentContext)
                            .hideCurrentMaterialBanner();
                        debugPrint("Material Banner Dismissed!");
                        ScaffoldMessenger.of(parentContext).showMaterialBanner(
                          MaterialBanner(
                            content: Text(result['error']),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(parentContext)
                                      .hideCurrentMaterialBanner();
                                },
                                child: Text("Dismiss"),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      debugPrint(e.toString());
                      debugPrintStack(stackTrace: stackTrace);
                      ScaffoldMessenger.of(parentContext).showMaterialBanner(
                        MaterialBanner(
                          content: Text(
                              "An Error Occurred while we process your transaction. Please Try Again."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(parentContext)
                                    .hideCurrentMaterialBanner();
                              },
                              child: Text("Dismiss"),
                            ),
                          ],
                        ),
                      );

                      // Auto-dismiss the banner after 10 seconds
                      Future.delayed(Duration(seconds: 10), () {
                        ScaffoldMessenger.of(parentContext)
                            .hideCurrentMaterialBanner();
                        debugPrint("Material Banner Dismissed!");
                      });
                    } finally {
                      setState(() {
                        processingData = false;
                      });
                    }
                  },
                  child: Row(children: [
                    Icon(FontAwesomeIcons.piggyBank, color: Color(0XFF3E9B52)),
                    SizedBox(width: 10),
                    Text("I Have Enough Funds",
                        style: TextStyle(color: Color(0XFF3E9B52)))
                  ])),
              TextButton(
                  onPressed: Navigator.of(dialogContext).pop,
                  child: Row(children: [
                    Icon(
                      FontAwesomeIcons.xmark,
                      color: Color(0XFFD43D4D),
                    ),
                    SizedBox(width: 10),
                    Text("I don't Have Enough Funds",
                        style: TextStyle(
                          color: Color(0XFFD43D4D),
                        ))
                  ]))
            ],
          );
        });
  }
}
