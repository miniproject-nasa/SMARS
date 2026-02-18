import 'package:flutter/material.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage("assets/profile.png"), 
                    // if you don’t have image yet, comment this line
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "You are",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        "Ashiq Kareem",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const Spacer(),

            /// 🔹 BIG SOS BUTTON
            Center(
              child: GestureDetector(
                onTap: () {
                  // later connect alert service
                },
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue, width: 5),
                  ),
                  child: const Center(
                    child: Text(
                      "SOS",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Alert Send",
              style: TextStyle(
                color: primaryBlue,
                fontSize: 16,
              ),
            ),

            const Spacer(),

          ],
        ),
      ),

      /// 🔹 FLOATING ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () {},
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔹 BOTTOM NAV BAR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, color: primaryBlue),
                  SizedBox(height: 4),
                  Text("Home", style: TextStyle(color: primaryBlue))
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: primaryBlue),
                  SizedBox(height: 4),
                  Text("Chatbot", style: TextStyle(color: primaryBlue))
                ],
              ),

              SizedBox(width: 40), // space for FAB

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_outlined, color: primaryBlue),
                  SizedBox(height: 4),
                  Text("Alert", style: TextStyle(color: primaryBlue))
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_outlined, color: primaryBlue),
                  SizedBox(height: 4),
                  Text("Games", style: TextStyle(color: primaryBlue))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
