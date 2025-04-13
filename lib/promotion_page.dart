import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PromotionPage extends StatefulWidget {
  final String userId;
  final String boutiqueNom;

  PromotionPage({required this.userId, required this.boutiqueNom});

  @override
  _PromotionPageState createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  List<Map<String, dynamic>> promotions = [];
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  final TextEditingController _categoriController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _pourcentageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  /// 🔹 Récupérer toutes les promotions depuis la base
  Future<void> _fetchPromotions() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.17/get_promotions.php?commercant_id=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          setState(() {
            promotions = List<Map<String, dynamic>>.from(data);
          });
        } else {
          print("Erreur: ${data['message']}");
        }
      }
    } catch (e) {
      print("Erreur de chargement: $e");
    }
  }

  /// 🔹 Sélectionner une image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// 🔹 Ajouter une promotion
  Future<void> _ajouterPromotion() async {
    if (_categoriController.text.isEmpty ||
        _dateDebutController.text.isEmpty ||
        _dateFinController.text.isEmpty ||
        _prixController.text.isEmpty ||
        _pourcentageController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs et ajouter une image")),
      );
      return;
    }

    // Vérification du pourcentage
    int pourcentage = int.tryParse(_pourcentageController.text) ?? 0;
    if (pourcentage < 10 || pourcentage > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Le pourcentage doit être entre 10% et 90%")),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.1.17/add_promotion.php"),
    );

    request.fields['commercant_id'] = widget.userId;
    request.fields['categori'] = _categoriController.text;
    request.fields['date_debut'] = _dateDebutController.text;
    request.fields['date_fin'] = _dateFinController.text;
    request.fields['prix'] = _prixController.text;
    request.fields['pourcentage'] = _pourcentageController.text;

    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['success'] == true) {
        setState(() {
          promotions.add({
            'id': jsonResponse['id'],
            'categori': _categoriController.text,
            'date_debut': _dateDebutController.text,
            'date_fin': _dateFinController.text,
            'prix': _prixController.text,
            'pourcentage': _pourcentageController.text,
            'image': jsonResponse['image_url'],
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Promotion ajoutée avec succès")),
        );

        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau: $e")),
      );
    }
  }



  /// 🔹 Supprimer une promotion avec confirmation
  Future<void> _supprimerPromotion(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Êtes-vous sûr de vouloir supprimer cette promotion ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                final promotionId = promotions[index]['id'];
                try {
                  final promotionId = promotions[index]['promo_id']; // Utiliser promo_id au lieu de id
                  final response = await http.delete(
                    Uri.parse("http://192.168.1.17/supprimer_promotion.php?promo_id=$promotionId"),
                  );


                  if (response.statusCode == 200) {
                    var data = json.decode(response.body);
                    if (data['success'] == true) {
                      setState(() {
                        promotions.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("✅ Promotion supprimée avec succès")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ Erreur: ${data['message']}")),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur réseau: $e")),
                  );
                }
              },
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  /// 🔹 Modifier une promotion
  Future<void> _modifierPromotion(int index) async {
    if (_categoriController.text.isEmpty ||
        _dateDebutController.text.isEmpty ||
        _dateFinController.text.isEmpty ||
        _prixController.text.isEmpty ||
        _pourcentageController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs et ajouter une image")),
      );
      return;
    }
    Future<void> _ajouterPromotion() async {
      if (_categoriController.text.isEmpty ||
          _dateDebutController.text.isEmpty ||
          _dateFinController.text.isEmpty ||
          _prixController.text.isEmpty ||
          _pourcentageController.text.isEmpty ||
          _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veuillez remplir tous les champs et ajouter une image")),
        );
        return;
      }

      // Vérification du pourcentage
      int pourcentage = int.tryParse(_pourcentageController.text) ?? 0;
      if (pourcentage < 10 || pourcentage > 90) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Le pourcentage doit être entre 10% et 90%")),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://192.168.1.17/add_promotion.php"),
      );

      request.fields['commercant_id'] = widget.userId;
      request.fields['categori'] = _categoriController.text;
      request.fields['date_debut'] = _dateDebutController.text;
      request.fields['date_fin'] = _dateFinController.text;
      request.fields['prix'] = _prixController.text;
      request.fields['pourcentage'] = _pourcentageController.text;

      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      try {
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['success'] == true) {
          setState(() {
            promotions.add({
              'id': jsonResponse['id'],
              'categori': _categoriController.text,
              'date_debut': _dateDebutController.text,
              'date_fin': _dateFinController.text,
              'prix': _prixController.text,
              'pourcentage': _pourcentageController.text,
              'image': jsonResponse['image_url'],
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Promotion ajoutée avec succès")),
          );

          _resetForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Erreur: ${jsonResponse['message']}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur réseau: $e")),
        );
      }
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://192.168.1.17/modifier_promotion.php"),
    );

    request.fields['promo_id'] = promotions[index]['promo_id'].toString();
    request.fields['commercant_id'] = widget.userId;
    request.fields['categori'] = _categoriController.text;
    request.fields['date_debut'] = _dateDebutController.text;
    request.fields['date_fin'] = _dateFinController.text;
    request.fields['prix'] = _prixController.text;
    request.fields['pourcentage'] = _pourcentageController.text;

    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['success'] == true) {
        setState(() {
          promotions[index] = {
            'id': promotions[index]['id'],
            'categori': _categoriController.text,
            'date_debut': _dateDebutController.text,
            'date_fin': _dateFinController.text,
            'prix': _prixController.text,
            'pourcentage': _pourcentageController.text,
            'image': jsonResponse['image_url'],
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Promotion modifiée avec succès")),
        );

        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau: $e")),
      );
    }
  }

  /// 🔹 Réinitialiser le formulaire
  void _resetForm() {
    _categoriController.clear();
    _dateDebutController.clear();
    _dateFinController.clear();
    _prixController.clear();
    _pourcentageController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mes Promotions"),
        backgroundColor: Colors.green,
      ),
      body: promotions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          double prix = double.parse(promotions[index]['prix']);
          double pourcentage = double.parse(promotions[index]['pourcentage']);
          double prixReduit = prix - ((pourcentage * prix) / 100);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              leading: promotions[index]['image'] != null
                  ? Image.network(promotions[index]['image'], width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 50, color: Colors.grey),
              title: Text(promotions[index]['categori']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Du ${promotions[index]['date_debut']} au ${promotions[index]['date_fin']}"),
                  Text(
                    "Prix: ${prix.toStringAsFixed(2)} dt",
                    style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red),
                  ),
                  Text("Nouveau Prix: ${prixReduit.toStringAsFixed(2)} dt", style: TextStyle(color: Colors.green)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAddPromotionForm(isEditing: true, index: index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _supprimerPromotion(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromotionForm(isEditing: false),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 🔹 Afficher le formulaire d'ajout ou de modification de promotion
  void _showAddPromotionForm({bool isEditing = false, int? index}) {
    List<String> categories = [
      "Électronique",
      "Animaux",
      "Vêtements",
      "Alimentation",
      "Beauté",
      "Maison",
      "Sport",
      "Jouets",
      "Auto-Moto",
      "Livres",
    ];

    String? selectedCategory = isEditing ? promotions[index!]['categori'] : null;
    DateTime now = DateTime.now();
    if (!isEditing) {
      _dateDebutController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }
    if (isEditing) {
      DateTime now = DateTime.now();
      _dateDebutController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.grey, size: 50),
                      SizedBox(height: 8),
                      Text("Ajouter une image", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(labelText: "Catégorie"),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              TextField(
                controller: _dateDebutController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Date début"),
              ),
              TextField(
                controller: _dateFinController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date fin",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    setState(() {
                      _dateFinController.text = formattedDate;
                    });
                  }
                },
              ),
              TextField(controller: _prixController, decoration: InputDecoration(labelText: "Prix")),
              TextField(controller: _pourcentageController, decoration: InputDecoration(labelText: "Pourcentage")),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Veuillez sélectionner une catégorie")),
                    );
                    return;
                  }
                  _categoriController.text = selectedCategory!;
                  if (isEditing) {
                    _modifierPromotion(index!);
                  } else {
                    _ajouterPromotion();
                  }
                },
                child: Text(isEditing ? "Modifier" : "Publier"),
              ),
            ],
          ),
        );
      },
    );
  }
}