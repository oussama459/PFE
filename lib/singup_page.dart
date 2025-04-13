import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController nom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController boutiqueNom = TextEditingController();
  TextEditingController adresse = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";
  String _userType = "Client"; // Par défaut

  Future<void> _signup() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });

    if (nom.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir tous les champs requis.";
        _isLoading = false;
      });
      return;
    }

    if (password.text != confirmPassword.text) {
      setState(() {
        _errorMessage = "Les mots de passe ne correspondent pas.";
        _isLoading = false;
      });
      return;
    }

    String uri = "http://192.168.1.17/crude.php";

    Map<String, dynamic> body = {
      "type": _userType,
      "nom": nom.text,
      "email": email.text,
      "password": password.text,
    };

    if (_userType == "Commerçant") {
      if (boutiqueNom.text.isEmpty || adresse.text.isEmpty) {
        setState(() {
          _errorMessage = "Veuillez remplir tous les champs pour un commerçant.";
          _isLoading = false;
        });
        return;
      }
      body["boutique_nom"] = boutiqueNom.text;
      body["adresse"] = adresse.text;
    }

    try {
      var res = await http.post(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      var response = jsonDecode(res.body);

      if (res.statusCode == 200 && response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"])),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = response["error"] ?? "Une erreur s'est produite.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion : ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour ouvrir Google Maps avec l'adresse
  Future<void> _openMap(String address) async {
    if (address.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez entrer une adresse valide.";
      });
      return;
    }

    final Uri googleMapsUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _errorMessage = "Impossible d'ouvrir Google Maps.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Inscription',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUserTypeButton("Client", FontAwesomeIcons.user),
                        SizedBox(width: 10),
                        _buildUserTypeButton("Commerçant", FontAwesomeIcons.store),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    _buildTextField(nom, "Nom", Icons.person),
                    SizedBox(height: 16.0),
                    _buildTextField(email, "Email", Icons.email),
                    SizedBox(height: 16.0),
                    _buildTextField(password, "Mot de passe", Icons.lock, obscure: true),
                    SizedBox(height: 16.0),
                    _buildTextField(confirmPassword, "Confirmer le mot de passe", Icons.lock, obscure: true),
                    if (_userType == "Commerçant") ...[
                      SizedBox(height: 16.0),
                      _buildTextField(boutiqueNom, "Nom de la boutique", Icons.store),
                      SizedBox(height: 16.0),
                      _buildTextField(adresse, "Adresse", Icons.location_on, isAddress: true),
                    ],
                    SizedBox(height: 24.0),
                    if (_errorMessage.isNotEmpty)
                      Text(_errorMessage, style: TextStyle(color: Colors.blueAccent)),
                    SizedBox(height: 10),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                      icon: Icon(FontAwesomeIcons.solidCheckCircle),
                      onPressed: _signup,
                      label: Text('S\'inscrire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text('Déjà un compte ? Connectez-vous'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, bool isAddress = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: isAddress
            ? GestureDetector(
          onTap: () {
            if (controller.text.isNotEmpty) {
              _openMap(controller.text);
            } else {
              setState(() {
                _errorMessage = "Veuillez entrer une adresse valide.";
              });
            }
          },
          child: Icon(icon, color: Colors.blueAccent),
        )
            : Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildUserTypeButton(String type, IconData icon) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: _userType == type ? Colors.white : Colors.blueAccent),
        label: Text(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: _userType == type ? Colors.blueAccent : Colors.white,
          foregroundColor: _userType == type ? Colors.white : Colors.blueAccent,
          side: BorderSide(color: Colors.blueAccent),
        ),
        onPressed: () {
          setState(() {
            _userType = type;
          });
        },
      ),
    );
  }
}
