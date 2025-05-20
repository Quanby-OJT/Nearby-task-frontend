import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/view/business_acc/home_page.dart';
import 'package:flutter_fe/view/service_acc/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/escrow_management_controller.dart';
import '../../controller/profile_controller.dart';
import '../../model/auth_user.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentProcessingPage extends StatefulWidget {
  final String transferMethod;
  const PaymentProcessingPage({super.key, required this.transferMethod});

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  final storage = GetStorage();
  bool isLoading = true;
  final EscrowManagementController _escrowController = EscrowManagementController();
  final ProfileController profileController = ProfileController();
  bool _isConfirmed = false;
  final String role = GetStorage().read("role");
  String _selectedPaymentMethod = '';
  bool _isMethodSelected = false;
  final _formKey = GlobalKey<FormState>();
  int taskerId = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initDeepLinkListener();
    fetchTaskerClientId();
  }

  void _initDeepLinkListener() async{
    final appLinks = AppLinks();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try{
      final Uri? redirectUrl = await appLinks.getInitialLink();

      if(redirectUrl != null){
        _handleDeepLink(redirectUrl);
      }
    }catch(e, stackTrace){
      debugPrint("Error getting initial link: $e");
      debugPrintStack(stackTrace: stackTrace);
      _showBanner(scaffoldMessenger, "AN Error Occurred while validating Your Payment.", Colors.red);
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final amount = uri.queryParameters['amount'];
    final transactionId = uri.queryParameters['transaction_id'];

    if (amount != null && transactionId != null) {
      switch(uri.host){
        case "payment-success":
          final String result = await _escrowController.validatePayment(true, storage.read("user_id"), transactionId, double.parse(amount));
          if(result == "Your Payment has been successfully processed."){
            _showBanner(ScaffoldMessenger.of(context), result, Colors.green);

            if(role == "Tasker"){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => TaskerHomePage()
                ),
              );
            }else if(role == "Client"){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ClientHomePage()
                ),
              );
            }
          }else{
            _showBanner(ScaffoldMessenger.of(context), result, Colors.red);
          }
          break;
        case "payment-failure":
          final isSuccess = await _escrowController.validatePayment(false, storage.read("user_id"), transactionId, double.parse(amount));
          _showBanner(ScaffoldMessenger.of(context), isSuccess, Colors.red);
          break;
        default:
          debugPrint("Unknown deep link: $uri");
          break;
      }
    } else {
      debugPrint("Payment Update Failed");
    }
  }

  Future<void> fetchTaskerClientId() async {
    try {
      String role = storage.read("role");
      int userId = storage.read("user_id");
      AuthenticatedUser? user = await profileController.getAuthenticatedUser(context, userId);

      if(role == "Tasker"){
        debugPrint("Tasker ID: ${user?.tasker?.id}");
        setState(() {
          taskerId = user?.tasker?.id ?? 0;
        });
      }else if(role == "Client"){
        setState(() {
          taskerId = 0;
        });
      }
    }catch(e, stackTrace) {
      debugPrint("Error fetching user data: $e");
      debugPrint("Stack Trace: $stackTrace");
      setState(() => isLoading = false);
    }
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
      _isMethodSelected = true;
    });
  }

  Future<void> _processPayment(BuildContext parentContext, String paymentMethod) async {
    if (_selectedPaymentMethod.isEmpty || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
    final isClient = role == "Client";
    Map<String, dynamic> result;

    try {
      _showBanner(scaffoldMessenger, "Please wait while we process your payment...", Colors.yellow);

      if (isClient) {
        result = await _escrowController.depositAmountToEscrow(paymentMethod);
      } else {
        result = await _escrowController.releaseEscrowPayment(taskerId, paymentMethod);
      }
      // Handle the response
      final isSuccess = result['success'] ?? false;
      if (isSuccess) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        final redirectUrl = result['payment_url'];
        if (redirectUrl != null) {
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            scaffoldMessenger.hideCurrentMaterialBanner();
          } else {
            debugPrint("Cannot launch URL: $redirectUrl");
          }
        }
      } else {
        _showBanner(scaffoldMessenger, result['error'] ?? "An error occurred while processing your request. Please try again.", Colors.red);
      }
    } catch (e, stackTrace) {
      _showBanner(scaffoldMessenger, "A network error occurred. Please check your connection and try again.", Colors.red);
      debugPrint("Payment processing error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showBanner(ScaffoldMessengerState scaffoldMessenger, String message, Color backgroundColor) {
    if (!mounted) return;
    scaffoldMessenger.showMaterialBanner(
      // Add a timer to dismiss the banner after 5 seconds
      MaterialBanner(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        actions: [
          TextButton(
            onPressed: () => scaffoldMessenger.hideCurrentMaterialBanner(),
            child: Text("Dismiss", style: GoogleFonts.poppins(color: Colors.white)),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'QTask Escrow',
          style: GoogleFonts.montserrat(
            color: Color(0xFF0272B1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        primary: false,
        child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                    children: [
                      Text(
                          widget.transferMethod == "withdraw" ? "How much would you like to withdraw?" : "How much would you want to deposit?",
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Color(0xFF0272B1),
                              fontWeight: FontWeight.bold
                          )
                      ),
                      SizedBox(height: 10,),
                      //Amount to Deposit/Withdraw
                      _buildTextField(
                        controller: _escrowController.amountController,
                        label: "Enter Your Desired Amount",
                        icon: FontAwesomeIcons.pesoSign,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          switch(widget.transferMethod){
                            case "withdraw":
                              if(value == null || value.isEmpty){
                                return "Please enter an amount to withdraw.";
                              }else if(double.parse(value) > 20000){
                                return "The Maximum Amount that you can withdraw is PHP 20,000.00.";
                              }else{
                                return null;
                              }
                            case "deposit":
                              if(value == null || value.isEmpty){
                                return "Please enter an amount to deposit.";
                              }else if(double.parse(value) < 500){
                                return "The Minimum Amount that you can deposit is P 500.00.";
                              }else if(double.parse(value) > 30000){
                                return "The Maximum Amount that you can deposit is P 30,000.00.";
                              }else{
                                return null;
                              }
                            default:
                              return "Please Login Again.";
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ]
                      ),
                      SizedBox(height: 10),
                      if(widget.transferMethod == "withdraw") Text(
                        "NOTE: The minimum amount that you can withdraw is P100.00, while the maximum amount that you can withdraw is PHP 20,000.00.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      if(widget.transferMethod == "deposit") Text(
                        "NOTE: The minimum amount that you can deposit is PHP 500.00 and the maximum is PHP 30,000.00.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 20,),
                      //Select Payment/Withdraw Method
                      Center(
                        child: Text(
                          widget.transferMethod == "withdraw" ? "Select Your Payment Withdrawal Method" : "Select Your Method of Deposit",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Color(0xFF0272B1),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //This will be expanded as the user wants more payment methods.
                          buildPaymentCard(
                              "GCash",
                              "assets/images/gcash-logo-png_seeklogo-522261.png",
                              null,
                              _selectPaymentMethod),
                          buildPaymentCard(
                              "PayMaya",
                              "assets/images/maya-logo_brandlogos.net_y6kkp-512x512.png",
                              null,
                              _selectPaymentMethod),
                        ],
                      ),
                      SizedBox(height: 10),
                      if(_selectedPaymentMethod.isNotEmpty)...[
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "You have Chosen: ",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: _selectedPaymentMethod,
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ]
                          )
                        ),
                      ],
                      if(widget.transferMethod == "withdraw")...[
                        _buildTextField(
                            controller: _escrowController.acctNumberController,
                            label: "Enter Your Account Number based On Your Selected Withdrawal Method",
                            icon: FontAwesomeIcons.buildingColumns,
                            validator: (value) {
                              if(value == null || value.isEmpty){
                                return "Please enter your account number.";
                              }else{
                                return null;
                              }
                            }
                        ),
                      ],
                      SizedBox(height: 8),
                      Text(
                        "NOTE: You will receive your amount to your wallet within 1-2 business days.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      //Confirmation Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Color(0XFF3C28CC),
                            ),
                            child: Checkbox(
                              value: _isConfirmed,
                              activeColor: Color(0XFF3C28CC),
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _isConfirmed = newValue!;
                                });
                              },
                            ),
                          ),
                          Text(
                            "I confirm that I entered the right amount from the system.",
                            style: GoogleFonts.poppins(
                              color: Color(0xFF0272B1),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: _isConfirmed ? () async{
                          if(_formKey.currentState!.validate()){
                            _showConfirmationDialog(context, Color(0XFFE23670));
                          }
                        } : null,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return const Color(0xFFD3D3D3);
                                }
                                return const Color(0xFF3C28CC);
                              }),
                        ),
                        child: Text(
                            widget.transferMethod == "withdraw" ? "Withdraw Amount" : "Deposit Amount",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            )
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.shield,
                            color: Colors.green.shade600,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Payments Secured via PayMongo and NextPay.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      )
                    ]
                )
            )
        ),
      )
    );
  }

  Widget buildPaymentCard(String title, String? imageLink, IconData? icon, Function(String) onMethodSelected) {
    final isSelected = _selectedPaymentMethod == title;
    return Card(
        elevation: 2,
        color: isSelected ? Color(0xFFF1F4FF) : Colors.white,
        child: InkWell(
            onTap: () {
              if (!isSelected) {
                onMethodSelected(title);
              } else {
                onMethodSelected('');
              }
            },
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    height: 100,
                    width: MediaQuery.of(context).size.width * 0.38,
                    child: Column(
                        children: [
                          if (imageLink != null)
                            Image.asset(imageLink, height: 60, width: 60),
                          if (icon != null)
                            Icon(icon, size: 30, color: Colors.black38),
                          const SizedBox(height: 10),
                          Text(title, style: GoogleFonts.poppins(fontSize: 18)),
                        ]
                    )
                )
            )
        )
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0272B1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hintText,
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext parentContext, Color iconColor) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.18,
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.circleExclamation,
                  size: 50,
                  color: iconColor,
                ),
                SizedBox(height: 12),
                Text(
                  "You will be redirected to your $_selectedPaymentMethod Application to complete the payment process.",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF3C28CC),
                  ),
                  textAlign: TextAlign.center,
                )
              ]
            )
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPayment(context, _selectedPaymentMethod);
              },
              child: Text(
                "Proceed",
                style: GoogleFonts.poppins(
                  color: Color(0XFFE23670)
                )
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Color(0XFFE23670)
                )
              ),
            )
          ],
        );
      }
    );
  }
}
