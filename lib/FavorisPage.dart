import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AccueilPage.dart';
import 'profile_page.dart';
import 'login_page.dart';

class FavorisPage extends StatefulWidget {
  final String userId;
  final String nom;
  final String email;

  FavorisPage({required this.userId, required this.nom, required this.email});

  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List favoris = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchFavoris();
  }

  Future<void> _fetchFavoris() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.17/get_favoris.php?client_id=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        setState(() {
          favoris = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Erreur favoris: $e");
      setState(() => isLoading = false);
    }
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
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            userId: widget.userId,
            nom: widget.nom,
            email: widget.email,
            type: '',
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
      appBar: AppBar(title: Text("Mes Favoris"), backgroundColor: Colors.green),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoris.isEmpty
          ? Center(child: Text("Aucun favori trouvé."))
          : ListView.builder(
        itemCount: favoris.length,
        itemBuilder: (context, index) {
          final promo = favoris[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: promo['image'] != null
                  ? Image.network(promo['image'], width: 50, height: 50)
                  : Icon(Icons.image),
              title: Text(promo['categori'] ?? ""),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Du ${promo['date_debut']} au ${promo['date_fin']}"),
                  Text("Prix: ${promo['prix']} dt",
                      style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red)),
                  Text("Réduit: ${promo['prix_reduit']} dt",
                      style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          );
        },
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
}
