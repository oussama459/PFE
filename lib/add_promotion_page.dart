import 'package:flutter/material.dart';

class AddPromotionPage extends StatefulWidget {
  final String userId; // Ajout de userId

  AddPromotionPage({required this.userId});

  @override
  _AddPromotionPageState createState() => _AddPromotionPageState();
}

class _AddPromotionPageState extends State<AddPromotionPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une Promotion")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Titre de la promotion"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Ici, tu peux ajouter la logique pour enregistrer la promotion
              },
              child: Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }
}
