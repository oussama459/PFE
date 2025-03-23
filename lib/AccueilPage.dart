import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'profile_page.dart';

class AccueilPage extends StatefulWidget {
  final String userId;
  final String nom;
  final String email;

  AccueilPage({required this.userId, required this.nom, required this.email});

  @override
  _AccueilPageState createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  List promotions = [];
  List filteredPromotions = [];
  List<String> categories = ["Électronique","Animaux","Vêtements","Alimentation","Beauté",
    "Maison","Sport","Jouets","Auto-Moto","Livres",];

  String? selectedCategory;
  TextEditingController prixMaxController = TextEditingController();
  TextEditingController pourcentageMinController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  // 🔹 Récupérer toutes les promotions depuis l'API PHP
  Future<void> _fetchPromotions() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.1.13/get_produits.php"));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          promotions = data;
          filteredPromotions = promotions;
          isLoading = false;
        });
      } else {
        throw Exception("Erreur lors du chargement des promotions.");
      }
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🔹 Appliquer les filtres
  void _applyFilters() async {
    String baseUrl = "http://192.168.1.13/recherche.php";
    String url = "$baseUrl?categorie=${selectedCategory ?? ''}"
        "&prix_max=${prixMaxController.text.isEmpty ? '999999' : prixMaxController.text}"
        "&pourcentage_min=${pourcentageMinController.text.isEmpty ? '0' : pourcentageMinController.text}";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);

        if (data.isEmpty) {
          _showAlert("Aucune promotion trouvée avec ces filtres.");
        }

        setState(() {
          filteredPromotions = data;
        });
      } else {
        _showAlert("Erreur lors de la récupération des promotions.");
      }
    } catch (e) {
      _showAlert("Problème de connexion au serveur.");
    }

    Navigator.pop(context); // Fermer la boîte de dialogue après l'application des filtres
  }

  // 🔹 Afficher une alerte
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Information"),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
          ],
        );
      },
    );
  }

  // 🔹 Afficher la boîte de dialogue des filtres
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Filtres"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(labelText: "Catégorie"),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              TextField(
                controller: prixMaxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Prix Max"),
              ),
              TextField(
                controller: pourcentageMinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Pourcentage Min"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
            TextButton(onPressed: _applyFilters, child: Text("Appliquer")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accueil"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onTap: _showFilterDialog, // 🔹 Afficher la boîte de filtres au clic
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Rechercher une promotion...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredPromotions.isEmpty
                ? Center(child: Text("Aucune promotion trouvée."))
                : ListView.builder(
              itemCount: filteredPromotions.length,
              itemBuilder: (context, index) {
                final promo = filteredPromotions[index];

                double prix = double.tryParse(promo['prix'] ?? '0') ?? 0;
                double pourcentage = double.tryParse(promo['pourcentage'] ?? '0') ?? 0;
                double prixReduit = prix - ((pourcentage * prix) / 100);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: promo['image'] != null && promo['image'].isNotEmpty
                        ? Image.network(
                      promo['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : Icon(Icons.image, size: 50, color: Colors.grey),
                    title: Text(
                      promo['categori'] ?? "Sans catégorie",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Du ${promo['date_debut']} au ${promo['date_fin']}"),
                        Text(
                          "Prix: ${prix.toStringAsFixed(2)} dt",
                          style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red),
                        ),
                        Text(
                          "Nouveau Prix: ${prixReduit.toStringAsFixed(2)} dt",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                builder: (context) => ProfilePage(
                  nom: widget.nom,
                  email: widget.email,
                  type: "client",
                  boutiqueNom: "",
                  boutiqueAdresse: "",
                  userId: widget.userId,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
