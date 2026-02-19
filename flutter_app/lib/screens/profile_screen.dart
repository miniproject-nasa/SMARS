import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Profile"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🔹 PROFILE PHOTO
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage("assets/profile.png"),
            ),

            const SizedBox(height: 16),

            /// 🔹 NAME
            const Text(
              "Ashiq Kareem",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 6),

            const Text("Patient ID: ASQKRM79"),

            const SizedBox(height: 30),

            /// 🔹 INFO CARDS
            _infoTile("Mobile", "9745215821"),
            _infoTile("Date of Birth", "26/08/1999"),
            _infoTile("Aadhar", "967081948207"),
            _infoTile(
              "Address",
              "Parambil (H.O), Vattoli Bazar (P.O), Thamarassery, Kozhikode",
            ),

            const Spacer(),

            /// 🔹 LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 INFO TILE
  static Widget _infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
