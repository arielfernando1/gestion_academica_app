import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/evento.dart';
import '../services/database_service.dart';
import '../services/materia_service.dart';
import '../services/sync_service.dart';
import 'materias_screen.dart';

class EventoFormScreen extends StatefulWidget {
  final Evento? evento;

  const EventoFormScreen({super.key, this.evento});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipoSeleccionado = 'Tarea';
  String? _materiaSeleccionada;
  List<String> _materias = [];
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  final List<String> _tipos = ['Tarea', 'Examen', 'Clase', 'Entrega', 'Reunión'];

  bool get _isEditing => widget.evento != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.evento!;
      _tituloController.text = e.titulo;
      _descripcionController.text = e.descripcion;
      _tipoSeleccionado = e.tipo;
      _materiaSeleccionada = e.materia;
      _fechaSeleccionada = DateTime.tryParse(e.fecha);
      final parts = e.hora.split(':');
      if (parts.length == 2) {
        _horaSeleccionada = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _cargarMaterias();
  }

  Future<void> _cargarMaterias() async {
    final list = await MateriaService.instance.getMaterias();
    if (!mounted) return;
    final nombres = list.map((m) => m.nombre).toList();

    // Si se está editando y la materia no está en la lista, la agrega temporalmente
    if (_isEditing &&
        _materiaSeleccionada != null &&
        _materiaSeleccionada!.isNotEmpty &&
        !nombres.contains(_materiaSeleccionada)) {
      nombres.insert(0, _materiaSeleccionada!);
    }

    setState(() {
      _materias = nombres;
      // Si la materia seleccionada ya no está en la lista, resetea
      if (_materiaSeleccionada != null && !_materias.contains(_materiaSeleccionada)) {
        _materiaSeleccionada = null;
      }
    });
  }

  Future<void> _abrirGestionMaterias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MateriasScreen()),
    );
    await _cargarMaterias();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fechaActual = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? fechaActual,
      firstDate: DateTime(fechaActual.year - 1),
      lastDate: DateTime(fechaActual.year + 5),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
    );
    if (hora != null) setState(() => _horaSeleccionada = hora);
  }

  String _formatearFecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);
  String _mostrarFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_materiaSeleccionada == null) {
      _mostrarMensaje('Seleccione una materia');
      return;
    }
    if (_fechaSeleccionada == null) {
      _mostrarMensaje('Seleccione una fecha');
      return;
    }
    if (_horaSeleccionada == null) {
      _mostrarMensaje('Seleccione una hora');
      return;
    }

    if (_isEditing) {
      final updated = widget.evento!.copyWith(
        titulo: _tituloController.text.trim(),
        materia: _materiaSeleccionada!,
        tipo: _tipoSeleccionado,
        fecha: _formatearFecha(_fechaSeleccionada!),
        hora: _formatearHora(_horaSeleccionada!),
        descripcion: _descripcionController.text.trim(),
      );
      await DatabaseService.instance.updateEvento(updated);
    } else {
      final evento = Evento(
        titulo: _tituloController.text.trim(),
        materia: _materiaSeleccionada!,
        tipo: _tipoSeleccionado,
        fecha: _formatearFecha(_fechaSeleccionada!),
        hora: _formatearHora(_horaSeleccionada!),
        descripcion: _descripcionController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.instance.insertEvento(evento);
    }

    unawaited(SyncService.instance.sync());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Evento actualizado' : 'Evento guardado')),
    );
    Navigator.pop(context, true);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  InputDecoration _decoracionCampo(String label, IconData icon, {String? hintText}) {
    return InputDecoration(labelText: label, hintText: hintText, prefixIcon: Icon(icon));
  }

  Widget _buildDateTimeRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool hasValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? kVerde : Colors.grey.shade300,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: kVerde, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: hasValue ? Colors.black87 : Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: kVerde.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto = _fechaSeleccionada == null
        ? 'Seleccionar fecha'
        : _mostrarFecha(_fechaSeleccionada!);
    final horaTexto = _horaSeleccionada == null
        ? 'Seleccionar hora'
        : _formatearHora(_horaSeleccionada!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar evento' : 'Nuevo evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kAmarillo.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAmarillo),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 16, color: kVerdeOscuro),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editando: ${widget.evento!.titulo}',
                        style: const TextStyle(
                          color: kVerdeOscuro,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Título
                      TextFormField(
                        controller: _tituloController,
                        decoration: _decoracionCampo(
                          'Título del evento',
                          Icons.title,
                          hintText: 'Ej. Entrega práctica Semana 2',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese el título' : null,
                      ),
                      const SizedBox(height: 14),

                      // Materia — selector
                      _buildMateriaSelector(),
                      const SizedBox(height: 14),

                      // Tipo
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _tipoSeleccionado, // controlled dropdown
                        decoration: _decoracionCampo('Tipo de evento', Icons.category),
                        dropdownColor: Colors.white,
                        items: _tipos.map((tipo) {
                          return DropdownMenuItem(value: tipo, child: Text(tipo));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoSeleccionado = v);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Fecha
                      _buildDateTimeRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Fecha',
                        value: fechaTexto,
                        onTap: _seleccionarFecha,
                        hasValue: _fechaSeleccionada != null,
                      ),
                      const SizedBox(height: 10),

                      // Hora
                      _buildDateTimeRow(
                        icon: Icons.access_time_outlined,
                        label: 'Hora',
                        value: horaTexto,
                        onTap: _seleccionarHora,
                        hasValue: _horaSeleccionada != null,
                      ),
                      const SizedBox(height: 14),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: _decoracionCampo(
                          'Descripción opcional',
                          Icons.description,
                          hintText: 'Ej. Incluir capturas, pruebas funcionales y demo.',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _guardarEvento,
                              icon: Icon(_isEditing ? Icons.check : Icons.save, size: 18),
                              label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaSelector() {
    final sinMaterias = _materias.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _materiaSeleccionada,
            decoration: InputDecoration(
              labelText: 'Materia',
              prefixIcon: const Icon(Icons.menu_book_outlined),
              helperText: sinMaterias ? 'Usa el botón ✏ para agregar materias' : null,
              helperStyle: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
            hint: Text(sinMaterias ? 'Sin materias disponibles' : 'Seleccionar materia'),
            items: _materias.map((nombre) {
              return DropdownMenuItem(value: nombre, child: Text(nombre));
            }).toList(),
            onChanged: sinMaterias ? null : (v) => setState(() => _materiaSeleccionada = v),
            validator: (_) =>
                _materiaSeleccionada == null ? 'Seleccione una materia' : null,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Gestionar materias',
          child: InkWell(
            onTap: _abrirGestionMaterias,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sinMaterias ? Colors.orange.shade50 : kVerdeClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sinMaterias
                      ? Colors.orange.shade300
                      : kVerde.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.edit_note,
                color: sinMaterias ? Colors.orange.shade700 : kVerde,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
