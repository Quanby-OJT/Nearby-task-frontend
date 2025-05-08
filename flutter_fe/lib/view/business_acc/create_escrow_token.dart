import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';

import 'payment.dart';

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

  // Define the payment options
  final List<String> _paymentOptions = [
    'GCash',
    'PayMaya',];

  @override
  void initState() {
    super.initState();
    setState(() {
      _escrowController.tokenCredits.value = 0;
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
                    String formattedValue = value.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'), (Match m) => '${m[0]},');

                    return RichText(
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.black
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: formattedValue,
                            style: GoogleFonts.barlow(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Color(0XFF2A1999)
                            ),
                          ),
                          TextSpan(text: ' IMONALICK Credit/s will be added to your account'),
                        ],


                      ),
                    );
                  },
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Methods",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      Text(
                        "We Accept the following secure payment methods:",
                        style: GoogleFonts.roboto()
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ///If the user demands we must provide additional payment methods, it will be placed here.
                          ///
                          /// -Ces
                          Image.asset('assets/images/gcash-logo-png_seeklogo-522261.png', height: 48, width: 48),
                          Image.asset('assets/images/maya-logo_brandlogos.net_y6kkp-512x512.png', height: 48, width: 48),
                          // SizedBox(width: 10,),
                          // SvgPicture.asset('assets/images/card-logos/Mastercard-logo.svg', height: 48, width: 48),
                          // SizedBox(width: 10,),
                          // SvgPicture.asset('assets/images/card-logos/visa-logo-svg-vector.svg', height: 48, width: 48),
                        ],
                      ),
                    ],
                  )
                ),
                SizedBox(height: 20),
                Center(
                  child: Text("How will you deposit your amount?",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Payment Method',
                    hintText: '--Select Payment Method--',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  value: selectedPaymentMethod.isEmpty ? null : selectedPaymentMethod,
                  items: _paymentOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          if(value == "GCash")
                            Image.asset('assets/images/gcash-logo-png_seeklogo-522261.png', height: 24, width: 24,),
                          if(value == "PayMaya")
                            Image.asset('assets/images/maya-logo_brandlogos.net_y6kkp-512x512.png', height: 24, width: 24,),
                          SizedBox(width: 10),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedPaymentMethod = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a payment method';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                if(selectedPaymentMethod == "GCash") Text("You will be redirected to your GCash Application."),
                if(selectedPaymentMethod == "PayMaya") Text("You will be redirected to your PayMaya Application."),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async{
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showMaterialBanner(
                            MaterialBanner(
                                content: Text(
                                  "Please Wait while We Process Your Payment.",
                                  style: GoogleFonts.barlow(
                                      color: Colors.white),),
                                backgroundColor: Color(0XFFD6932A),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentMaterialBanner();
                                      },
                                      child: Text("Dismiss")
                                  )
                                ]
                            )
                        );
                        Map<String, dynamic> response = await _escrowController.depositAmountToEscrow(selectedPaymentMethod);

                        if(response.containsKey("success") && response["success"]){
                          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EscrowPaymentScreen(paymentUrl: response["payment_url"])
                            )
                          );
                        }else{
                          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                          ScaffoldMessenger.of(context).showMaterialBanner(
                            MaterialBanner(
                              backgroundColor: Color(0XFFD6932A),
                              content: Text(response['error'] ?? "An Error Occurred while processing Your Payment."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                                  },
                                  child: Text("Dismiss")
                                )
                              ]
                            )
                          );
                        }
                      }
                    },
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
                ),

              ]
            )
          )
        )
      )
    );
  }


  Widget buildInputField(
      TextEditingController controller,
      Widget? suffixIcon,
      String label,
      String hint,
      ValueChanged<String>? onCardChanged
  ){
    return TextFormField(
      controller: controller,
      onChanged: onCardChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        suffixIcon: suffixIcon != null ? Container(
          padding: EdgeInsets.only(right: 10.0),
          child: suffixIcon,
        ) : null,
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.montserrat(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
