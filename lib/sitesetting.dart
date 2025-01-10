// setting_page.dart
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkMode = false; // Variabel untuk pengaturan tema gelap
  bool _isNotificationsEnabled = true; // Variabel untuk pengaturan notifikasi
  bool _isLocationEnabled = true; // Variabel untuk pengaturan lokasi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Tombol back akan mengarah ke halaman ProfileScreen
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Opsi Tema Gelap
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
              secondary: Icon(Icons.nightlight_round),
            ),

            // Opsi Notifikasi
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _isNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isNotificationsEnabled = value;
                });
              },
              secondary: Icon(Icons.notifications),
            ),

            // Opsi Lokasi
            SwitchListTile(
              title: Text('Enable Location'),
              value: _isLocationEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isLocationEnabled = value;
                });
              },
              secondary: Icon(Icons.location_on),
            ),

            Divider(), // Pemisah antar opsi pengaturan



            Divider(), // Pemisah lainnya

            // Opsi Logout
          ],
        ),
      ),
    );
  }
}
