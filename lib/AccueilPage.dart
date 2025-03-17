import 'package:flutter/material.dart';
import 'profile_page.dart';

class AccueilPage extends StatelessWidget {
  final String userId;
  final String nom;
  final String email;

  AccueilPage({required this.userId, required this.nom, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accueil"), backgroundColor: Colors.blue),
      body: Center(child: Text("Bienvenue, $nom 👋", style: TextStyle(fontSize: 22))),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(nom: nom, email: email, type: "client", boutiqueNom: "", boutiqueAdresse: "", userId: userId),
              ),
            );
          }
        },
      ),
    );
  }
}