import 'package:flutter/material.dart';
import 'siteprofile.dart'; // Import halaman EditProfilePage
import 'sitehelp.dart'; // Import halaman SiteHelpPage
import 'sitesetting.dart';  // Pastikan Anda mengimpor SettingPage
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';  // Firebase Core
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart';  // Firestore


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;  // Get current user ID from FirebaseAuth

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[400],

        title: Text("Profile"),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
            SizedBox(height: 20),
            // Use StreamBuilder to get data from Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text("No profile data available");
                }

                var userData = snapshot.data!;
                return Column(
                  children: [
                    Text(
                      userData['name'] ?? 'Guest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ID: ${userData['id'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 60),
            // Your Profile Options (Edit Profile, Settings, etc.)
            ProfileOption(
              icon: Icons.person,
              text: "Edit Profile",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
              },
            ),
            ProfileOption(
              icon: Icons.settings,
              text: "Setting",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
            ProfileOption(
              icon: Icons.help,
              text: "Help",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SiteHelpPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  ProfileOption({required this.icon, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.green[300],
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
