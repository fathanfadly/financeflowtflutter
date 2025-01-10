import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

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
      home: CategorySelectionScreen(),
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
        title: Text('Pilih Kategori'),
        backgroundColor: Colors.green[400],
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

class EditDataFormScreen extends StatelessWidget {
  final String category;

  EditDataFormScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data $category'),
        backgroundColor: Colors.green[400],
        centerTitle: true,
      ),
      body: Center(
        child: Text('Halaman untuk mengedit data $category'),
      ),
    );
  }
}

class RekapDataScreen extends StatelessWidget {
  final String category;

  RekapDataScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    final databaseReference = FirebaseDatabase.instance.ref('tabungan');

    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Data $category'),
        backgroundColor: Colors.green[400],
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: databaseReference.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('Tidak ada data tersedia'));
          }

          var data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          var items = data.entries.map((entry) {
            String key = entry.key;
            var value = entry.value;
            return ListTile(
              title: Text('Jumlah: ${value['amount']}'),
              subtitle: Text('Deskripsi: ${value['description']}\nTanggal: ${value['date']}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // Hapus data dari Firebase berdasarkan key
                  try {
                    await databaseReference.child(key).remove();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data berhasil dihapus')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus data')),
                    );
                  }
                },
              ),
            );
          }).toList();

          return ListView(
            children: items,
          );
        },
      ),
    );
  }
}


class InputDataFormScreen extends StatelessWidget {
  final String category;
  final String dataType;

  InputDataFormScreen({required this.category, required this.dataType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Data $category'),
        backgroundColor: Colors.green[400],
        centerTitle: true,
      ),
      body: category == 'Tabungan'
          ? InputTabunganDataScreen()
          : InputUangBulananDataScreen(),
    );
  }
}

class InputTabunganDataScreen extends StatefulWidget {
  @override
  _InputTabunganDataScreenState createState() => _InputTabunganDataScreenState();
}

class _InputTabunganDataScreenState extends State<InputTabunganDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedDate;

  // List of months and years
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _years = [
    '2023', '2024', '2025', '2026', '2027', '2028'
  ];

  // Default current date
  String currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

  Future<void> _sendData() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Pastikan tanggal tidak null, jika null gunakan currentDate
        String dateToSend = _selectedDate ?? currentDate;

        final database = FirebaseDatabase.instance.refFromURL('https://financeflow-45ab7-default-rtdb.firebaseio.com/');
        await database.child('tabungan').push().set({
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'description': _descriptionController.text,
          'timestamp': DateTime.now().toIso8601String(),
          'date': dateToSend,  // Pastikan tanggal tidak null
          'month': _selectedMonth ?? 'Januari', // Bulan
          'year': _selectedYear ?? '2024', // Tahun
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data Tabungan berhasil dikirim')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error sending data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim data')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Tabungan',
                  hintText: 'Masukkan jumlah tabungan',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan jumlah';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Masukkan deskripsi tabungan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan deskripsi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDate,
                items: List.generate(31, (index) {
                  return DropdownMenuItem<String>(
                    value: (index + 1).toString(),
                    child: Text('${index + 1}'),
                  );
                }),
                onChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
                decoration: InputDecoration(
                    labelText: 'Pilih Tanggal'
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (newMonth) {
                  setState(() {
                    _selectedMonth = newMonth;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Bulan',
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                items: _years.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (newYear) {
                  setState(() {
                    _selectedYear = newYear;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Tahun',
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _sendData,
                child: Text('Kirim Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputUangBulananDataScreen extends StatefulWidget {
  @override
  _InputUangBulananDataScreenState createState() => _InputUangBulananDataScreenState();
}

class _InputUangBulananDataScreenState extends State<InputUangBulananDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedDate;

  // List of months and years
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _years = [
    '2023', '2024', '2025', '2026', '2027', '2028'
  ];

  // Default current date
  String currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

  Future<void> _sendData() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final database = FirebaseDatabase.instance.refFromURL('https://financeflow-45ab7-default-rtdb.firebaseio.com/');
        await database.child('uang_bulanan').push().set({
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'category': _categoryController.text,
          'timestamp': DateTime.now().toIso8601String(),
          'date': _selectedDate ?? currentDate,  // Tanggal
          'month': _selectedMonth ?? 'Januari', // Bulan
          'year': _selectedYear ?? '2024', // Tahun
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data Uang Bulanan berhasil dikirim')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error sending data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Uang Bulanan',
                  hintText: 'Masukkan jumlah uang bulanan',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan jumlah';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Masukkan kategori uang bulanan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan kategori';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDate,
                items: List.generate(31, (index) {
                  return DropdownMenuItem<String>(
                    value: (index + 1).toString(),
                    child: Text('${index + 1}'),
                  );
                }),
                onChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Tanggal', // Menampilkan label "Pilih Tanggal"
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (newMonth) {
                  setState(() {
                    _selectedMonth = newMonth;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Bulan',
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                items: _years.map((year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (newYear) {
                  setState(() {
                    _selectedYear = newYear;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Tahun',
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _sendData,
                child: Text('Kirim Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
