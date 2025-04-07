import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  Future<void> saveUserData(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'tigerStats': {
        'hunger': 50,
        'happiness': 50,
        'energy': 50,
        'lastUpdated': DateTime.now().toIso8601String(),
        'currentTigerImage': 'assets/images/tiger/tiger_normal.png',
        'currentBlinkImage': 'assets/images/tiger/tiger_normal_blink.png',
      },
      'foodInventory': {
        'bread': 2,
        'candy': 3,
        'cheese': 5,
      },
      'coins': 100,
      'level': 1,
      'experience': 0
    }, SetOptions(merge: true)); // Merge prevents overwriting existing data
  }

  // 🟡 Update food inventory (e.g., when buying food)
  Future<void> updateFoodInventory(String userId, String foodName, int quantity) async {
    await _firestore.collection('users').doc(userId).update({
      'foodInventory.$foodName': quantity,
    });
  }

  // 🟡 Update tiger stats (e.g., when feeding)
  Future<void> updateTigerStats(String userId, int hunger, int happiness) async {
    await _firestore.collection('users').doc(userId).update({
      'tigerStats.hunger': hunger.clamp(0, 100),
      'tigerStats.happiness': happiness.clamp(0, 100),
      'tigerStats.lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // 🟡 Fetch user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return null;
  }
}