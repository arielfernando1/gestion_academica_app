import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/evento.dart';

class EventoCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;

  const EventoCard({
    super.key,
    required this.evento,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleComplete,
  });

  bool get _isCompleted => evento.estado == 'completado';

  DateTime? _parseFecha(String fecha) {
    try {
      return DateTime.parse(fecha);
    } catch (_) {
      return null;
    }
  }

  int? _diasRestantes() {
    final fechaEvento = _parseFecha(evento.fecha);
    if (fechaEvento == null) return null;
    final hoy = DateTime.now();
    final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
    final eventoSolo = DateTime(fechaEvento.year, fechaEvento.month, fechaEvento.day);
    return eventoSolo.difference(hoySolo).inDays;
  }

  String _formatearFecha() {
    final date = _parseFecha(evento.fecha);
    if (date == null) return evento.fecha;
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }

  String _textoAlerta() {
    if (_isCompleted) return 'Completado';
    final dias = _diasRestantes();
    if (dias == null) return 'Fecha inválida';
    if (dias < 0) return 'Vencido hace ${-dias}d';
    if (dias == 0) return 'Vence hoy';
    if (dias == 1) return 'Vence mañana';
    return 'Faltan $dias días';
  }

  Color _accentColor() {
    if (_isCompleted) return Colors.grey.shade400;
    final dias = _diasRestantes();
    if (dias == null) return Colors.grey.shade400;
    if (dias <= 0) return const Color(0xFFD32F2F);
    if (dias == 1) return const Color(0xFFF57C00);
    return kVerde;
  }

  Color _bgColor() {
    if (_isCompleted) return const Color(0xFFF5F5F5);
    final dias = _diasRestantes();
    if (dias == null) return const Color(0xFFF5F5F5);
    if (dias <= 0) return const Color(0xFFFFF0F0);
    if (dias == 1) return const Color(0xFFFFF8F0);
    return const Color(0xFFF0FFF5);
  }

  Color _chipBgColor() {
    if (_isCompleted) return Colors.grey.shade200;
    final dias = _diasRestantes();
    if (dias == null) return Colors.grey.shade200;
    if (dias <= 0) return const Color(0xFFFFEBEB);
    if (dias == 1) return const Color(0xFFFFF3E0);
    return kVerdeClaro;
  }

  IconData _iconoPorTipo() {
    switch (evento.tipo.toLowerCase()) {
      case 'examen':
        return Icons.assignment_outlined;
      case 'tarea':
        return Icons.task_alt;
      case 'clase':
        return Icons.school_outlined;
      case 'entrega':
        return Icons.upload_file_outlined;
      case 'reunión':
        return Icons.groups_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final bg = _bgColor();
    final chipBg = _chipBgColor();

    return Opacity(
      opacity: _isCompleted ? 0.75 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: _isCompleted ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent strip
                Container(width: 5, color: accent),

                // Card content
                Expanded(
                  child: Container(
                    color: bg,
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon avatar
                        Container(
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_iconoPorTipo(), color: accent, size: 22),
                        ),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _isCompleted
                                      ? Colors.grey.shade500
                                      : Colors.black87,
                                  decoration: _isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _SmallChip(
                                    label: evento.tipo,
                                    color: accent,
                                    bg: chipBg,
                                  ),
                                  _SmallChip(
                                    label: _textoAlerta(),
                                    color: accent,
                                    bg: chipBg,
                                    icon: _isCompleted
                                        ? Icons.check_circle_outline
                                        : Icons.schedule,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.menu_book_outlined,
                                text: evento.materia,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 3),
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                text: '${_formatearFecha()}  ·  ${evento.hora}',
                                color: Colors.grey.shade700,
                              ),
                              if (evento.descripcion.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                _InfoRow(
                                  icon: Icons.notes_outlined,
                                  text: evento.descripcion,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Actions column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _ActionButton(
                              icon: _isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _isCompleted ? kVerde : Colors.grey.shade400,
                              tooltip: _isCompleted ? 'Marcar pendiente' : 'Completado',
                              onTap: onToggleComplete,
                            ),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              onSelected: (v) {
                                if (v == 'edit') onEdit();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: kVerde, size: 20),
                                      const SizedBox(width: 10),
                                      const Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      const SizedBox(width: 10),
                                      const Text('Eliminar',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
