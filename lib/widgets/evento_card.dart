import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evento.dart';

class EventoCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback onDelete;

  const EventoCard({
    super.key,
    required this.evento,
    required this.onDelete,
  });

  DateTime? _parseFecha(String fecha) {
    try {
      return DateTime.parse(fecha);
    } catch (_) {
      return null;
    }
  }

  int? _diasRestantes(String fecha) {
    final fechaEvento = _parseFecha(fecha);
    if (fechaEvento == null) return null;

    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final eventoSoloFecha = DateTime(
      fechaEvento.year,
      fechaEvento.month,
      fechaEvento.day,
    );

    return eventoSoloFecha.difference(hoySoloFecha).inDays;
  }

  String _formatearFecha(String fecha) {
    final date = _parseFecha(fecha);
    if (date == null) return fecha;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _textoAlerta() {
    final dias = _diasRestantes(evento.fecha);

    if (dias == null) return 'Fecha no válida';
    if (dias < 0) return 'Vencido';
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    if (dias == 2) return 'Faltan 2 días';
    return 'Faltan $dias días';
  }

  Color _colorAlerta() {
    final dias = _diasRestantes(evento.fecha);

    if (dias == null) return Colors.grey.shade200;
    if (dias <= 0) return Colors.red.shade100;
    if (dias == 1) return Colors.amber.shade100;
    return Colors.green.shade100;
  }

  Color _colorBordeAlerta() {
    final dias = _diasRestantes(evento.fecha);

    if (dias == null) return Colors.grey.shade400;
    if (dias <= 0) return Colors.red.shade700;
    if (dias == 1) return Colors.amber.shade800;
    return Colors.green.shade700;
  }

  Color _colorTextoAlerta() {
    final dias = _diasRestantes(evento.fecha);

    if (dias == null) return Colors.grey.shade800;
    if (dias <= 0) return Colors.red.shade900;
    if (dias == 1) return Colors.amber.shade900;
    return Colors.green.shade900;
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'examen':
        return Icons.assignment;
      case 'tarea':
        return Icons.task_alt;
      case 'clase':
        return Icons.school;
      case 'entrega':
        return Icons.upload_file;
      case 'reunión':
        return Icons.groups;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorAlerta = _colorAlerta();
    final colorBorde = _colorBordeAlerta();
    final colorTexto = _colorTextoAlerta();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorBorde,
          width: 1.4,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorAlerta,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: colorBorde,
            child: Icon(_iconoPorTipo(evento.tipo)),
          ),
          title: Text(
            evento.titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(
                      label: Text(
                        evento.tipo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white,
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: colorTexto,
                      ),
                      label: Text(
                        _textoAlerta(),
                        style: TextStyle(
                          color: colorTexto,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Materia: ${evento.materia}'),
                Text('Fecha: ${_formatearFecha(evento.fecha)} - ${evento.hora}'),
                if (evento.descripcion.trim().isNotEmpty)
                  Text('Descripción: ${evento.descripcion}'),
              ],
            ),
          ),
          trailing: IconButton(
            tooltip: 'Eliminar evento',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
