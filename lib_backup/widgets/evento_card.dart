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

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return fecha;
    }
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

  Color _colorPorTipo(BuildContext context, String tipo) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (tipo.toLowerCase()) {
      case 'examen':
        return colorScheme.errorContainer;
      case 'tarea':
        return colorScheme.primaryContainer;
      case 'clase':
        return colorScheme.secondaryContainer;
      case 'entrega':
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: _colorPorTipo(context, evento.tipo),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(_iconoPorTipo(evento.tipo)),
          ),
          title: Text(
            evento.titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Materia: ${evento.materia}'),
                Text('Tipo: ${evento.tipo}'),
                Text('Fecha: ${_formatearFecha(evento.fecha)} - ${evento.hora}'),
                if (evento.descripcion.trim().isNotEmpty)
                  Text('Descripción: ${evento.descripcion}'),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}