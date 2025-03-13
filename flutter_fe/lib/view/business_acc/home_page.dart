import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController controller = CardSwiperController();
  List<String> searchCategories = [
    'All',
    'Cleaning',
    'Delivery',
    'Repair',
    'Moving'
  ];
  List<String> selectedCategories = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NavUserScreen(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 35, top: 20),
                  child: SizedBox(
                    width: 200,
                    // child: DropdownSearch<String>.multiSelection(
                    //   items: searchCategories,
                    //   selectedItems: selectedCategories,
                    //   dropdownDecoratorProps: DropDownDecoratorProps(
                    //     dropdownSearchDecoration: InputDecoration(
                    //       prefixIcon: Icon(Icons.search),
                    //       filled: true,
                    //       fillColor: Color(0xFFF1F4FF),
                    //       hintText: 'Search...',
                    //       hintStyle: TextStyle(color: Colors.grey),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderSide:
                    //             BorderSide(color: Colors.transparent, width: 0),
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(10),
                    //         borderSide:
                    //             BorderSide(color: Color(0xFF0272B1), width: 2),
                    //       ),
                    //     ),
                    //   ),
                    //   popupProps: PopupPropsMultiSelection.menu(
                    //     scrollbarProps: ScrollbarProps(
                    //       thickness: 8,
                    //       radius: Radius.circular(10),
                    //     ),
                    //
                    //     showSelectedItems:
                    //         false, // This hides selected items from search field
                    //     showSearchBox: true,
                    //     fit: FlexFit.loose,
                    //
                    //     itemBuilder: (context, item, isSelected) {
                    //       return Container(
                    //         padding: EdgeInsets.symmetric(
                    //             horizontal: 16, vertical: 8),
                    //         child: Row(
                    //           children: [
                    //             Checkbox(
                    //               value: isSelected,
                    //               hoverColor: Color(0xFF0272B1),
                    //               activeColor: Color(0xFF0272B1),
                    //               onChanged: null,
                    //             ),
                    //             SizedBox(width: 8),
                    //             Text(
                    //               item,
                    //               style: TextStyle(
                    //                 fontWeight: isSelected
                    //                     ? FontWeight.bold
                    //                     : FontWeight.normal,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       );
                    //     },
                    //   ),
                    //   onChanged: (List<String> selectedItems) {
                    //     setState(() {
                    //       selectedCategories = selectedItems;
                    //     });
                    //   },
                    // ),
                  ),
                ),
              ),
              Expanded(
                //height: 450,
                child: CardSwiper(
                  allowedSwipeDirection: AllowedSwipeDirection.only(
                    left: true,
                    right: true,
                  ),
                  controller: controller,
                  cardsCount: 3,
                  onSwipe: (previousIndex, targetIndex, swipeDirection) {
                    if (swipeDirection == CardSwiperDirection.left) {
                      print("Swiped Left (Disliked)");
                    } else if (swipeDirection == CardSwiperDirection.right) {
                      print("Swiped Right (Liked)");
                    }
                    return true;
                  },
                  cardBuilder:
                      (context, index, percentThresholdX, percentThresholdY) {
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
                                    'Service Details',
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
