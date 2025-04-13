import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'promotion_page.dart';
import 'AccueilPage.dart';
import 'FavorisPage.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String nom;
  final String email;
  final String type;
  final String boutiqueNom;
  final String boutiqueAdresse;

  ProfilePage({
    required this.userId,
    required this.nom,
    required this.email,
    required this.type,
    this.boutiqueNom = "",
    this.boutiqueAdresse = "",
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('profile_image_${widget.userId}');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _imagePath = savedPath;
        _imageFile = File(savedPath);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final savedPath = await _saveImage(File(pickedFile.path));
      setState(() {
        _imageFile = File(savedPath);
        _imagePath = savedPath;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profile_image_${widget.userId}', savedPath);
    }
  }

  Future<String> _saveImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/profile_${widget.userId}.jpg';
    await image.copy(path);
    return path;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccueilPage(
            userId: widget.userId,
            nom: widget.nom,
            email: widget.email,
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FavorisPage(
            userId: widget.userId,
            nom: widget.nom,
            email: widget.email,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileImage(),
            SizedBox(height: 20),
            _buildUserInfo(),
            if (widget.type == "commercant" &&
                widget.boutiqueNom.isNotEmpty &&
                widget.boutiqueAdresse.isNotEmpty)
              _buildShopInfo(),
            SizedBox(height: 20),
            if (widget.type == "commercant") _buildPromotionButton(),
            SizedBox(height: 30),
            _buildLogoutButton(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Déconnexion'),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: _imagePath != null
            ? FileImage(File(_imagePath!))
            : AssetImage('images/default-profile.jpg') as ImageProvider,
        child: _imagePath == null
            ? Icon(Icons.camera_alt, size: 40, color: Colors.white70)
            : null,
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.person, "Nom", widget.nom),
            Divider(),
            _infoRow(Icons.email, "Email", widget.email),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations de la boutique",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 12),
            _infoRow(Icons.store, "Boutique", widget.boutiqueNom),
            Divider(),
            _infoRow(Icons.location_on, "Adresse", widget.boutiqueAdresse),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromotionPage(
              userId: widget.userId,
              boutiqueNom: widget.boutiqueNom,
            ),
          ),
        );
      },
      icon: Icon(Icons.campaign, color: Colors.white),
      label: Text("Mes Promotions"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      },
      icon: Icon(Icons.logout, color: Colors.white),
      label: Text("Se Déconnecter"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "$label : $value",
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
