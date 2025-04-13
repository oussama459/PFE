import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'profile_page.dart';
import 'FavorisPage.dart';

import 'login_page.dart'; // pour redirection après déconnexion

class AccueilPage extends StatefulWidget {
  final String userId;
  final String nom;
  final String email;

  AccueilPage({required this.userId, required this.nom, required this.email});

  @override
  _AccueilPageState createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _selectedIndex = 0;

  List promotions = [];
  List filteredPromotions = [];

  Position? _userPosition;
  bool isLoading = true;

  List<String> categories = [
    "Électronique", "Animaux", "Vêtements", "Alimentation", "Beauté",
    "Maison", "Sport", "Jouets", "Auto-Moto", "Livres",
  ];
  String? selectedCategory;
  TextEditingController prixMaxController = TextEditingController();
  TextEditingController pourcentageMinController = TextEditingController();

  List<String> favoris = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchPromotions();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _userPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchPromotions() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.1.17/get_produits.php"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          promotions = data;
          filteredPromotions = promotions;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur de chargement: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() async {
    String baseUrl = "http://192.168.1.17/recherche.php";
    String url = "$baseUrl?categorie=${selectedCategory ?? ''}"
        "&prix_max=${prixMaxController.text.isEmpty ? '999999' : prixMaxController.text}"
        "&pourcentage_min=${pourcentageMinController.text.isEmpty ? '0' : pourcentageMinController.text}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isEmpty) _showAlert("Aucune promotion trouvée.");
        setState(() {
          filteredPromotions = data;
        });
      } else {
        _showAlert("Erreur de filtre.");
      }
    } catch (e) {
      _showAlert("Erreur de connexion.");
    }

    Navigator.pop(context);
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Info"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Filtres"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(labelText: "Catégorie"),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
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
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  Future<void> _toggleFavori(String promoId) async {
    final isAlreadyFavori = favoris.contains(promoId);

    setState(() {
      if (isAlreadyFavori) {
        favoris.remove(promoId);
      } else {
        favoris.add(promoId);
      }
    });

    if (!isAlreadyFavori) {
      // Enregistre uniquement si ce n'est pas déjà un favori
      try {
        final response = await http.post(
          Uri.parse("http://192.168.1.17/enregistrer_vue.php"),
          body: {
            'client_id': widget.userId,
            'promo_id': promoId,
          },
        );

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          print("Résultat: ${responseBody['status']}");
        } else {
          print("Erreur lors de l'enregistrement.");
        }
      } catch (e) {
        print("Erreur réseau: $e");
      }
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => FavorisPage(userId: widget.userId, nom: '', email: '',)));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(
        userId: widget.userId,
        nom: widget.nom,
        email: widget.email,
        type: '',
      )));
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accueil"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onTap: _showFilterDialog,
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
                final promoId = promo['promo_id'].toString();
                final isFavori = favoris.contains(promoId);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: promo['image'] != null && promo['image'].isNotEmpty
                        ? Image.network(promo['image'], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image, size: 50, color: Colors.grey),
                    title: Text(promo['categori'] ?? "Sans catégorie",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Du ${promo['date_debut']} au ${promo['date_fin']}"),
                        Text("Prix: ${promo['prix']} dt",
                            style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
                        Text("Prix réduit: ${promo['prix_reduit']} dt",
                            style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isFavori ? Icons.favorite : Icons.favorite_border,
                        color: isFavori ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavori(promoId),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
