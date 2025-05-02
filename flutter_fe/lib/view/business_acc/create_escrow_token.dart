import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';

import 'payment.dart';

enum CardType {
  Visa,
  MasterCard,
  AmericanExpress,
  Unknown,
}

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
  String selectedPaymentMethod = "";
  String selectedMonth = "";
  bool showCardDetails = false;
  String selectedYear = "";
  String? cardImagePath;
  CardType? _detectedCardType;

  //Initialize All Data
  @override
  void initState() {
    super.initState();
    setState(() {
      userRole = storage.read('role');
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

  CardType detectCardType(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^4[0-9]{6,}$').hasMatch(cleaned)) {
      return CardType.Visa;
    } else if (RegExp(r'^5[1-5][0-9]{5,}$').hasMatch(cleaned) ||
        RegExp(r'^2[2-7][0-9]{5,}$').hasMatch(cleaned)) {
      return CardType.MasterCard;
    } else if (RegExp(r'^3[47][0-9]{5,}$').hasMatch(cleaned)) {
      return CardType.AmericanExpress;
    }
    return CardType.Unknown;
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
      body: SingleChildScrollView(
          child: Padding(
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
                    fillColor: Color(0XFF2A1999),
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
                  "Current Price: P1.00 to 1 NearByTask Credit",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                ValueListenableBuilder(
                  valueListenable: _escrowController.tokenCredits,
                  builder: (context, value, child) {
                    return Text(
                      "You will receive: ${value.toStringAsFixed(0)} NearByTask Credit/s to your account"
                          .replaceAllMapped(
                              RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[0]},'),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: Text("How Would You Load to this system?",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center
                  ),
                ),
                SizedBox(height: 20),
                buildPaymentRow(
                    FontAwesomeIcons.creditCard,
                    null,
                    "Bank",
                    selectedPaymentMethod,
                    (newValue) {
                      setState(() {
                        selectedPaymentMethod = newValue;
                        showCardDetails = newValue == "Bank";
                      });
                    }
                ),
                if (showCardDetails) buildCardDetails(),
                buildPaymentRow(
                    null,
                    'assets/images/gcash-logo-png_seeklogo-522261.png',
                    "GCash",

                    selectedPaymentMethod,
                    (newValue) => setState(() => selectedPaymentMethod = newValue)
                ),
                buildPaymentRow(
                  null,
                  'assets/images/maya-logo_brandlogos.net_y6kkp-512x512.png',
                  "PayMaya",
                  selectedPaymentMethod,
                  (newValue) => setState(() => selectedPaymentMethod = newValue)
                ),
                SizedBox(height: 20),
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
                    ]
                  )
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () => debugPrint("This will redirect the user to confirm the payment."),
                    style: ButtonStyle(
                      backgroundColor:
                        WidgetStateProperty.all(Color(0XFF03045E)),
                    ),
                    child: Text("Deposit Amount",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      )
                    )
                  )
                )
              ]
            )
          )
        )
      )
    );
  }

  Widget buildCardDetails() {
    return Column(
      children: [
        buildInputField(
          _escrowController.cardNumberController,
          "Card Number",
          "xxxx xxxx xxxx xxxx",
          (value) {
            final detected = detectCardType(value);
            setState(() {
              _detectedCardType = detected;
              switch (detected) {
                case CardType.Visa:
                  cardImagePath = 'assets/images/cards/visa.png';
                  break;
                case CardType.MasterCard:
                  cardImagePath = 'assets/images/cards/mastercard.png';
                  break;
                case CardType.AmericanExpress:
                  cardImagePath = 'assets/images/cards/amex.png';
                  break;
                default:
                  cardImagePath = null;
              }
            });
          }
        ),
        SizedBox(height: 15),
        buildInputField(_escrowController.cardHolderNameController, "Card Holder Name", "", null),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: buildInputField(
                _escrowController.cvvController,
                "CVV",
                "Please Input CVV",
                null
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _escrowController.expiryDateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  fillColor: Color(0xff2A1999),
                  labelText: "Expiry Date (MM/YY)",
                  hintText: "MM/YY",
                  labelStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  ExpiryDateInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter expiry date";
                  }
                  final parts = value.split('/');
                  if (parts.length != 2) return "Invalid format";
                  final mm = int.tryParse(parts[0]) ?? 0;
                  final yy = int.tryParse(parts[1]) ?? 0;
                  if (mm < 1 || mm > 12) return "Invalid month";
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget buildInputField(TextEditingController controller, String label, String hint, ValueChanged<String>? onCardChanged){
    return TextFormField(
      controller: controller,
      onChanged: onCardChanged,
      decoration: InputDecoration(
        fillColor: Color(0xFF2A1999),
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.montserrat(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        )
      )
    );
  }

  Widget buildPaymentRow(IconData? paymentIcon, String? imageLink, String nameOfPayment, String groupValue, ValueChanged<String> onChanged) {
    return GestureDetector(
        onTap: () {
          onChanged(nameOfPayment);
        },
        child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if(paymentIcon != null) Icon(paymentIcon, size: 30,),
                  if(imageLink != null) Image.asset(imageLink, width: 30, height: 30),
                  SizedBox(width: 30),
                  Text(nameOfPayment, style: GoogleFonts.roboto(fontSize: 16)),
                ],
              ),
              Radio(
                value: nameOfPayment,
                groupValue: groupValue,
                onChanged: (newValue) {
                    onChanged(newValue!);
                },
              ),
            ],
          )
        )
      )
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.replaceAll("/", "");
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    String formatted = '';
    if (text.length >= 3) {
      formatted = '${text.substring(0, 2)}/${text.substring(2)}';
    } else if (text.isNotEmpty) {
      formatted = text;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
