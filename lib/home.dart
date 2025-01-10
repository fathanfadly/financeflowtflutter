import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inisialisasi Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', // Menggunakan font kustom
      ),
      home: FinanceDashboard(),
    );
  }
}

class FinanceDashboard extends StatefulWidget {
  @override
  _FinanceDashboardState createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard> {
  double saldo = 0.0; // Total saldo (uang bulanan)
  double tabungan = 0.0; // Tabungan
  double uangBulanan = 0.0; // Uang bulanan
  double pengeluaran = 0.0; // Pengeluaran
  double progress = 0.0; // Progress bar
  bool isLoading = true; // Status loading data
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 2);

  List<Map<String, String>> transactions = [];
  List<Map<String, String>> pemasukanTransactions = [];
  PageController _pageController = PageController();

  void _updateProgress() {
    setState(() {
      if (saldo > 0) {
        progress = pengeluaran / saldo;
        progress = progress.clamp(0.0, 1.0); // Pastikan nilai antara 0 dan 1
      } else {
        progress = 0.0;
      }
    });
  }

  Future<void> _getDataFromFirebase() async {
    try {
      final database = FirebaseDatabase.instance.refFromURL('https://financeflow-45ab7-default-rtdb.firebaseio.com/');

      final snapshotTabungan = await database.child('tabungan').get();
      double newTabungan = 0.0;
      if (snapshotTabungan.exists) {
        var data = snapshotTabungan.value;
        if (data != null && data is Map) {
          data.forEach((key, value) {
            if (value != null && value['amount'] != null) {
              newTabungan += value['amount'];
            }
          });
        }
      }

      double newUangBulanan = 0.0;
      final snapshotUangBulanan = await database.child('uang_bulanan').get();
      if (snapshotUangBulanan.exists) {
        var uangBulananData = snapshotUangBulanan.value;
        if (uangBulananData != null && uangBulananData is Map) {
          uangBulananData.forEach((key, value) {
            if (value != null && value['amount'] != null) {
              newUangBulanan += value['amount'];
            }
          });
        }
      }

      setState(() {
        tabungan = newTabungan;
        uangBulanan = newUangBulanan;
        saldo = newUangBulanan;
      });

      await _fetchTransactions();
      _updateProgress();
    } catch (e) {
      print("Terjadi error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data')),
      );
    }
  }

  Future<void> _fetchTransactions() async {
    final database = FirebaseDatabase.instance.refFromURL('https://financeflow-45ab7-default-rtdb.firebaseio.com/');
    try {
      final snapshot = await database.child('transactions').get();
      if (snapshot.exists) {
        var transactionsData = snapshot.value;
        if (transactionsData != null && transactionsData is Map) {
          transactionsData.forEach((key, value) {
            if (value != null && value['amount'] != null && value['date'] != null) {
              String amount = value['amount'].toString();
              String date = value['date'].toString();
              String title = value['title'].toString();

              var transaction = {"title": title, "amount": amount, "date": date};
              transactions.add(transaction);

              if (double.tryParse(amount) != null && double.tryParse(amount)! > 0) {
                pemasukanTransactions.add(transaction);
              }
            }
          });
        }
      }
    } catch (e) {
      print("Gagal mengambil transaksi: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[100]!, Colors.green[300]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'asset/images/financeflow.png',
                            width: 100,
                            height: 100,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Tabungan", style: TextStyle(fontSize: 16, color: Colors.black54)),
                            Text(formatter.format(tabungan), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Pengeluaran", style: TextStyle(fontSize: 13, color: Colors.black54)),
                            Text("- ${formatter.format(pengeluaran)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Total Saldo: ${formatter.format(saldo)}",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mutasi Pemasukan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                });
                              },
                              icon: Icon(Icons.savings, color: Colors.white),
                              label: Text("Tabungan", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                                });
                              },
                              icon: Icon(Icons.attach_money, color: Colors.white),
                              label: Text("Uang Bulanan", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            children: [
                              TabunganPage(),
                              UangBulananPage(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabunganPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseDatabase.instance.ref('tabungan').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || (snapshot.data as DataSnapshot).value == null) {
          return Center(child: Text('Data tabungan kosong'));
        }

        // Ambil data tabungan dari Firebase
        final tabunganData = snapshot.data as DataSnapshot;
        List<Map<String, dynamic>> listTabungan = [];

        if (tabunganData.value != null && tabunganData.value is Map) {
          (tabunganData.value as Map).forEach((key, value) {
            listTabungan.add({
              'title': value['title'] ?? 'Tanpa Judul',
              'amount': value['amount'] ?? 0,
              'date': value['date'] ?? '-',
            });
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Tabungan"),
            backgroundColor: Colors.green,
          ),
          body: ListView.builder(
            itemCount: listTabungan.length,
            itemBuilder: (context, index) {
              final item = listTabungan[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.savings, color: Colors.green),
                  title: Text(
                    item['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tanggal: ${item['date']}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(item['amount']),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}



class UangBulananPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseDatabase.instance.ref('uang_bulanan').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || (snapshot.data as DataSnapshot).value == null) {
          return Center(child: Text('Data uang bulanan kosong'));
        }

        // Ambil data uang bulanan dari Firebase
        final uangBulananData = snapshot.data as DataSnapshot;
        List<Map<String, dynamic>> listUangBulanan = [];

        if (uangBulananData.value != null && uangBulananData.value is Map) {
          (uangBulananData.value as Map).forEach((key, value) {
            listUangBulanan.add({
              'title': value['title'] ?? 'Tanpa Judul',
              'amount': value['amount'] ?? 0,
              'date': value['date'] ?? '-',
            });
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Uang Bulanan"),
            backgroundColor: Colors.green,
          ),
          body: ListView.builder(
            itemCount: listUangBulanan.length,
            itemBuilder: (context, index) {
              final item = listUangBulanan[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.attach_money, color: Colors.green),
                  title: Text(
                    item['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tanggal: ${item['date']}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(item['amount']),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

