import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  final dataService = FirestoreService();
  runApp(MainApp(dataService: dataService));
}


abstract class DataService {
  Stream<List<UserData>> getUsersForParkingLot(String lotNumber);
}


class UserData {
  final String status;
  final String parkingLot;

  UserData({required this.status, required this.parkingLot});
}

 
class FirestoreService implements DataService {
  @override
  Stream<List<UserData>> getUsersForParkingLot(String lotNumber) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('parkingLot', isEqualTo: lotNumber)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return UserData(
              status: data['status'] ?? '',
              parkingLot: data['parkingLot'] ?? '',
            );
          }).toList();
        });
  }
}

class MainApp extends StatelessWidget {
  final DataService dataService;
  
  const MainApp({
    super.key, 
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ShuttleMonitoringScreen(dataService: dataService),
    );
  }
}

class ShuttleMonitoringScreen extends StatefulWidget {
  final DataService dataService;
  
  const ShuttleMonitoringScreen({
    super.key,
    required this.dataService,
  });

  @override
  State<ShuttleMonitoringScreen> createState() => _ShuttleMonitoringScreenState();
}

class _ShuttleMonitoringScreenState extends State<ShuttleMonitoringScreen> {
  String currentParkingLot = '1'; 
  String shuttleStatus = 'Waiting'; 
  int onRouteToParkingCount = 0;
  int waitingAtParkingCount = 0;
  int atVenueCount = 0;
  int waitingAtVenueCount = 0;
  bool isLoading = true;
  
  StreamSubscription<List<UserData>>? _usersSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchParkingLotData();
    
   
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchParkingLotData();
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void fetchParkingLotData() {
    setState(() {
      isLoading = true;
    });
    
  
    _usersSubscription?.cancel();
    
   
    setState(() {
      onRouteToParkingCount = 0;
      waitingAtParkingCount = 0;
      atVenueCount = 0;
      waitingAtVenueCount = 0;
    });
    
    _usersSubscription = widget.dataService
        .getUsersForParkingLot(currentParkingLot)
        .listen(
          (users) {
            updateStatusCounts(users);
            setState(() {
              isLoading = false;
            });
          }
        );
  }
  
  void updateStatusCounts(List<UserData> users) {
    int onRoute = 0;
    int waitingParking = 0;
    int atVenue = 0;
    int waitingVenue = 0;
    String shuttleStatusText = 'Waiting';
    

    for (var user in users) {
      switch (user.status.toLowerCase()) {
        case 'on route to parking':
          onRoute++;
          break;
        case 'waiting at parking':
          waitingParking++;
          break;
        case 'at venue':
          atVenue++;
          break;
        case 'waiting at venue':
          waitingVenue++;
          break;
      }
      
      if (onRoute > 0) {
        shuttleStatusText = 'Approaching';
      } else if (waitingParking > 0 || waitingVenue > 0) {
        shuttleStatusText = 'Waiting';
      }
    }
    
    setState(() {
      onRouteToParkingCount = onRoute;
      waitingAtParkingCount = waitingParking;
      atVenueCount = atVenue;
      waitingAtVenueCount = waitingVenue;
      shuttleStatus = shuttleStatusText;
    });
  }
  
  void changeParkingLot(String newLot) {
    setState(() {
      currentParkingLot = newLot;
    });
    fetchParkingLotData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Status Monitor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 100,
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        "Shuttle Status: $shuttleStatus",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatusBox(
                        title: "On route to Parking",
                        count: onRouteToParkingCount,
                        lotNumber: currentParkingLot,
                      ),
                      StatusBox(
                        title: "Waiting at Parking",
                        count: waitingAtParkingCount,
                        lotNumber: currentParkingLot,
                      ),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatusBox(
                        title: "At Venue",
                        count: atVenueCount,
                        lotNumber: currentParkingLot,
                      ),
                      StatusBox(
                        title: "Waiting at venue",
                        count: waitingAtVenueCount,
                        lotNumber: currentParkingLot,
                      ),
                    ],
                  ),
                  
                  Container(
                    height: 100,
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Parking Lot $currentParkingLot",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.change_circle, size: 30),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ParkingLotSelector(
                                currentLot: currentParkingLot,
                                onSelect: (lot) {
                                  changeParkingLot(lot);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class StatusBox extends StatelessWidget {
  final String title;
  final int count;
  final String lotNumber;

  const StatusBox({
    super.key,
    required this.title,
    required this.count,
    required this.lotNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class ParkingLotSelector extends StatelessWidget {
  final String currentLot;
  final Function(String) onSelect;

  const ParkingLotSelector({
    super.key,
    required this.currentLot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Parking Lot'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 3, 
          itemBuilder: (context, index) {
            final lotNumber = (index + 1).toString();
            return ListTile(
              title: Text('Parking Lot $lotNumber'),
              selected: lotNumber == currentLot,
              onTap: () => onSelect(lotNumber),
            );
          },
        ),
      ),
    );
  }
}