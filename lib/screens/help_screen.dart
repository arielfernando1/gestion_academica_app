import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Agenda Académica',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta aplicación permite registrar eventos académicos y consultarlos desde el celular, incluso sin conexión a internet.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.add_circle_outline,
            title: 'Registrar un evento',
            text:
                'Presione el botón “Nuevo”, complete título, materia, tipo, fecha, hora y descripción opcional. Luego pulse “Guardar”.',
          ),
          _buildSection(
            icon: Icons.check_circle_outline,
            title: 'Validación de datos',
            text:
                'La app no permite guardar eventos sin título, materia, fecha u hora. Esto evita registros incompletos.',
          ),
          _buildSection(
            icon: Icons.storage_outlined,
            title: 'Persistencia local',
            text:
                'Los eventos se guardan en una base de datos local SQLite. Al cerrar y abrir la app, la información permanece registrada.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined),
                      SizedBox(width: 10),
                      Text(
                        'Colores de prioridad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    color: Colors.green.shade100,
                    title: 'Verde',
                    description: 'faltan 2 días o más para el evento.',
                  ),
                  _buildLegendItem(
                    color: Colors.amber.shade100,
                    title: 'Amarillo',
                    description: 'falta 1 día para el evento.',
                  ),
                  _buildLegendItem(
                    color: Colors.red.shade100,
                    title: 'Rojo',
                    description: 'el evento es hoy o ya venció.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nota: las notificaciones automáticas del celular quedan planificadas para la siguiente iteración.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
