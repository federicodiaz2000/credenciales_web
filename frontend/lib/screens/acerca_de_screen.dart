import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/link.dart';

class AcercaDeScreen extends StatefulWidget {
  const AcercaDeScreen({super.key});

  @override
  State<AcercaDeScreen> createState() => _AcercaDeScreenState();
}

class _AcercaDeScreenState extends State<AcercaDeScreen> {
  int diasRestantes = 0;
  static const String _destinatario = 'federicodiaz@gmail.com';
  static const String _asunto = 'Consulta sobre Credenciales - Web';

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Uri get _mailUri => Uri(scheme: 'mailto', path: _destinatario, query: _encodeQueryParameters({'subject': _asunto}));

  Uri get _gmailComposeUri =>
      Uri.https('mail.google.com', '/mail/', {'view': 'cm', 'fs': '1', 'to': _destinatario, 'su': _asunto});

  Uri get _correoUriPreferida => kIsWeb ? _gmailComposeUri : _mailUri;

  Future<void> _enviarCorreo() async {
    final Uri emailLaunchUri = _correoUriPreferida;

    try {
      bool launched = await launchUrl(emailLaunchUri, webOnlyWindowName: kIsWeb ? '_self' : null);

      if (!launched && kIsWeb) {
        launched = await launchUrl(_gmailComposeUri, webOnlyWindowName: '_blank');
      }

      if (!launched) {
        throw Exception('No se pudo abrir el correo electrónico');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'No se pudo abrir tu cliente de correo en el navegador. Verifica que tengas uno configurado por defecto.'
                  : 'Error al abrir el correo: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color.fromARGB(255, 217, 255, 255), const Color.fromARGB(255, 7, 22, 120)],
        ),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        // Agregamos el scroll vertical
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SvgPicture.asset("assets/images/credencial.svg", height: 200),
              Text('Credenciales - Web', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Versión: 1.0.0 - © 2026', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                'Esta aplicación te ayuda a gestionar:\n - Credenciales,\n - Compartir por WhatsApp.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 24),
              Text('Desarrollado por Federico R. Díaz', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              Text('federicodiaz@gmail.com', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Text("Días restantes de prueba: $diasRestantes", style: TextStyle(fontSize: 16, color: Colors.blue)),
              const SizedBox(height: 32),
              Link(
                uri: _correoUriPreferida,
                target: kIsWeb ? LinkTarget.blank : LinkTarget.self,
                builder: (BuildContext context, Future<void> Function()? followLink) {
                  return ElevatedButton.icon(
                    onPressed: followLink ?? _enviarCorreo,
                    icon: const Icon(Icons.email),
                    label: Text('Enviar correo', style: TextStyle(fontSize: 14)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
