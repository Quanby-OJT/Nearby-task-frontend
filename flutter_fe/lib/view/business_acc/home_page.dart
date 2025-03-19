import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';

import 'package:flutter_fe/view/nav/user_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController controller = CardSwiperController();
  List<UserModel> tasker = [];
  String? _errorMessage;
  int? cardNumber = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasker();
  }

  Future<void> _fetchTasker() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    ClientServices clientServices = ClientServices();
    List<UserModel> tasks = await clientServices.fetchAllTasker();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      tasker = tasks;
      cardNumber = tasks.length;
    });
  }

  void _cardCounter() {
    if (cardNumber == 0) {
      return;
    } else {
      setState(() {
        cardNumber = cardNumber! - 1;
      });
    }
  }

  Future<void> _saveLikedTasker(UserModel task) async {
    try {
      debugPrint("Printing..." + task.toString());
      if (task == null) {
        print("Cannot like task: Task ID is null for task: ${task.firstName}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot like task: Invalid task ID"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      ClientServices clientServices = ClientServices();

      final result = await clientServices.saveLikedTasker(task.id!);

      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("$e");
      debugPrintStack();

      // Show error indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save like. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NavUserScreen(),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(onPressed: _fetchTasker, child: Text('Retry')),
              ],
            ))
          else if (tasker.isEmpty)
            const Center(
              child: Text(
                "No taskers found",
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 35, top: 20),
                    child: SizedBox(
                      width: 200,
                    ),
                  ),
                ),
                Expanded(
                  child: CardSwiper(
                    allowedSwipeDirection: AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    controller: controller,
                    cardsCount: tasker.length,
                    onSwipe: (previousIndex, targetIndex, swipeDirection) {
                      if (swipeDirection == CardSwiperDirection.left) {
                        print("Swiped Left (Disliked)");
                        _cardCounter();
                      } else if (swipeDirection == CardSwiperDirection.right) {
                        _saveLikedTasker(tasker[previousIndex]);
                        _cardCounter();
                      }
                      return true;
                    },
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      final task = tasker[index];
                      return Center(
                        child: SizedBox(
                          height: double.infinity,
                          child: FlipCard(
                            direction: FlipDirection.HORIZONTAL,
                            front: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/image1.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            back: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${cardNumber?.toString()}" ?? "No Name",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0272B1),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Additional information about the service can go here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    Icon(
                                      Icons.touch_app,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                    Text(
                                      'Tap',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.swipe(CardSwiperDirection.left);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: CircleBorder(),
                        fixedSize: Size(60, 60),
                        padding: EdgeInsets.zero),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        weight: 4,
                        size: 30,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.swipe(CardSwiperDirection.right);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: CircleBorder(),
                      fixedSize: Size(60, 60),
                      padding: EdgeInsets.zero, // Remove default padding
                    ),
                    child: Center(
                      // Use Center instead of Align
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
