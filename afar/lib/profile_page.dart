import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  ProfilePage({required this.userData, required String nom, required String email, required String type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil de ${userData['nom']}")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom: ${userData['nom']}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Email: ${userData['email']}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Type: ${userData['type']}", style: TextStyle(fontSize: 18)),
            if (userData['type'] == "commercant" && userData.containsKey("boutique_nom")) ...[
              SizedBox(height: 10),
              Text("Nom de la boutique: ${userData['boutique_nom']}", style: TextStyle(fontSize: 18)),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Déconnexion"),
            ),
          ],
        ),
      ),
    );
  }
}
