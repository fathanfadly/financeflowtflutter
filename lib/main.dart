import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Impor FirebaseAuth
import 'home.dart'; // Impor HomeScreen
import 'input.dart'; // Impor InputScreen
import 'profile.dart'; // Impor ProfileScreen
import 'package:cloud_firestore/cloud_firestore.dart';  // For Firestore database
import 'siteprofile.dart'; // Halaman EditProfilePage
import 'sitehelp.dart'; // Halaman SiteHelpPage
import 'sitesetting.dart'; // Halaman SettingPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome', // Mengarahkan ke halaman Welcome
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/auth': (context) => AuthScreen(), // Halaman login/sign-up
        '/menu': (context) => MenuScreen(), // Tambahkan route '/menu'
      },
    );
  }
}
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Navigasi otomatis dengan jeda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 3), () async {
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isNotEmpty) {
          DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (doc.exists && doc['is_logged_in'] == true) {
            Navigator.pushReplacementNamed(context, '/menu');
          } else {
            Navigator.pushReplacementNamed(context, '/auth');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      });
    });

    // Tampilan hanya logo
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.grey[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Image.asset(
            'asset/images/financeflow.png', // Ganti dengan path logo Anda
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  String _errorMessage = '';

  // Fungsi untuk sign-in
  Future<void> _signIn() async {
    try {
      // Logout terlebih dahulu jika ada sesi aktif
      await FirebaseAuth.instance.signOut();

      // Lanjutkan untuk login dengan akun baru
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Setel data pengguna di Firestore jika belum ada
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': 'New User', // Inisialisasi nama jika belum ada
          'id': uid,
          'finance_data': {
            'savings': 0.0,
            'monthly_money': 0.0,
          }, // Inisialisasi data keuangan
          'is_logged_in': true,  // Set status login menjadi true
        });
      } else {
        // Periksa jika pengguna lain sudah login, jika ya logout mereka
        if (userDoc['is_logged_in'] == true) {
          // Logout pengguna lain
          String otherUserId = userDoc['id'];
          await FirebaseFirestore.instance.collection('users').doc(otherUserId).update({
            'is_logged_in': false, // Logout pengguna lain
          });
        }

        // Update status login pengguna saat ini menjadi true
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'is_logged_in': true,
        });
      }

      // Navigasikan ke Menu utama setelah login berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Login failed";
      });
    }
  }
  // Fungsi untuk sign-up
  // Saat sign-up, menyimpan data pengguna di Firestore dengan uid sebagai ID dokumen
  Future<void> _signUp() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Mengecek apakah data pengguna sudah ada sebelumnya
      DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!snapshot.exists) {
        // Menyimpan data pengguna baru jika belum ada
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'id': uid,
          'is_logged_in': false, // Status login pertama kali
        });
      }

      // Login berhasil, update status is_logged_in
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_logged_in': true,
      });

      // Navigasikan ke halaman utama setelah sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Sign-up failed";
      });
    }
  }

  // Fungsi logout yang akan menghapus sesi
  Future<void> logout() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Setel is_logged_in menjadi false saat logout
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_logged_in': false,
      });

      // Logout pengguna di FirebaseAuth
      await FirebaseAuth.instance.signOut();
      print('Logout berhasil');

      // Kembali ke halaman login setelah logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    } catch (e) {
      print('Logout gagal: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ornamen latar belakang
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green[300]!, Colors.blue[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue[300]!, Colors.green[300]!],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          // Konten login
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'asset/images/financeflow.png',
                  height: 150, // Sesuaikan ukuran logo
                ),
                SizedBox(height: 20),
                Text(
                  "Selamat Datang di FinanceFlow",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signIn,
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _signUp,
                  child: Text(
                    'Belum punya akun? Sign Up',
                    style: TextStyle(color: Colors.blue[400]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    FinanceDashboard(), // Halaman Home
    CategorySelectionScreen(), // Halaman Input
    ProfileScreen(), // Halaman Profile
  ];

  // Fungsi logout yang akan menghapus sesi
  Future<void> logout() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Setel is_logged_in menjadi false saat logout
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_logged_in': false,
      });

      // Logout pengguna di FirebaseAuth
      await FirebaseAuth.instance.signOut();
      print('Logout berhasil');

      // Kembali ke halaman login setelah logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    } catch (e) {
      print('Logout gagal: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: Text("FinanceFlow"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout, // Menambahkan tombol logout di AppBar
          ),
        ],
      ),
      body: _pages[_currentIndex], // Menampilkan halaman sesuai dengan index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.input),
            label: "Input",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid; // Ambil userId dari FirebaseAuth

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[400],
        title: Text("Home"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId) // Ambil data berdasarkan uid
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No data available"));
          }

          var userData = snapshot.data!;
          double savings = userData['finance_data']['savings'] ?? 0.0;
          double monthlyMoney = userData['finance_data']['monthly_money'] ?? 0.0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${userData['name']}!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text('Savings: \$${savings.toString()}'),
                Text('Monthly Money: \$${monthlyMoney.toString()}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
class CategorySelectionScreen extends StatelessWidget {
  void _showOptionsDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Opsi untuk $category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputDataFormScreen(category: category, dataType: 'baru'),
                    ),
                  );
                },
                child: Text('Input Data Baru'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDataFormScreen(category: category),
                    ),
                  );
                },
                child: Text('Edit Data'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RekapDataScreen(category: category),
                    ),
                  );
                },
                child: Text('Lihat Rekap Data'),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showOptionsDialog(context, 'Tabungan'),
              child: Container(
                width: double.infinity,
                height: 100,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Center(
                  child: Text(
                    'Tabungan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showOptionsDialog(context, 'Uang Bulanan'),
              child: Container(
                width: double.infinity,
                height: 100,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Center(
                  child: Text(
                    'Uang Bulanan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    String userId = _auth.currentUser!.uid;  // Ambil userId yang sedang login
    String email = _auth.currentUser!.email ?? '';  // Ambil email pengguna

    // Ekstrak bagian sebelum "@" dari email
    String userName = email.split('@')[0];  // Ambil bagian sebelum '@'

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
            // Gunakan StreamBuilder untuk mengambil data pengguna dari Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)  // Ambil data berdasarkan userId
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Jika ada error
                if (snapshot.hasError) {
                  print("Error: ${snapshot.error}");
                  return Center(child: Text("Error loading profile"));
                }

                // Jika data tidak ada
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  print("No profile data available for user: $userId");
                  return Center(child: Text("No profile data available"));
                }

                // Data ditemukan, ambil data
                var userData = snapshot.data!;
                String userIdFromFirestore = userData['id'] ?? 'Unknown';  // Ambil id

                return Column(
                  children: [
                    Text(
                      userName,  // Menampilkan nama pengguna (email tanpa domain)
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ID: $userIdFromFirestore',  // Menampilkan ID
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 30),
            // Opsi profil lainnya (Edit Profil, Settings, dll)
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
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
