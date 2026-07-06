import 'package:flutter/material.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(255, 217, 255, 255), const Color.fromARGB(255, 7, 22, 120)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
              child: Container(
                width: double.infinity,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 188, 221, 255),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color.fromARGB(255, 146, 198, 255), width: 1.5),
                ),
                child: const Text(
                  'Credenciales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 27, 95, 170),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: Center(child: SizedBox.shrink())),
            Text(
              "Hola! Bienvenido a Credenciales.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
