import 'package:flutter/material.dart';

class SiteHelpPage extends StatefulWidget {
  @override
  _SiteHelpPageState createState() => _SiteHelpPageState();
}

class _SiteHelpPageState extends State<SiteHelpPage> {
  bool isFAQSelected = true; // Untuk mengatur apakah tab FAQ dipilih
  String selectedCategory = 'General'; // Kategori yang terpilih

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQs'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: Colors.green,
            child: Center(
              child: Text(
                'How Can We Help You?',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Tab Section
          Container(
            color: Colors.green.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('FAQ', isFAQSelected),
                _buildTabButton('Contact Us', !isFAQSelected),
              ],
            ),
          ),

          // Category Filter Section
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton('General', selectedCategory == 'General'),
                _buildCategoryButton('Account', selectedCategory == 'Account'),
                _buildCategoryButton('Services', selectedCategory == 'Services'),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          // FAQ List
          Expanded(
            child: ListView(
              children: _buildFAQList(),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membangun tombol tab
  Widget _buildTabButton(String title, bool isSelected) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.green.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        setState(() {
          isFAQSelected = title == 'FAQ';
        });
      },
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.green,
        ),
      ),
    );
  }

  // Fungsi untuk membangun tombol kategori
  Widget _buildCategoryButton(String title, bool isSelected) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white,
        side: BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.green,
        ),
      ),
    );
  }

  // Fungsi untuk membangun daftar FAQ
  List<Widget> _buildFAQList() {
    List<String> faqList = [];

    if (selectedCategory == 'General') {
      faqList = [
        'How to use FinWise?',
        'How much does it cost to use FinWise?',
        'Can I use the app offline?',
      ];
    } else if (selectedCategory == 'Account') {
      faqList = [
        'How can I reset my password if I forget it?',
        'How do I delete my account?',
      ];
    } else if (selectedCategory == 'Services') {
      faqList = [
        'Can I customize settings within the application?',
        'How do I access my expense history?',
      ];
    }

    return faqList
        .map((question) => _buildFAQItem(question))
        .toList();
  }

  // Fungsi untuk membangun item FAQ
  Widget _buildFAQItem(String question) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Answer to the question will go here.'),
        ),
      ],
    );
  }
}
