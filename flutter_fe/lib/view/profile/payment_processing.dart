import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/escrow_management_controller.dart';
import '../../controller/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:signature/signature.dart';

class PaymentProcessingPage extends StatefulWidget {
  final String? transferMethod;
  final Uri? uri;
  const PaymentProcessingPage({super.key, this.transferMethod, this.uri});

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  final storage = GetStorage();
  bool isLoading = false;
  final EscrowManagementController _escrowController =
      EscrowManagementController();
  final ProfileController profileController = ProfileController();
  bool _isConfirmed = false;
  final String role = GetStorage().read("role");
  String _selectedPaymentMethod = '';
  final _formKey = GlobalKey<FormState>();
  int taskerId = 0;
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _handleDeepLink(widget.uri);
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  //For PayMongo Deposit
  Future<void> _handleDeepLink(Uri? uri) async {
    final amount = uri?.queryParameters['amount'];
    final transactionId = uri?.queryParameters['transaction_id'];

    if (amount != null && transactionId != null) {
      final String result = await _escrowController.validatePayment(
          true, storage.read("user_id"), transactionId, double.parse(amount));
      if (result ==
          "Your Payment has been Deposited Successfully. You can now create new Tasks.") {
        _showStatusModal(
            context,
            result,
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 70,
            ));

        if (role == "Tasker") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ServiceAccMain()),
            (route) => false,
          );
        } else if (role == "Client") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BusinessAccMain()),
            (route) => false,
          );
        }
      } else {
        _showStatusModal(
            context,
            result,
            Icon(
              Icons.error,
              color: Colors.red,
              size: 70,
            ));
      }
    } else {
      debugPrint("Payment Update Failed");
    }
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  Future<void> _processPayment(
      BuildContext parentContext, String paymentMethod) async {
    if (_selectedPaymentMethod.isEmpty || !mounted) {
      _showStatusModal(
          context,
          "Please Select a Payment Method",
          Icon(
            Icons.error,
            color: Colors.red,
          ));
      return;
    }
    Map<String, dynamic> result;
    _showStatusModal(context, "Please wait while we process your payment...",
        CircularProgressIndicator());

    setState(() {
      isLoading = true;
    });

    try {
      final storage = GetStorage();
      int userId = storage.read("user_id");

      if (widget.transferMethod == "deposit") {
        result = await _escrowController.depositAmountToEscrow(paymentMethod);
        // Handle the response
        final isSuccess = result['success'] ?? false;
        if (isSuccess) {
          final redirectUrl = result['payment_url'];
          if (redirectUrl != null) {
            final uri = Uri.parse(redirectUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              debugPrint("Cannot launch URL: $redirectUrl");
            }
          }
        } else {
          _showStatusModal(
              context,
              result['error'] ??
                  "An error occurred while processing your request. Please try again.",
              Icon(
                Icons.error,
                color: Colors.red,
              ));
        }
      } else if (widget.transferMethod == "withdraw") {
        result =
            await _escrowController.releaseEscrowPayment(userId, paymentMethod);
        // Handle the response
        final isSuccess = result['success'] ?? false;
        if (isSuccess) {
          _showStatusModal(
              context,
              result['message'] ?? "Successfully Withdrew Your Amount.",
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ));

          Future.delayed(Duration(seconds: 5), () {
            if (role == "Tasker") {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ServiceAccMain()),
                (route) => false,
              );
            } else if (role == "Client") {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => BusinessAccMain()),
                (route) => false,
              );
            }
          });
        } else {
          _showStatusModal(
              context,
              result['error'] ??
                  "An error occurred while processing your request. Please try again.",
              Icon(
                Icons.error,
                color: Colors.red,
              ));
        }
      } else {
        return;
      }
    } catch (e, stackTrace) {
      _showStatusModal(
          context,
          "A network error occurred. Please check your connection and try again.",
          Icon(
            Icons.error,
            color: Colors.red,
          ));
      debugPrint("Payment processing error: $e");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showStatusModal(
      BuildContext parentContext, String message, Widget indicator) {
    if (!mounted) return;

    showDialog(
        context: parentContext,
        builder: (BuildContext childContext) {
          Future.delayed(Duration(seconds: 10), () {
            Navigator.of(parentContext).pop();
          });

          return AlertDialog(
              content: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Row(children: [
                    indicator,
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF3C28CC),
                        ),
                      ),
                    )
                  ])));
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_signatureController.isEmpty) {
          return true;
        }
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Unsaved Changes',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                content: Text(
                    'Are you sure you want to go back? Your signature will be lost.',
                    style: GoogleFonts.poppins(fontSize: 14)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(color: Color(0xFF0272B1))),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Yes, go back',
                        style: GoogleFonts.poppins(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF0272B1)),
            onPressed: () async {
              if (_signatureController.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Unsaved Changes',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  content: Text(
                      'Are you sure you want to go back? Your signature will be lost.',
                      style: GoogleFonts.poppins(fontSize: 14)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: Color(0xFF0272B1))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes, go back',
                          style: GoogleFonts.poppins(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (shouldPop ?? false) {
                Navigator.of(context).pop();
              }
            },
          ),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      widget.transferMethod == "withdraw"
                          ? "How much would you like to withdraw?"
                          : "How much would you want to deposit?",
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Color(0xFF0272B1),
                          fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 10,
                  ),
                  //Amount to Deposit/Withdraw
                  _buildTextField(
                      controller: _escrowController.amountController,
                      label: "Enter Your Desired Amount",
                      icon: FontAwesomeIcons.pesoSign,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        switch (widget.transferMethod) {
                          case "withdraw":
                            if (value == null || value.isEmpty) {
                              return "Please enter an amount to withdraw.";
                            } else if (double.parse(value) > 20000) {
                              return "The Maximum Amount that you can withdraw is PHP 20,000.00.";
                            } else {
                              return null;
                            }
                          case "deposit":
                            if (value == null || value.isEmpty) {
                              return "Please enter an amount to deposit.";
                            } else if (double.parse(value) < 500) {
                              return "The Minimum Amount that you can deposit is P 500.00.";
                            } else if (double.parse(value) > 30000) {
                              return "The Maximum Amount that you can deposit is P 30,000.00.";
                            } else {
                              return null;
                            }
                          default:
                            return "Please Login Again.";
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ]),
                  SizedBox(height: 10),
                  if (widget.transferMethod == "withdraw")
                    Text(
                      "NOTE: The minimum amount that you can withdraw is P100.00, while the maximum amount that you can withdraw is PHP 20,000.00.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  if (widget.transferMethod == "deposit")
                    Text(
                      "NOTE: The minimum amount that you can deposit is PHP 500.00 and the maximum is PHP 30,000.00.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  //Select Payment/Withdraw Method
                  Center(
                      child: Text(
                    widget.transferMethod == "withdraw"
                        ? "Select Your Payment Withdrawal Method"
                        : "Select Your Method of Deposit",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Color(0xFF0272B1),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //This will be expanded as the user wants more payment methods.
                      //NextPay does not accept gcash as a payment method for withdrawal.
                      if (widget.transferMethod == "deposit") ...[
                        buildPaymentCard(
                            "GCash",
                            "assets/images/gcash-logo-png_seeklogo-522261.png",
                            null,
                            _selectPaymentMethod),
                      ],
                      buildPaymentCard(
                          "PayMaya",
                          "assets/images/maya-logo_brandlogos.net_y6kkp-512x512.png",
                          null,
                          _selectPaymentMethod),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (_selectedPaymentMethod.isNotEmpty) ...[
                    Text.rich(TextSpan(children: [
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
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ])),
                  ],
                  if (widget.transferMethod == "withdraw") ...[
                    _buildTextField(
                        controller: _escrowController.acctNumberController,
                        label:
                            "Enter Your Account Number based On Your Selected Withdrawal Method",
                        icon: FontAwesomeIcons.buildingColumns,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your account number.";
                          } else {
                            return null;
                          }
                        }),
                    SizedBox(height: 8),
                  ],
                  // Add signature pad for both deposit and withdraw
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF0272B1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "NOTE: Your signature will be compared with the one you provided during registration for verification purposes.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Signature',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0272B1),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _signatureController.clear();
                              },
                              child: Text(
                                'Clear',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF0272B1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  if (widget.transferMethod == "withdraw")
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
                        "I confirm that my details above are correct.",
                        style: GoogleFonts.poppins(
                          color: Color(0xFF0272B1),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.shield,
                        color: Colors.green.shade600,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        "Powered by PayMongo and NextPay.",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: (_isConfirmed && !isLoading)
                        ? () async {
                            // Button is enabled only if _isConfirmed is true and isLoading is false
                            if (_selectedPaymentMethod.isEmpty) {
                              _showStatusModal(
                                  context,
                                  "Please Select Your Desired Payment Method",
                                  Icon(
                                    FontAwesomeIcons.circleExclamation,
                                    color: Color(0XFFE23670),
                                    size: 50,
                                  ));
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              _showConfirmationDialog(
                                  context, Color(0XFFE23670));
                            }
                          }
                        : null, // Button is disabled if _isConfirmed is false or isLoading is true
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFD3D3D3); // Disabled color
                        }
                        return const Color(0xFF3C28CC);
                      }),
                    ),
                    child: Text(
                        widget.transferMethod == "withdraw"
                            ? "Withdraw Amount"
                            : "Deposit Amount",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPaymentCard(String title, String? imageLink, IconData? icon,
      Function(String) onMethodSelected) {
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
                    child: Column(children: [
                      if (imageLink != null)
                        Image.asset(imageLink, height: 60, width: 60),
                      if (icon != null)
                        Icon(icon, size: 70, color: Colors.black38),
                      const SizedBox(height: 10),
                      Text(title, style: GoogleFonts.poppins(fontSize: 18)),
                    ])))));
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
                child: Column(children: [
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
                ])),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processPayment(context, _selectedPaymentMethod);
                },
                child: Text("Proceed",
                    style: GoogleFonts.poppins(color: Color(0XFFE23670))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel",
                    style: GoogleFonts.poppins(color: Color(0XFFE23670))),
              )
            ],
          );
        });
  }
}
