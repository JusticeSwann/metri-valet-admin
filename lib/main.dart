import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                height:100,
                width:400,
                color: Colors.grey,
              
                child: const Center(child: Text("Shuttle Status:")),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     Container(
                        height:100,
                        width:200,
                        color: Colors.grey,         
                        child: const Center(child: Text("On route to Parking:")),
                      ),
                      Container(
                        height:100,
                        width:200,
                        color: Colors.grey,         
                        child: const Center(child: Text("Waiting at Parking:")),
                      ),
                   ],
                 ),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     Container(
                        height:100,
                        width:200,
                        color: Colors.grey,         
                        child: const Center(child: Text("At Venue:")),
                      ),
                      Container(
                        height:100,
                        width:200,
                        color: Colors.grey,         
                        child: const Center(child: Text("Waiting at Venue:")),
                      ),
                   ],
                 ),
                Container(
                height:100,
                width:400,
                color: Colors.grey,
              
                child: const Center(child: Text("Parking Lot")),
                ),
            ]
            ,)
        ),
      ),
    );
  }
}
