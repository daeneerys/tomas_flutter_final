import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Tiger Mood
  int hunger = 50;
  int happiness = 50;
  int energy = 50;

  //Tiger Animation

  bool isBlinking = false;
  bool isMoodChanging = false;

  //TigerBlinking Image
  String currentTigerImage = 'assets/images/tiger/tiger_normal.png';
  String currentBlinkImage = 'assets/images/tiger/tiger_normal_blink.png';

  //Food
  String? droppedFoodImage; // Store food image when feeding
  int selectedFoodIndex = 0;

  List<String> foodKeys = [
    'bread', 'candy', 'cheese', 'chocolate', 'eggs',
    'hotdogsandwich', 'icecream', 'meat', 'nuggetsfries',
    'pizza', 'salad', 'salmon'
  ];

  Map<String, int> foodInventory = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBlinking();
    _startMoodChanging();
  }

  Future<void> _loadData() async{
    try{
      DocumentSnapshot snapshot = await _firestore.collection('pet_data').doc('stats').get();
      if(snapshot.exists){
        setState(() {
          hunger = snapshot ["hunger"];
          happiness = snapshot ["happiness"];
          energy = snapshot ["energy"];
          foodInventory = Map<String, int>.from(snapshot['foodInventory']);
          currentTigerImage = snapshot["currentTigerImage"] ?? 'assets/images/tiger/tiger_normal.png';
          currentBlinkImage = snapshot["currentBlinkImage"] ?? 'assets/images/tiger/tiger_normal_blink.png';
        });
      }
    } catch (e){
      print("Error loading data: $e");
    }
  }

  Future<void> _updateDatabase() async {
    try {
      await _firestore.collection('pet_data').doc('stats').update({
        'hunger': hunger,
        'happiness': happiness,
        'energy': energy,
        'foodInventory': foodInventory,
        'currentTigerImage': currentTigerImage,
        'currentBlinkImage': currentBlinkImage,
      });
    } catch (e) {
      print("Error updating database: $e");
    }
  }

  void _startBlinking() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        isBlinking = true;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        setState(() {
          isBlinking = false;
        });
      });
    });
  }

  void _startMoodChanging() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _changeMood((happiness - 5).clamp(0, 100));
    });
  }

  void _changeMood(int newHappiness) {
    setState(() {
      isMoodChanging = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        happiness = newHappiness;

        if (happiness > 50) {
          currentTigerImage = 'assets/images/tiger/tiger_happy.png';
          currentBlinkImage = 'assets/images/tiger/tiger_blink.png';
        } else if (happiness == 50) {
          currentTigerImage = 'assets/images/tiger/tiger_normal.png';
          currentBlinkImage = 'assets/images/tiger/tiger_normal_blink.png';
        } else {
          currentTigerImage = 'assets/images/tiger/tiger_sad.png';
          currentBlinkImage = 'assets/images/tiger/tiger_sad_blink.png';
        }
      });

      // Save updated mood and images to Firestore
      _updateDatabase();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        isMoodChanging = false;
      });
    });
  }

  void feedTiger(String food) {
    if (foodInventory[food]! > 0) {
      setState(() {
        // Reduce food count
        foodInventory[food] = (foodInventory[food]! - 1).clamp(0, 99);

        // Increase Happiness
        _changeMood((happiness + 10).clamp(0, 100));

        // Show food animation near tiger
        droppedFoodImage = 'assets/images/foods/${food}_food.png';
      });

      // Update Firestore with new values
      _updateDatabase();

      // Remove food after animation
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => droppedFoodImage = null);
      });
    }
  }

  void navigateFood(int direction) {
    setState(() {
      selectedFoodIndex = (selectedFoodIndex + direction) % foodKeys.length;
      if (selectedFoodIndex < 0) selectedFoodIndex = foodKeys.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedFood = foodKeys[selectedFoodIndex];

    return Scaffold(
      backgroundColor: Colors.green[300],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green),
                        Text('100', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildStatBox('Hunger', hunger, Colors.yellow),
                      const SizedBox(width: 20),
                      buildStatBox('Happiness', happiness, Colors.yellow),
                      const SizedBox(width: 20),
                      buildStatBox('Energy', energy, Colors.yellow),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        Text('Lv. 5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 5),
                        Icon(Icons.star, color: Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DragTarget<String>(
                      onAccept: (food) => feedTiger(food), // Feeding logic
                      builder: (context, candidateData, rejectedData) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(currentTigerImage, height: 200),
                            AnimatedOpacity(
                              opacity: isBlinking ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Image.asset(currentBlinkImage, height: 200),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Food Navigation & Dragging
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, size: 40),
                    onPressed: () => navigateFood(-1),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Draggable<String>(
                      data: selectedFood,
                      feedback: Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                      childWhenDragging: SizedBox(
                        height: 100,
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                          Text('${foodInventory[selectedFood]}'),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, size: 40),
                    onPressed: () => navigateFood(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatBox(String label, int value, Color fillColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 40,
                height: (value / 100) * 40,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Text('$value%', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}